//
//  DeviceListScreen.swift
//  Scan + connect (mirrors DeviceListFragment). Lists BLE devices whose name
//  contains "OnAir". On successful connect, returns to the controller.
//

import SwiftUI

struct DeviceListScreen: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    @EnvironmentObject var nav: NavModel

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()      // starfield (from AppShell) shows through
            VStack(spacing: 0) {
                autoConnectToggle
                if !ble.bluetoothReady {
                    info("Bluetooth is off", "Turn on Bluetooth to find your OnAir controller.")
                } else if s.isConnected {
                    connected
                } else if ble.discovered.isEmpty {
                    info("Searching for OnAir…", "Make sure the vehicle is awake and the controller is powered.")
                } else {
                    deviceList
                }
                Spacer()
                if !s.isConnected {
                    Button(ble.isScanning ? "Stop" : "Scan") {
                        ble.isScanning ? ble.stopScan() : ble.startScan()
                    }
                    .font(.headline).foregroundColor(OnAirTheme.background)
                    .frame(width: 200, height: 46)
                    .background(OnAirTheme.menuLine, in: Capsule())
                    .padding(.bottom, 30)
                }
            }
            .padding(.top, 16)
        }
        .onAppear { if ble.bluetoothReady && !s.isConnected { ble.startScan() } }
        .onDisappear { ble.stopScan() }
        .onChange(of: s.isConnected) { _, connected in
            if connected { nav.back() }   // jump to controller once connected
        }
    }

    private var autoConnectToggle: some View {
        VStack(spacing: 10) {
            settingRow("Auto-connect",
                       "Reconnect to your controller automatically when it's in range.",
                       isOn: $ble.autoConnectEnabled)
            settingRow("Release when app is closed",
                       "Frees the controller so another phone can take over when you leave the app.",
                       isOn: $ble.releaseWhenInactive)
        }
        .padding(.horizontal, 20).padding(.bottom, 10)
    }

    private func settingRow(_ title: String, _ subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(OnAirTheme.gray)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(OnAirTheme.violet)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(OnAirTheme.violet.opacity(0.25), lineWidth: 1))
        )
    }

    private var deviceList: some View {
        VStack(spacing: 0) {
            ForEach(ble.discovered) { device in
                Button {
                    ble.connect(device)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name).font(.headline).foregroundColor(OnAirTheme.text)
                            Text("Signal \(device.rssi) dBm")
                                .font(.caption).foregroundColor(OnAirTheme.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(OnAirTheme.gray)
                    }
                    .padding(.horizontal, 22).frame(height: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider().background(OnAirTheme.line)
            }
        }
    }

    private var connected: some View {
        VStack(spacing: 16) {
            Image("toolbar_bluetooth").resizable().scaledToFit().frame(width: 40, height: 40)
            Text(s.connectedName.isEmpty ? "Connected" : s.connectedName)
                .font(.title3.bold()).foregroundColor(OnAirTheme.text)
            Button("Disconnect", role: .destructive) { ble.disconnect() }
                .padding(.top, 6)
            Button("Forget this device") { ble.forgetDevice() }
                .font(.caption).foregroundColor(OnAirTheme.gray)
        }
        .padding(.top, 40)
    }

    private func info(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 10) {
            ProgressView().tint(OnAirTheme.gray)
            Text(title).font(.headline).foregroundColor(OnAirTheme.text)
            Text(subtitle).font(.subheadline).foregroundColor(OnAirTheme.gray)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
        }
        .padding(.top, 50)
    }
}
