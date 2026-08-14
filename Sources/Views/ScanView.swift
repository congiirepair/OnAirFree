//
//  ScanView.swift
//  Device discovery + connect. Lists BLE devices whose name contains "OnAir".
//

import SwiftUI

struct ScanView: View {
    @EnvironmentObject var ble: BLEManager

    var body: some View {
        NavigationStack {
            VStack {
                if !ble.bluetoothReady {
                    ContentUnavailableView("Bluetooth is off",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        description: Text("Turn on Bluetooth to find your OnAir controller."))
                } else if ble.discovered.isEmpty {
                    ContentUnavailableView {
                        Label("Searching for OnAir…", systemImage: "dot.radiowaves.left.and.right")
                    } description: {
                        Text("Make sure the vehicle is awake and the controller is powered.")
                    }
                } else {
                    List(ble.discovered) { device in
                        Button {
                            ble.connect(device)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name).font(.headline)
                                    Text("Signal \(device.rssi) dBm")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Connect")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(ble.isScanning ? "Stop" : "Scan") {
                        ble.isScanning ? ble.stopScan() : ble.startScan()
                    }
                }
            }
            .onAppear { if ble.bluetoothReady { ble.startScan() } }
            .onDisappear { ble.stopScan() }
        }
    }
}
