//
//  ControllerView.swift
//  Futuristic Controller — space background + morphing constellation + hovering
//  car + circular ORB controls (Low / OnAir / High / Auto / All Down) with depth.
//  The chosen mode glows; the OnAir orb carries the OnAir mark. Same BLE logic.
//

import SwiftUI

struct ControllerView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    @AppStorage("selectedModel") private var selectedModel = "model3"
    @State private var showHighWarning = false
    @State private var hover = false        // ambient float
    @State private var glowPulse = false    // ambient under-glow breathing

    private var car: CarModel { CarModels.by(id: selectedModel) }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 393, 1.4)
            ZStack {
                ConstellationView(height: s.height)
                    .frame(width: geo.size.width * 0.86, height: 180 * scale)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.20)
                    .animation(.easeInOut(duration: 0.7), value: s.height)

                VStack(spacing: 0) {
                    Image("image_onair").resizable().scaledToFit()
                        .frame(width: 150 * scale)

                    Spacer().frame(height: 40 * scale)
                    carView(scale: scale)
                    Spacer().frame(height: 46 * scale)
                    heightOrbs(scale: scale)
                    Spacer().frame(height: 26 * scale)
                    autoAllDownOrbs(scale: scale)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: geo.size.height * 0.02)
            }
            .alert("Slow below 40 before raising to HIGH.", isPresented: $showHighWarning) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    // MARK: Car (hover + breathing glow + rise/lower)

    private func carView(scale: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [OnAirTheme.violet.opacity(0.55), .clear],
                                     center: .center, startRadius: 0, endRadius: 150 * scale))
                .frame(width: 320 * scale, height: 150 * scale)
                .blur(radius: 28)
                .offset(y: 44 * scale)
                .scaleEffect(glowPulse ? 1.06 : 0.94)
                .opacity(glowPulse ? 0.7 : 0.45)

            Image(car.image).resizable().scaledToFit()
                .frame(width: 240 * scale)
                .offset(y: hover ? -6 : 6)
                .shadow(color: OnAirTheme.violet.opacity(0.35), radius: 12, y: 6)

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
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { hover = true }
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) { glowPulse = true }
        }
    }

    private func carOffset(_ scale: CGFloat) -> CGFloat {
        switch s.height {
        case .high:    return -14 * scale
        case .low:     return 12 * scale
        case .allDown: return 22 * scale
        default:       return 0
        }
    }

    // MARK: Height orbs — Low / OnAir / High

    private func heightOrbs(scale: CGFloat) -> some View {
        HStack(spacing: 20 * scale) {
            heightOrb("LOW",  .low,  OnAirCommand.low,  scale, size: 84)
            onairOrb(scale)
            heightOrb("HIGH", .high, OnAirCommand.high, scale, size: 84)
        }
        .opacity(s.isRepairMode ? 0.4 : 1)
        .allowsHitTesting(!s.isRepairMode)
    }

    private func heightOrb(_ title: String, _ h: SuspensionState.Height,
                           _ cmd: String, _ scale: CGFloat, size: CGFloat) -> some View {
        OrbButton(selected: s.height == h, size: size * scale, action: {
            if h == .high, s.smartSpeedMode, s.currentSpeed > 40 { showHighWarning = true }
            else { ble.send(cmd) }
        }) {
            Text(title)
                .font(.system(size: 15 * scale, weight: .bold))
                .foregroundColor(s.height == h ? .white : OnAirTheme.violetLight)
        }
    }

    private func onairOrb(_ scale: CGFloat) -> some View {
        OrbButton(selected: s.height == .onair, size: 96 * scale,
                  action: { ble.send(OnAirCommand.onair) }) {
            Image("onair_mark").resizable().scaledToFit()
                .frame(width: 48 * scale, height: 48 * scale)
        }
    }

    // MARK: Auto / All Down orbs

    private func autoAllDownOrbs(scale: CGFloat) -> some View {
        HStack {
            OrbButton(selected: s.isAuto, size: 84 * scale, enabled: !s.isRepairMode, action: {
                ble.send(s.isAuto ? OnAirCommand.closeAuto : OnAirCommand.openAuto)
            }) {
                Text("AUTO")
                    .font(.system(size: 15 * scale, weight: .bold))
                    .foregroundColor(s.isAuto ? .white : OnAirTheme.violetLight)
            }

            Spacer()

            // All Down — triple-tap to activate (safety); disabled until enabled.
            OrbButton(selected: s.height == .allDown, size: 84 * scale, tapCount: 3,
                      enabled: s.allDownEnable && !s.isRepairMode,
                      action: { ble.send(OnAirCommand.allDown) }) {
                Text("ALL\nDOWN")
                    .font(.system(size: 13 * scale, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(s.height == .allDown ? .white : OnAirTheme.violetLight)
            }
        }
        .frame(width: 268 * scale)
    }
}
