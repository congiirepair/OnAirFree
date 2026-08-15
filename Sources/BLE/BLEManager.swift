//
//  BLEManager.swift
//  OnAirFree
//
//  CoreBluetooth replacement for the Android cn.com.heaton.blelibrary layer.
//  Scans for devices whose name contains "OnAir", connects, discovers the
//  UART service, subscribes to notifications, and writes command frames.
//
//  The controller may expose either the standard HM-10 service (FFE0/FFE1)
//  or a custom service (00010203-…-1910 / …-2b11). We discover both and use
//  whichever the connected device actually has — the same fallback the
//  Android app performs in MainActivity.eventToSendCommand.
//

import Foundation
import CoreBluetooth

// UUIDs, ported from UtilsBle.
private enum UART {
    static let serviceStd   = CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
    static let charStd      = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
    static let serviceCustom = CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1910")
    static let charCustomWrite = CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d2b11")
    // Some firmwares notify on the custom "read" characteristic (same UUID as service).
    static let charCustomRead  = CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1910")
}

/// "FFE1" from a full 128-bit UUID; else the first 8 chars — for the debug log.
private func shortUUID(_ uuid: String) -> String {
    if uuid.uppercased().hasSuffix("-0000-1000-8000-00805F9B34FB") {
        return String(uuid.prefix(8).suffix(4)).uppercased()
    }
    return String(uuid.prefix(8)).uppercased()
}

/// A discovered device shown in the scan list.
struct ScannedDevice: Identifiable, Equatable {
    let id: UUID           // peripheral.identifier
    let name: String
    let rssi: Int
    static func == (a: ScannedDevice, b: ScannedDevice) -> Bool { a.id == b.id }
}

@MainActor
final class BLEManager: NSObject, ObservableObject {

    @Published var isScanning = false
    @Published var discovered: [ScannedDevice] = []
    @Published var bluetoothReady = false
    @Published var lastError: String?

    /// Shared, observable device state (updated by FrameParser).
    let state = SuspensionState()

    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var connected: CBPeripheral?
    private var writeChar: CBCharacteristic?
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    private var pollTask: Task<Void, Never>?

    // Auto-connect: remember the last device and re-link when it's in range.
    private let lastDeviceKey = "lastDeviceID"
    /// True after a manual disconnect — this phone won't auto-grab the controller
    /// again until the user taps Connect or relaunches. Keeps a hand-off from being
    /// snatched back by the person who just released control. Not persisted.
    private var autoConnectSuppressed = false
    @Published var autoConnectEnabled: Bool =
        (UserDefaults.standard.object(forKey: "autoConnectEnabled") as? Bool) ?? true {
        didSet { UserDefaults.standard.set(autoConnectEnabled, forKey: "autoConnectEnabled") }
    }

    var hasSavedDevice: Bool { UserDefaults.standard.string(forKey: lastDeviceKey) != nil }

    // Debug frame log (shown on the Debug screen).
    @Published var debugLines: [String] = []
    @Published var writeCharInfo: String = "—"
    func dbg(_ s: String) {
        debugLines.append(s)
        if debugLines.count > 250 { debugLines.removeFirst(debugLines.count - 250) }
    }
    func clearDebug() { debugLines.removeAll() }

    // Buffer for reassembling multi-packet frames terminated by 0D 0A.
    private var rxBuffer = Data()

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: Scan

    func startScan() {
        guard bluetoothReady else { return }
        discovered.removeAll()
        isScanning = true
        // Passing nil scans for everything; we filter by name in the callback,
        // because the controller advertises the UART service inconsistently.
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        isScanning = false
        central.stopScan()
    }

    // MARK: Connect

    func connect(_ device: ScannedDevice) {
        guard let p = peripherals[device.id] else { return }
        autoConnectSuppressed = false        // explicit connect intent
        stopScan()
        connected = p
        p.delegate = self
        central.connect(p, options: nil)
    }

