//
//  AppShell.swift
//  The toolbar + switchable content area (mirrors MainActivity + toolbar_main).
//  Shown once a model is chosen. The controller is the default screen; the
//  Bluetooth button opens the device list, the hamburger opens the menu.
//

import SwiftUI

struct AppShell: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    @StateObject private var nav = NavModel()

    var body: some View {
        ZStack {
            CarbonBackground()
            VStack(spacing: 0) {
                ToolbarBar()
                Divider().background(OnAirTheme.mono.opacity(0.25))
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(nav)
    }

    @ViewBuilder private var content: some View {
        switch nav.screen {
        case .controller:        ControllerView()
        case .menu:              MenuScreen()
        case .deviceList:        DeviceListScreen()
        case .allDown:           AllDownScreen()
        case .factoryReset:      FactoryResetScreen()
        case .serviceMode:       ServiceModeScreen()
        case .airTank:           AirTankScreen()
        case .smartSpeed:        SmartSpeedScreen()
        case .errorNotification: ErrorNotificationScreen()
        case .engineer:          EngineerScreen()
        default:                 ComingSoonScreen(title: nav.screen.title)
        }
    }
}

/// Top toolbar: hamburger/back • title • Bluetooth status.
private struct ToolbarBar: View {
    @EnvironmentObject var nav: NavModel
    @EnvironmentObject var s: SuspensionState
    @EnvironmentObject var ble: BLEManager

    var body: some View {
        HStack(spacing: 12) {
            if nav.screen == .controller {
                connectButton                       // top-left: Connect / Disconnect
                Spacer()
                if !modeLabel.isEmpty {             // top-right: current mode
                    Text(modeLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(OnAirTheme.monoSoft)
                        .padding(.horizontal, 11).padding(.vertical, 5)
                        .background(Capsule().fill(OnAirTheme.mono.opacity(0.18))
                            .overlay(Capsule().stroke(OnAirTheme.mono.opacity(0.4), lineWidth: 1)))
                        .transition(.opacity)
                }
                Button { nav.openMenu() } label: { Hamburger() }   // top-right: menu
            } else {
                Button { nav.back() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(OnAirTheme.text)
                        .frame(width: 28, height: 28)
                }
                Text(nav.screen.title)
                    .font(.system(size: 17))
                    .foregroundColor(OnAirTheme.text)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    private var modeLabel: String {
        if s.isAuto { return "Auto" }
        switch s.height {
        case .low:     return "Low"
        case .onair:   return "On Air"
        case .high:    return "High"
        case .allDown: return "All Down"
        default:       return ""
        }
    }

    private var connectButton: some View {
        Button {
            if s.isConnected {
                ble.disconnect()                    // release control
            } else if ble.hasSavedDevice {
                ble.userConnect()                   // re-link to the known controller
            } else {
                nav.go(.deviceList)                 // first time: pick a device
            }
        } label: {
            HStack(spacing: 7) {
                Circle().fill(s.isConnected ? Color.green : OnAirTheme.gray)
                    .frame(width: 8, height: 8)
                Text(s.isConnected ? "Disconnect" : "Connect")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14).frame(height: 34)
            .background(Capsule().fill(s.isConnected ? OnAirTheme.mono.opacity(0.30)
                                                     : Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(OnAirTheme.mono.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// The three-line hamburger drawn to match toolbar_main (menu_line coloured bars).
private struct Hamburger: View {
    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(OnAirTheme.menuLine)
                    .frame(width: 26, height: 2)
            }
        }
        .frame(width: 28, height: 28)
    }
}

/// Placeholder for screens not yet ported (Language, Guide, My Account, Debug).
struct ComingSoonScreen: View {
    let title: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer.fill").font(.system(size: 40)).foregroundColor(OnAirTheme.gray)
            Text(title).font(.title3.bold()).foregroundColor(OnAirTheme.text)
            Text("This screen is being ported next.")
                .font(.subheadline).foregroundColor(OnAirTheme.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
