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
        stopScan()
        connected = p
        p.delegate = self
        central.connect(p, options: nil)
    }

    func disconnect() {
        if let p = connected { central.cancelPeripheralConnection(p) }
    }

    // MARK: Send

    /// Write a command hex string (from OnAirCommand) to the controller.
    func send(_ commandHex: String) {
        guard let p = connected, let c = writeChar else {
            lastError = "Not connected"
            return
        }
        p.writeValue(commandHex.onairHexData, for: c, type: writeType)
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
            if !poweredOn {
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
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([UART.serviceStd, UART.serviceCustom])
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
            self.connected = nil
            self.state.isConnected = false
            self.state.reset()
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
        for c in service.characteristics ?? [] {
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
        Task { @MainActor in
            if let writeToSet, self.writeChar == nil || writeToSet.uuid == UART.charStd {
                self.writeChar = writeToSet
                self.writeType = typeToSet
            }
            // Guard on !isConnected so a device exposing both services only inits once.
            if self.writeChar != nil, self.connected != nil, !self.state.isConnected {
                self.state.isConnected = true
                self.state.connectedName = name
                self.startPolling()                     // continuous status refresh
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didUpdateValueFor characteristic: CBCharacteristic,
                                error: Error?) {
        guard let value = characteristic.value else { return }
        Task { @MainActor in
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
