//
//  ControllerView.swift
//  Pixel-matched recreation of the original fragment_man_controller.xml, sized
//  PROPORTIONALLY to the screen so it fills the same on any iPhone.
//
//  Layout (top → bottom): OnAir logo → up indicator → car → down indicator
//  (+warning +name) → Low/OnAir/High bar → Auto ...... All Down.
//
//  Up/down arrows are status indicators (ledUp/ledDown from the device).
//  Low/OnAir/High send height commands; Auto toggles; All Down = TRIPLE-TAP.
//

import SwiftUI

struct ControllerView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    @AppStorage("selectedModel") private var selectedModel = "model3"

    private var car: CarModel { CarModels.by(id: selectedModel) }

    var body: some View {
        GeometryReader { geo in
            // Scale everything relative to a 393pt reference width (mild cap for iPad).
            let scale = min(geo.size.width / 393, 1.4)
            ZStack {
                OnAirTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Image("image_onair").resizable().scaledToFit()
                        .frame(width: 150 * scale)

                    Spacer().frame(height: 34 * scale)

                    Image(s.ledUp ? "controll_up_light" : "controll_up_dark")
                        .resizable().scaledToFit().frame(width: 60 * scale)

                    Image(car.image).resizable().scaledToFit()
                        .frame(width: 230 * scale)

                    // Down indicator with warning (left) and car name (right)
                    ZStack {
                        Image(s.ledDown ? "controll_down_light" : "controll_down_dark")
                            .resizable().scaledToFit().frame(width: 60 * scale)
                        HStack {
                            Image("menu_system_display_warning")
                                .resizable().frame(width: 26 * scale, height: 26 * scale)
                                .opacity(s.anyWarning ? 1 : 0)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(car.brand)
                                Text(car.line)
                            }
                            .font(.system(size: 14 * scale, weight: .semibold))
                            .foregroundColor(OnAirTheme.text)
                        }
                        .padding(.horizontal, 24 * scale)
                    }

                    Spacer().frame(height: 40 * scale)

                    heightBar(scale: scale)

                    Spacer().frame(height: 34 * scale)

                    autoAndAllDown(scale: scale)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: -geo.size.height * 0.03)   // upper-center bias, matching the original
            }
        }
    }

    // MARK: Low / OnAir / High

    private func heightBar(scale: CGFloat) -> some View {
        let barW = 250 * scale
        return ZStack {
            Capsule()
                .fill(OnAirTheme.background)
                .overlay(Capsule().stroke(OnAirTheme.buttonLine, lineWidth: 2))
                .frame(width: barW, height: 40 * scale)

            HStack(spacing: 0) {
                heightButton(.low,   "controll_low_normoal", "controll_low_select", scale)
                Spacer()
                heightButton(.onair, "controll_onair",       "controll_onair_checked", scale)
                Spacer()
                heightButton(.high,  "high_normal",          "high", scale)
            }
            .frame(width: barW)
        }
        .frame(height: 56 * scale)
        .opacity(s.isRepairMode ? 0.4 : 1)
        .allowsHitTesting(!s.isRepairMode)
    }

    private func heightButton(_ h: SuspensionState.Height,
                              _ normal: String, _ selected: String, _ scale: CGFloat) -> some View {
        let isSel = s.height == h
        let cmd = h == .low ? OnAirCommand.low : h == .onair ? OnAirCommand.onair : OnAirCommand.high
        return Button {
            ble.send(cmd)
        } label: {
            Image(isSel ? selected : normal)
                .resizable().scaledToFit()
                .frame(width: 56 * scale, height: 56 * scale)
        }
        .buttonStyle(.plain)
    }

    // MARK: Auto + All Down

    private func autoAndAllDown(scale: CGFloat) -> some View {
        HStack {
            Button {
                ble.send(s.isAuto ? OnAirCommand.closeAuto : OnAirCommand.openAuto)
            } label: {
                Image(s.isAuto ? "auto" : "auto_dark")
                    .resizable().scaledToFit().frame(width: 56 * scale, height: 56 * scale)
            }
            .buttonStyle(.plain)

            Spacer()

            AllDownTripleTap(enabled: s.allDownEnable, size: 56 * scale) {
                ble.send(OnAirCommand.allDown)
            }
        }
        .frame(width: 250 * scale)
    }
}

/// All-Down control using the real art — activates on a TRIPLE-TAP (per request),
/// with a brief highlight flash for feedback.
private struct AllDownTripleTap: View {
    let enabled: Bool
    let size: CGFloat
    let onActivate: () -> Void

    @State private var flash = false

    var body: some View {
        Image(flash ? "all_down_slect" : "all_down_dark")
            .resizable().scaledToFit()
            .frame(width: size, height: size)
            .opacity(enabled ? 1 : 0.4)
            .contentShape(Rectangle())
            .allowsHitTesting(enabled)
            .onTapGesture(count: 3) {
                onActivate()
                flash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { flash = false }
            }
    }
}
