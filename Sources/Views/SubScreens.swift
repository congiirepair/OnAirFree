//
//  SubScreens.swift
//  Functional menu sub-screens, wired to the real command set. Dark-themed to
//  match the original; layouts refined per-screen against their XML.
//

import SwiftUI

// Small shared building blocks -------------------------------------------------

private func screenBG<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    ZStack {
        OnAirTheme.background.ignoresSafeArea()
        VStack(spacing: 22) { content() }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 28).padding(.horizontal, 24)
    }
}

private struct PillButton: View {
    let title: String
    var tint: Color = OnAirTheme.menuLine
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).foregroundColor(OnAirTheme.background)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(tint, in: Capsule())
        }
    }
}

// All Down ---------------------------------------------------------------------

struct AllDownScreen: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    var body: some View {
        screenBG {
            Text("All Down lets you dump all struts to their lowest point. Enable it here, then hold the All Down button on the controller for 5 seconds.")
                .font(.subheadline).foregroundColor(OnAirTheme.gray)
            HStack {
                Text("All Down enabled").foregroundColor(OnAirTheme.text)
                Spacer()
                Text(s.allDownEnable ? "ON" : "OFF")
                    .foregroundColor(s.allDownEnable ? OnAirTheme.accent : OnAirTheme.gray)
            }
            PillButton(title: s.allDownEnable ? "Disable All Down" : "Enable All Down") {
                ble.send(s.allDownEnable ? OnAirCommand.allDownDisable : OnAirCommand.allDownEnable)
            }
        }
    }
}

// Factory Reset ----------------------------------------------------------------

struct FactoryResetScreen: View {
    @EnvironmentObject var ble: BLEManager
    @State private var confirm = false
    var body: some View {
        screenBG {
            Text("This restores the controller's default settings and exits any active modes.")
                .font(.subheadline).foregroundColor(OnAirTheme.gray)
            PillButton(title: "Factory Reset", tint: OnAirTheme.accent) { confirm = true }
        }
        .alert("Factory reset the controller?", isPresented: $confirm) {
            Button("Reset", role: .destructive) { ble.send(OnAirCommand.restoreExitSettings) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// Service (Repair) Mode --------------------------------------------------------

struct ServiceModeScreen: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    var body: some View {
        screenBG {
            Text("Service Mode locks the suspension so the vehicle can be safely lifted or serviced.")
                .font(.subheadline).foregroundColor(OnAirTheme.gray)
            HStack {
                Text("Service Mode").foregroundColor(OnAirTheme.text)
                Spacer()
                Text(s.isRepairMode ? "ON" : "OFF")
                    .foregroundColor(s.isRepairMode ? OnAirTheme.accent : OnAirTheme.gray)
            }
            PillButton(title: s.isRepairMode ? "Exit Service Mode" : "Enter Service Mode",
                       tint: s.isRepairMode ? OnAirTheme.gray : OnAirTheme.accent) {
                ble.send(s.isRepairMode ? OnAirCommand.closeRepairMode : OnAirCommand.openRepairMode)
            }
        }
    }
}

// Air Tank Pressure ------------------------------------------------------------

struct AirTankScreen: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState

    private let presets: [(String, String)] = [
        ("1", OnAirCommand.setValue1), ("2", OnAirCommand.setValue2),
        ("3", OnAirCommand.setValue3), ("4", OnAirCommand.setValue4),
        ("5", OnAirCommand.setValue5),
    ]

    var body: some View {
        screenBG {
            Image("air_tank_pressure").resizable().scaledToFit().frame(height: 90)
            HStack(spacing: 6) {
                Text(s.airPressure).font(.system(size: 48, weight: .bold))
                    .foregroundColor(OnAirTheme.text)
                Text("PSI").font(.headline).foregroundColor(OnAirTheme.gray)
            }
            PillButton(title: "Refresh") { ble.send(OnAirCommand.getAirBottlePressure) }

            Text("Set target level").font(.subheadline).foregroundColor(OnAirTheme.gray)
            HStack(spacing: 10) {
                ForEach(presets, id: \.0) { p in
                    Button(p.0) { ble.send(p.1) }
                        .font(.headline).foregroundColor(OnAirTheme.text)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(OnAirTheme.buttonLine, lineWidth: 2))
                }
            }
        }
        .onAppear { ble.send(OnAirCommand.getAirBottlePressure) }
    }
}

// Smart Speed ------------------------------------------------------------------

struct SmartSpeedScreen: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    var body: some View {
        screenBG {
            Text("Smart Speed automatically lowers the vehicle as speed increases for better stability.")
                .font(.subheadline).foregroundColor(OnAirTheme.gray)
            HStack {
                Text("Smart Speed").foregroundColor(OnAirTheme.text)
                Spacer()
                Text(s.smartSpeedMode ? "ON" : "OFF")
                    .foregroundColor(s.smartSpeedMode ? OnAirTheme.accent : OnAirTheme.gray)
            }
            PillButton(title: s.smartSpeedMode ? "Turn Off" : "Turn On",
                       tint: s.smartSpeedMode ? OnAirTheme.gray : OnAirTheme.accent) {
                ble.send(s.smartSpeedMode ? OnAirCommand.smartSpendOff : OnAirCommand.smartSpendOn)
            }
        }
    }
}

