//
//  HoldButton.swift
//  A button that reports press and release separately.
//
//  Two modes:
//   • Momentary hold (wheels): fires onPress when touched, onRelease when let go.
//   • Timed hold (All Down):   set `minimumHold`; onHoldComplete fires only if the
//     press is held that long, with a progress ring for feedback.
//

import SwiftUI

struct HoldButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .accentColor
    var minimumHold: Double = 0            // 0 = momentary
    var onPress: () -> Void = {}
    var onRelease: () -> Void = {}
    var onHoldComplete: () -> Void = {}

    @State private var isPressed = false
    @State private var progress: Double = 0
    @State private var holdTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(isPressed ? 0.9 : 0.5))
            if minimumHold > 0 && isPressed {
                RoundedRectangle(cornerRadius: 12)
                    .trim(from: 0, to: progress)
                    .stroke(.white, lineWidth: 3)
                    .animation(.linear(duration: 0.05), value: progress)
            }
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { begin() } }
                .onEnded { _ in end() }
        )
    }

    private func begin() {
        isPressed = true
        onPress()
        guard minimumHold > 0 else { return }
        progress = 0
        holdTask = Task {
            let steps = 40
            let interval = minimumHold / Double(steps)
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { return }
                await MainActor.run { progress = Double(i) / Double(steps) }
            }
            if !Task.isCancelled {
                await MainActor.run { onHoldComplete() }
            }
        }
    }

    private func end() {
        isPressed = false
        holdTask?.cancel()
        holdTask = nil
        progress = 0
        onRelease()
    }
}
