//
//  MenuScreen.swift
//  The main menu list (mirrors fragment_menu / MenuFragment). Items that need a
//  live connection show a prompt when disconnected. Engineer/Debug are hidden
//  until a triple-tap on the header, like the original.
//

import SwiftUI

struct MenuScreen: View {
    @EnvironmentObject var s: SuspensionState
    @EnvironmentObject var nav: NavModel

    @State private var revealHidden = false
    @State private var tapCount = 0
    @State private var showConnectAlert = false

    private var entries: [MenuEntry] {
        MenuEntry.all.filter { !$0.hidden || revealHidden }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Triple-tap header reveals Engineer/Debug (matches the original).
                Color.clear
                    .frame(height: 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tapCount += 1
                        if tapCount >= 3 { revealHidden.toggle(); tapCount = 0 }
                    }

                ForEach(entries) { entry in
                    Button {
                        if entry.requiresConnection && !s.isConnected {
                            showConnectAlert = true
                        } else {
                            nav.go(entry.screen)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(entry.title)
                                .font(.system(size: 16))
                                .foregroundColor(OnAirTheme.text)
                            if entry.screen == .errorNotification && s.anyWarning {
                                Image("menu_system_display_warning")
                                    .resizable().frame(width: 18, height: 18)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(OnAirTheme.gray)
                        }
                        .padding(.horizontal, 22)
                        .frame(height: 54)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().background(OnAirTheme.line)
                }
            }
        }
        .background(OnAirTheme.background)
        .alert("Connect to your OnAir device first.",
               isPresented: $showConnectAlert) {
            Button("Connect") { nav.go(.deviceList) }
            Button("OK", role: .cancel) {}
        }
    }
}
