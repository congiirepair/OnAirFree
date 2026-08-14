//
//  ControllerView.swift
//  Carbon-fiber Controller — static car over a soft light pool, with metallic
//  orb controls (Low / OnAir / High / Auto / All Down). Same BLE logic.
//

import SwiftUI

struct ControllerView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    @AppStorage("selectedModel") private var selectedModel = "model3"
    @State private var showHighWarning = false

    private var car: CarModel { CarModels.by(id: selectedModel) }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 393, 1.4)
            VStack(spacing: 0) {
                Image("image_onair").resizable().scaledToFit()
                    .frame(width: 150 * scale)

                Spacer().frame(height: 44 * scale)
                carView(scale: scale)
                Spacer().frame(height: 50 * scale)
                heightOrbs(scale: scale)
                Spacer().frame(height: 26 * scale)
                autoAllDownOrbs(scale: scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .offset(y: geo.size.height * 0.02)
            .alert("Slow below 40 before raising to HIGH.", isPresented: $showHighWarning) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    // MARK: Car (static, on a soft light pool)

    private func carView(scale: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Color.white.opacity(0.16), .clear],
                                     center: .center, startRadius: 0, endRadius: 150 * scale))
                .frame(width: 320 * scale, height: 150 * scale)
                .blur(radius: 26)
                .offset(y: 44 * scale)

            Image(car.image).resizable().scaledToFit()
                .frame(width: 240 * scale)
                .shadow(color: .black.opacity(0.5), radius: 14, y: 8)
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
                .foregroundColor(s.height == h ? .black : .white)
        }
    }

    private func onairOrb(_ scale: CGFloat) -> some View {
        let sel = s.height == .onair
        return OrbButton(selected: sel, size: 96 * scale,
                         action: { ble.send(OnAirCommand.onair) }) {
            Image("onair_mark").renderingMode(.template).resizable().scaledToFit()
                .frame(width: 48 * scale, height: 48 * scale)
                .foregroundColor(sel ? .black : .white)
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
                    .foregroundColor(s.isAuto ? .black : .white)
            }

            Spacer()

            // All Down — triple-tap to activate (safety); disabled until enabled.
            OrbButton(selected: s.height == .allDown, size: 84 * scale, tapCount: 3,
                      enabled: s.allDownEnable && !s.isRepairMode,
                      action: { ble.send(OnAirCommand.allDown) }) {
                Text("ALL\nDOWN")
                    .font(.system(size: 13 * scale, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(s.height == .allDown ? .black : .white)
            }
        }
        .frame(width: 268 * scale)
    }
}
