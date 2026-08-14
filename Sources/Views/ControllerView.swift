//
//  ControllerView.swift
//  Main air-suspension controller. Wired to the real command set.
//
//  Behavior mirrors the Android ControllerFragment:
//   • Low / OnAir / High    → momentary tap
//   • Manual wheel up/down   → press-and-hold (move while held, stop on release)
//   • All Down               → press-and-hold ~3s to activate (safety)
//   • Auto                   → toggle
//   • Memory 1/2/3           → save current height into a slot
//

import SwiftUI

struct ControllerView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusCard
                    if s.anyWarning { warningCard }
                    heightPresets
                    manualWheels
                    modesRow
                    memoryRow
                }
                .padding()
            }
            .navigationTitle(s.connectedName.isEmpty ? "OnAir" : s.connectedName)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Disconnect", role: .destructive) { ble.disconnect() }
                }
            }
        }
    }

    // MARK: Status

    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label(s.isConnected ? "Connected" : "Disconnected",
                      systemImage: "dot.radiowaves.left.and.right")
                    .foregroundStyle(s.isConnected ? .green : .secondary)
                Spacer()
                Button {
                    ble.send(OnAirCommand.getAirBottlePressure)
                } label: { Image(systemName: "arrow.clockwise") }
            }
            HStack(spacing: 24) {
                stat("Height", s.height == .none ? "—" : s.height.rawValue.capitalized)
                stat("Tank", "\(s.airPressure)")
                stat("Speed", "\(s.currentSpeed)")
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var warningCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("System warning", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange).font(.headline)
            let items = [
                ("Front height sensor", s.warnFrontHeightSensor),
                ("Rear height sensor",  s.warnBackHeightSensor),
                ("Air tank",            s.warnAirTank),
                ("Air pump",            s.warnAirPump),
                ("Device",              s.warnDevice),
                ("MCU",                 s.warnMcu),
            ].filter { $0.1 }
            ForEach(items, id: \.0) { Text("• \($0.0)").font(.caption) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Height presets

    private var heightPresets: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Ride height")
            HStack(spacing: 12) {
                presetButton("Low",   .low,   OnAirCommand.low)
                presetButton("OnAir", .onair, OnAirCommand.onair)
                presetButton("High",  .high,  OnAirCommand.high)
            }
        }
    }

    private func presetButton(_ title: String, _ h: SuspensionState.Height, _ cmd: String) -> some View {
        Button {
            ble.send(cmd)
        } label: {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(s.height == h ? .accentColor : .gray)
        .disabled(s.isRepairMode)
    }

    // MARK: Manual wheels (press & hold)

    private var manualWheels: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Manual control (hold)")
            wheelRow("Front", up: OnAirCommand.frontWheelUp, down: OnAirCommand.frontWheelDown)
            wheelRow("Rear",  up: OnAirCommand.backWheelUp,  down: OnAirCommand.backWheelDown)
            wheelRow("All",   up: OnAirCommand.frontBackWheelUp, down: OnAirCommand.frontBackWheelDown)
        }
    }

    private func wheelRow(_ label: String, up: String, down: String) -> some View {
        HStack(spacing: 12) {
            Text(label).frame(width: 54, alignment: .leading)
            HoldButton(title: "Up", systemImage: "arrow.up",
                       onPress: { ble.send(up) },
                       onRelease: { ble.send(OnAirCommand.wheelUpStop) })
            HoldButton(title: "Down", systemImage: "arrow.down",
                       onPress: { ble.send(down) },
                       onRelease: { ble.send(OnAirCommand.wheelDownStop) })
        }
        .disabled(s.isRepairMode)
    }

    // MARK: Modes

    private var modesRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Modes")
            HStack(spacing: 12) {
                Toggle("Auto", isOn: Binding(
                    get: { s.isAuto },
                    set: { ble.send($0 ? OnAirCommand.openAuto : OnAirCommand.closeAuto) }
                ))
                .toggleStyle(.button).buttonStyle(.bordered)

                // All-down: hold to activate (safety); sends the dump frame.
                HoldButton(title: "All Down (hold)", systemImage: "arrow.down.to.line",
                           tint: .red, minimumHold: 3.0,
                           onPress: { },
                           onRelease: { },
                           onHoldComplete: { ble.send(OnAirCommand.allDown) })
                    .disabled(!s.allDownEnable)
            }
        }
    }

    // MARK: Memory

    private var memoryRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Save memory height")
            HStack(spacing: 12) {
                memButton("M1", OnAirCommand.setMemory1)
                memButton("M2", OnAirCommand.setMemory2)
                memButton("M3", OnAirCommand.setMemory3)
            }
        }
    }

    private func memButton(_ title: String, _ cmd: String) -> some View {
        Button { ble.send(cmd) } label: {
            Text(title).frame(maxWidth: .infinity).padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.headline).frame(maxWidth: .infinity, alignment: .leading)
    }
}
