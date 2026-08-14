//
//  ControllerView.swift
//  Futuristic Controller — space background (from AppShell) + morphing
//  constellation + car with violet under-glow + neon controls. No arrows.
//  Same BLE logic as before: Low/OnAir/High send height commands, Auto toggles,
//  All Down = triple-tap. The car rises/lowers subtly with the setting.
//

import SwiftUI

struct ControllerView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    @AppStorage("selectedModel") private var selectedModel = "model3"

    private var car: CarModel { CarModels.by(id: selectedModel) }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 393, 1.4)
            ZStack {
                // Constellation for the current setting (behind the content)
                ConstellationView(height: s.height)
                    .frame(width: geo.size.width * 0.86, height: 180 * scale)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.22)
                    .animation(.easeInOut(duration: 0.7), value: s.height)

                VStack(spacing: 0) {
                    Image("image_onair").resizable().scaledToFit()
                        .frame(width: 150 * scale)

                    Spacer().frame(height: 44 * scale)
                    carView(scale: scale)
                    Spacer().frame(height: 46 * scale)
                    heightSelector(scale: scale)
                    Spacer().frame(height: 36 * scale)
                    autoAndAllDown(scale: scale)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: geo.size.height * 0.02)
            }
        }
    }

    // MARK: Car (under-glow + rise/lower)

    private func carView(scale: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [OnAirTheme.violet.opacity(0.55), .clear],
                                     center: .center, startRadius: 0, endRadius: 150 * scale))
                .frame(width: 320 * scale, height: 150 * scale)
                .blur(radius: 28)
                .offset(y: 44 * scale)

            Image(car.image).resizable().scaledToFit()
                .frame(width: 240 * scale)

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(car.brand); Text(car.line)
                }
                .font(.system(size: 14 * scale, weight: .semibold))
                .foregroundColor(OnAirTheme.text)
            }
            .frame(width: 300 * scale)
            .offset(y: 48 * scale)
        }
        .offset(y: carOffset(scale))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: s.height)
    }

    private func carOffset(_ scale: CGFloat) -> CGFloat {
        switch s.height {
        case .high:    return -14 * scale
        case .low:     return 12 * scale
        case .allDown: return 22 * scale
        default:       return 0
        }
    }

    // MARK: LOW / ON AIR / HIGH

    private func heightSelector(scale: CGFloat) -> some View {
        let w = 280 * scale
        return ZStack {
            Capsule()
                .fill(Color.black.opacity(0.25))
                .overlay(Capsule().stroke(OnAirTheme.violet.opacity(0.7), lineWidth: 2))
                .shadow(color: OnAirTheme.violet.opacity(0.7), radius: 10)
                .frame(width: w, height: 58 * scale)
            HStack(spacing: 0) {
                seg("LOW",    .low,   OnAirCommand.low,   scale)
                seg("ON AIR", .onair, OnAirCommand.onair, scale)
                seg("HIGH",   .high,  OnAirCommand.high,  scale)
            }
            .frame(width: w)
        }
        .opacity(s.isRepairMode ? 0.4 : 1)
        .allowsHitTesting(!s.isRepairMode)
    }

    private func seg(_ title: String, _ h: SuspensionState.Height,
                     _ cmd: String, _ scale: CGFloat) -> some View {
        let active = s.height == h
        return Button {
            ble.send(cmd)
        } label: {
            Text(title)
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundColor(active ? .white : OnAirTheme.gray)
                .frame(maxWidth: .infinity).frame(height: 48 * scale)
                .background {
                    if active {
                        Capsule().fill(OnAirTheme.violet.opacity(0.35))
                            .shadow(color: OnAirTheme.violetGlow.opacity(0.9), radius: 10)
                    }
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: active)
    }

    // MARK: Auto + All Down

    private func autoAndAllDown(scale: CGFloat) -> some View {
        HStack {
            NeonCircle(title: "AUTO", active: s.isAuto, size: 92 * scale) {
                ble.send(s.isAuto ? OnAirCommand.closeAuto : OnAirCommand.openAuto)
            }
            Spacer()
            AllDownNeon(enabled: s.allDownEnable, size: 92 * scale) {
                ble.send(OnAirCommand.allDown)
            }
        }
        .frame(width: 280 * scale)
    }
}

// MARK: - Neon components

private struct NeonCircle: View {
    let title: String
    let active: Bool
    let size: CGFloat
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(active ? OnAirTheme.violet.opacity(0.3) : Color.black.opacity(0.25))
                Circle().stroke(OnAirTheme.violet.opacity(active ? 1 : 0.7), lineWidth: 2)
                Text(title).font(.system(size: size * 0.2, weight: .semibold))
                    .foregroundColor(active ? .white : OnAirTheme.violetLight)
            }
            .frame(width: size, height: size)
            .shadow(color: OnAirTheme.violet.opacity(active ? 0.9 : 0.5), radius: active ? 14 : 8)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: active)
    }
}

private struct AllDownNeon: View {
    let enabled: Bool
    let size: CGFloat
    let onActivate: () -> Void
    @State private var flash = false
    var body: some View {
        ZStack {
            Circle().fill(flash ? OnAirTheme.violetGlow.opacity(0.5) : Color.black.opacity(0.25))
            Circle().stroke(OnAirTheme.violet.opacity(0.85), lineWidth: 2)
            Text("ALL\nDOWN").font(.system(size: size * 0.18, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(OnAirTheme.violetLight)
        }
        .frame(width: size, height: size)
        .shadow(color: OnAirTheme.violet.opacity(flash ? 1 : 0.5), radius: flash ? 18 : 8)
        .opacity(enabled ? 1 : 0.4)
        .allowsHitTesting(enabled)
        .contentShape(Circle())
        .onTapGesture(count: 3) {
            onActivate()
            withAnimation { flash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { flash = false }
            }
        }
    }
}