    /// User taps Disconnect — releases control and stops THIS phone from auto-grabbing
    /// the controller again until they tap Connect (so the other phone can take over).
    func disconnect() {
        autoConnectSuppressed = true
        if let p = connected { central.cancelPeripheralConnection(p) }
    }

    /// User taps Connect — clears the suppression and re-links to the saved device.
    func userConnect() {
        autoConnectSuppressed = false
        tryAutoConnect()
    }

    /// Forget the saved device so this phone stops auto-connecting to it.
    func forgetDevice() {
        UserDefaults.standard.removeObject(forKey: lastDeviceKey)
        disconnect()
    }

    /// Re-link to the last device. `connect()` has no timeout, so the link completes
    /// whenever the controller is in range and free.
    private func tryAutoConnect() {
        guard autoConnectEnabled, !autoConnectSuppressed, !state.isConnected, connected == nil,
              let idStr = UserDefaults.standard.string(forKey: lastDeviceKey),
              let uuid = UUID(uuidString: idStr) else { return }
        if let p = central.retrievePeripherals(withIdentifiers: [uuid]).first {
            connected = p
            p.delegate = self
            central.connect(p, options: nil)
        }
        startScan()   // fallback discovery in case the system no longer knows it
    }

    /// App backgrounded — KEEP the controller connection (control stays held); just
    /// pause polling to save battery.
    func appDidEnterBackground() {
        stopPolling()
    }

    /// App foregrounded — resume polling if still connected, else try to reconnect.
    func appDidBecomeActive() {
        if state.isConnected { startPolling() } else { tryAutoConnect() }
    }

    // MARK: Send

    /// Write a command hex string (from OnAirCommand) to the controller.
    func send(_ commandHex: String) {
        guard let p = connected, let c = writeChar else {
            dbg("TX FAIL (no connection): \(commandHex)")
            lastError = "Not connected"
            return
        }
        p.writeValue(commandHex.onairHexData, for: c, type: writeType)
        dbg("TX \(commandHex)")
    }

    // MARK: Status polling (mirrors the Android AutogetAir loop)

