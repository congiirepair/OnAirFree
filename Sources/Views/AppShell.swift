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
            OnAirTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ToolbarBar()
                Divider().background(OnAirTheme.line)
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

    var body: some View {
        HStack(spacing: 12) {
            Button {
                nav.screen == .controller ? nav.openMenu() : nav.back()
            } label: {
                if nav.screen == .controller {
                    Hamburger()
                } else {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(OnAirTheme.text)
                        .frame(width: 28, height: 28)
                }
            }

            Text(nav.screen.title)
                .font(.system(size: 17))
                .foregroundColor(OnAirTheme.text)

            Spacer()

            Button {
                nav.go(.deviceList)
            } label: {
                Image(s.isConnected ? "toolbar_bluetooth" : "toolbar_bluetooth_noconect")
                    .resizable().scaledToFit().frame(width: 26, height: 26)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(OnAirTheme.background)
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
        .background(OnAirTheme.background)
    }
}
