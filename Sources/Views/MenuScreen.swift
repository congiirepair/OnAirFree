//
//  MenuScreen.swift
//  Futuristic menu — frosted-glass rows with glowing violet icons, floating
//  over the animated starfield (from AppShell). Triple-tap the title reveals
//  Engineer/Debug, like the original. Connection-required items prompt first.
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
            VStack(spacing: 14) {
                header
                ForEach(entries) { row($0) }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .alert("Connect to your OnAir device first.", isPresented: $showConnectAlert) {
            Button("Connect") { nav.go(.deviceList) }
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack {
            Text("MENU")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: OnAirTheme.violet.opacity(0.8), radius: 10)
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {                          // triple-tap reveals Engineer/Debug
            tapCount += 1
            if tapCount >= 3 { withAnimation { revealHidden.toggle() }; tapCount = 0 }
        }
    }

    private func row(_ entry: MenuEntry) -> some View {
        let warn = entry.screen == .errorNotification && s.anyWarning
        return Button {
            if entry.requiresConnection && !s.isConnected { showConnectAlert = true }
            else { nav.go(entry.screen) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(OnAirTheme.violet.opacity(0.18)).frame(width: 42, height: 42)
                    Circle().stroke(OnAirTheme.violet.opacity(0.5), lineWidth: 1).frame(width: 42, height: 42)
                    Image(systemName: entry.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(OnAirTheme.violetLight)
                }
                Text(entry.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                if warn {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OnAirTheme.violet.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(OnAirTheme.violet.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: OnAirTheme.violet.opacity(0.18), radius: 10, y: 3)
        }
        .buttonStyle(.plain)
    }
}