// Error Notification -----------------------------------------------------------

struct ErrorNotificationScreen: View {
    @EnvironmentObject var s: SuspensionState

    private var rows: [(String, Bool)] {
        [("Front height sensor", s.warnFrontHeightSensor),
         ("Rear height sensor",  s.warnBackHeightSensor),
         ("Air tank",            s.warnAirTank),
         ("Air pump",            s.warnAirPump),
         ("Device",              s.warnDevice),
         ("MCU",                 s.warnMcu)]
    }

    var body: some View {
        screenBG {
            if !s.anyWarning {
                Text("No faults reported.").foregroundColor(OnAirTheme.gray).padding(.top, 20)
            }
            ForEach(rows, id: \.0) { row in
                HStack {
                    Circle().fill(row.1 ? Color.orange : OnAirTheme.gray.opacity(0.4))
                        .frame(width: 10, height: 10)
                    Text(row.0).foregroundColor(OnAirTheme.text)
                    Spacer()
                    Text(row.1 ? "FAULT" : "OK")
                        .font(.caption.bold())
                        .foregroundColor(row.1 ? .orange : OnAirTheme.gray)
                }
                .frame(height: 44)
                Divider().background(OnAirTheme.line)
            }
        }
    }
}

// Engineer Mode — manual per-wheel control -------------------------------------

struct EngineerScreen: View {
    @EnvironmentObject var ble: BLEManager
    var body: some View {
        screenBG {
            Text("Manual control — hold to move each corner, release to stop.")
                .font(.subheadline).foregroundColor(OnAirTheme.gray)
            wheelRow("Front", OnAirCommand.frontWheelUp, OnAirCommand.frontWheelDown)
            wheelRow("Rear",  OnAirCommand.backWheelUp,  OnAirCommand.backWheelDown)
            wheelRow("All",   OnAirCommand.frontBackWheelUp, OnAirCommand.frontBackWheelDown)

            Text("Save memory height").font(.subheadline).foregroundColor(OnAirTheme.gray).padding(.top, 8)
            HStack(spacing: 12) {
                ForEach([("M1", OnAirCommand.setMemory1),
                         ("M2", OnAirCommand.setMemory2),
                         ("M3", OnAirCommand.setMemory3)], id: \.0) { m in
                    Button(m.0) { ble.send(m.1) }
                        .font(.headline).foregroundColor(OnAirTheme.text)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(OnAirTheme.buttonLine, lineWidth: 2))
                }
            }
        }
    }

    private func wheelRow(_ label: String, _ up: String, _ down: String) -> some View {
        HStack(spacing: 12) {
            Text(label).frame(width: 54, alignment: .leading).foregroundColor(OnAirTheme.text)
            HoldButton(title: "Up", systemImage: "arrow.up",
                       onPress: { ble.send(up) },
                       onRelease: { ble.send(OnAirCommand.wheelUpStop) })
            HoldButton(title: "Down", systemImage: "arrow.down",
                       onPress: { ble.send(down) },
                       onRelease: { ble.send(OnAirCommand.wheelDownStop) })
        }
    }
}