    /// While connected, continuously re-query full device status + air pressure
    /// so height, auto, service mode, smart-speed, faults and pressure stay live.
    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { @MainActor in
            while !Task.isCancelled {
                if self.connected != nil, self.writeChar != nil {
                    self.send(OnAirCommand.getDeviceInfo)         // FC: height/auto/repair/smart-speed/level
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    self.send(OnAirCommand.getAirBottlePressure)  // F4: tank pressure + speed
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let poweredOn = central.state == .poweredOn
        Task { @MainActor in
            self.bluetoothReady = poweredOn
            if poweredOn {
                self.tryAutoConnect()          // re-link to the last device on launch
            } else {
                self.stopPolling()
                self.state.isConnected = false
                self.state.reset()
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        let advName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name ?? ""
        // Android filter: name contains "OnAir".
        guard advName.localizedCaseInsensitiveContains("OnAir") else { return }
        let rssi = RSSI.intValue
        Task { @MainActor in
            self.peripherals[peripheral.identifier] = peripheral
            let dev = ScannedDevice(id: peripheral.identifier, name: advName, rssi: rssi)
            if let idx = self.discovered.firstIndex(of: dev) {
                self.discovered[idx] = dev
            } else {
                self.discovered.append(dev)
            }
            // Auto-connect to the last-used device when it reappears (and is free).
            if self.autoConnectEnabled, !self.autoConnectSuppressed,
               self.connected == nil, !self.state.isConnected,
               UserDefaults.standard.string(forKey: self.lastDeviceKey) == peripheral.identifier.uuidString {
                self.connect(dev)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didConnect peripheral: CBPeripheral) {
        Task { @MainActor in self.dbg("CONNECTED \(peripheral.name ?? "?") — discovering services…") }
        peripheral.discoverServices(nil)          // discover ALL services (was limited to FFE0/custom)
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didFailToConnect peripheral: CBPeripheral,
                                    error: Error?) {
        let message = error?.localizedDescription ?? "Failed to connect"
        Task { @MainActor in
            self.connected = nil          // clear the stale peripheral after a failed attempt
            self.lastError = message
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDisconnectPeripheral peripheral: CBPeripheral,
                                    error: Error?) {
        Task { @MainActor in
            self.stopPolling()
            self.writeChar = nil
            self.state.isConnected = false
            self.state.reset()
            if self.autoConnectEnabled, !self.autoConnectSuppressed {
                // Unexpected drop (out of range): keep a pending connect so it re-links
                // automatically when the controller is back in range and free.
                self.central.connect(peripheral, options: nil)
            } else {
                self.connected = nil    // manual disconnect — stay released for hand-off
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverCharacteristicsFor service: CBService,
                                error: Error?) {
        // Choose the write characteristic locally first (prefer standard FFE1),
        // then apply everything in a single MainActor hop to avoid ordering races.
        var chosenWrite: CBCharacteristic?
        var chosenType: CBCharacteristicWriteType = .withoutResponse
        var log: [String] = []
        let svc = shortUUID(service.uuid.uuidString)
        for c in service.characteristics ?? [] {
            var props: [String] = []
            if c.properties.contains(.read) { props.append("R") }
            if c.properties.contains(.write) { props.append("W") }
            if c.properties.contains(.writeWithoutResponse) { props.append("Wnr") }
            if c.properties.contains(.notify) { props.append("N") }
            if c.properties.contains(.indicate) { props.append("I") }
            log.append("svc \(svc) · char \(shortUUID(c.uuid.uuidString)) [\(props.joined(separator: ","))]")
            if c.properties.contains(.notify) || c.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: c)
            }
            let isWritable = c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse)
            if isWritable, chosenWrite == nil || c.uuid == UART.charStd {
                chosenWrite = c
                chosenType = c.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
            }
        }
        let writeToSet = chosenWrite
        let typeToSet = chosenType
        let name = peripheral.name ?? "OnAir"
        let deviceID = peripheral.identifier.uuidString
        let logCopy = log
        Task { @MainActor in
            for l in logCopy { self.dbg(l) }
            if let writeToSet, self.writeChar == nil || writeToSet.uuid == UART.charStd {
                self.writeChar = writeToSet
                self.writeType = typeToSet
                self.writeCharInfo = "\(shortUUID(writeToSet.uuid.uuidString)) (\(typeToSet == .withoutResponse ? "no-response" : "with-response"))"
                self.dbg("→ WRITE CHAR = \(self.writeCharInfo)")
            }
            // Guard on !isConnected so a device exposing both services only inits once.
            if self.writeChar != nil, self.connected != nil, !self.state.isConnected {
                self.state.isConnected = true
                self.state.connectedName = name
                UserDefaults.standard.set(deviceID, forKey: self.lastDeviceKey)  // remember for auto-connect
                self.startPolling()                     // continuous status refresh
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didUpdateValueFor characteristic: CBCharacteristic,
                                error: Error?) {
        guard let value = characteristic.value else { return }
        Task { @MainActor in
            self.dbg("RX \(value.onairHexString)")
            self.handleIncoming(value)
        }
    }

    /// Reassemble frames terminated by 0D 0A, then parse each complete frame.
    @MainActor
    private func handleIncoming(_ chunk: Data) {
        rxBuffer.append(chunk)
        let bytes = [UInt8](rxBuffer)
        var frameStart = 0
        var i = 0
        // Scan for each CR-LF terminator and emit the frame up to and including it.
        while i + 1 < bytes.count {
            if bytes[i] == 0x0D && bytes[i + 1] == 0x0A {
                let frame = Data(bytes[frameStart...(i + 1)])
                FrameParser.apply(frame, to: state)
                i += 2
                frameStart = i
            } else {
                i += 1
            }
        }
        // Keep any partial (unterminated) tail for the next chunk.
        rxBuffer = frameStart < bytes.count ? Data(bytes[frameStart...]) : Data()
        // Safety: prevent unbounded growth on a malformed stream.
        if rxBuffer.count > 512 { rxBuffer.removeAll() }
    }
}
