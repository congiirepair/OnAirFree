//
//  ControllerView.swift
//  Pixel-matched recreation of the original fragment_man_controller.xml,
//  using the real button/car/logo art extracted from the APK.
//
//  Layout (top → bottom), matching the original ConstraintLayout:
//    OnAir logo → up indicator → car image → down indicator (+warning +name)
//    → rounded Low/OnAir/High bar → Auto ........ All Down
//
//  The up/down arrows are STATUS INDICATORS (driven by ledUp/ledDown from the
//  device), exactly like the original — not buttons. Low/OnAir/High send the
//  height commands; Auto toggles; All Down needs a 5-second hold.
//

import SwiftUI

struct ControllerView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState
    @AppStorage("selectedModel") private var selectedModel = "model3"

    private var car: CarModel { CarModels.by(id: selectedModel) }

    var body: some View {
        ZStack {
            OnAirTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 8)

                Image("image_onair").resizable().scaledToFit()
                    .frame(width: 144, height: 60)

                Spacer(minLength: 12)

                // Up status indicator
                Image(s.ledUp ? "controll_up_light" : "controll_up_dark")
                    .resizable().scaledToFit().frame(width: 54, height: 26)

                // Car
                Image(car.image).resizable().scaledToFit()
                    .frame(width: 217, height: 102)

                // Down indicator, with warning (left) and car name (right)
                ZStack {
                    Image(s.ledDown ? "controll_down_light" : "controll_down_dark")
                        .resizable().scaledToFit().frame(width: 54, height: 26)
                    HStack {
                        Image("menu_system_display_warning")
                            .resizable().frame(width: 25, height: 25)
                            .opacity(s.anyWarning ? 1 : 0)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(car.brand)
                            Text(car.line)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(OnAirTheme.text)
                    }
                    .padding(.horizontal, 26)
                }

                Spacer(minLength: 16)

                heightBar
                Spacer(minLength: 22)
                autoAndAllDown
                Spacer(minLength: 28)
            }
        }
    }

    // MARK: Low / OnAir / High

    private var heightBar: some View {
        ZStack {
            Capsule()
                .fill(OnAirTheme.background)
                .overlay(Capsule().stroke(OnAirTheme.buttonLine, lineWidth: 2))
                .frame(width: 235, height: 37)

            HStack(spacing: 0) {
                heightButton(.low,   "controll_low_normoal", "controll_low_select")
                Spacer()
                heightButton(.onair, "controll_onair",       "controll_onair_checked")
                Spacer()
                heightButton(.high,  "high_normal",          "high")
            }
            .frame(width: 235)
        }
        .frame(height: 52)         // buttons sit slightly proud of the bar
        .opacity(s.isRepairMode ? 0.4 : 1)
        .allowsHitTesting(!s.isRepairMode)
    }

    private func heightButton(_ h: SuspensionState.Height,
                              _ normal: String, _ selected: String) -> some View {
        let isSel = s.height == h
        let cmd = h == .low ? OnAirCommand.low : h == .onair ? OnAirCommand.onair : OnAirCommand.high
        return Button {
            ble.send(cmd)
        } label: {
            Image(isSel ? selected : normal)
                .resizable().scaledToFit()
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
    }

    // MARK: Auto + All Down

    private var autoAndAllDown: some View {
        HStack {
            // Auto — toggles open/close auto
            Button {
                ble.send(s.isAuto ? OnAirCommand.closeAuto : OnAirCommand.openAuto)
            } label: {
                Image(s.isAuto ? "auto" : "auto_dark")
                    .resizable().scaledToFit().frame(width: 52, height: 52)
            }
            .buttonStyle(.plain)

            Spacer()

            // All Down — hold 5s to activate (safety)
            AllDownHoldButton(enabled: s.allDownEnable) {
                ble.send(OnAirCommand.allDown)
            }
        }
        .frame(width: 235)
    }
}

/// All-Down control using the real art; requires a 5-second hold, with a
/// progress ring for feedback (mirrors the original safety behavior).
private struct AllDownHoldButton: View {
    let enabled: Bool
    let onActivate: () -> Void

    init(enabled: Bool, onActivate: @escaping () -> Void) {
        self.enabled = enabled
        self.onActivate = onActivate
    }

    @State private var pressed = false
    @State private var progress: Double = 0
    @State private var task: Task<Void, Never>?

    var body: some View {
        ZStack {
            Image(pressed ? "all_down_slect" : "all_down_dark")
                .resizable().scaledToFit().frame(width: 52, height: 52)
            if pressed {
                Circle().trim(from: 0, to: progress)
                    .stroke(OnAirTheme.accent, lineWidth: 3)
                    .frame(width: 50, height: 50).rotationEffect(.degrees(-90))
            }
        }
        .opacity(enabled ? 1 : 0.4)
        .allowsHitTesting(enabled)
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in if !pressed { begin() } }
            .onEnded { _ in end() })
    }

    private func begin() {
        pressed = true; progress = 0
        task = Task {
            let steps = 50, hold = 5.0
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: UInt64(hold / Double(steps) * 1_000_000_000))
                if Task.isCancelled { return }
                await MainActor.run { progress = Double(i) / Double(steps) }
            }
            if !Task.isCancelled { await MainActor.run { onActivate() } }
        }
    }

    private func end() {
        pressed = false; progress = 0
        task?.cancel(); task = nil
    }
}
