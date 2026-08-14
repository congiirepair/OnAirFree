//
//  OrbButton.swift
//  A circular control with depth — convex gradient, top sheen, outer ring, and a
//  lift shadow. When `selected` it fills violet, glows, and scales up so the chosen
//  mode is unmistakable. Used by Low / OnAir / High / Auto / All Down.
//

import SwiftUI

struct OrbButton<Content: View>: View {
    var selected: Bool
    var size: CGFloat
    var tapCount: Int = 1
    var enabled: Bool = true
    let action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            // Convex base: lighter top → darker bottom reads as a raised dome.
            Circle()
                .fill(LinearGradient(
                    colors: selected
                        ? [OnAirTheme.violet.opacity(0.95), OnAirTheme.violet.opacity(0.40)]
                        : [Color(white: 0.17), Color(white: 0.05)],
                    startPoint: .top, endPoint: .bottom))

            // Top sheen — light catching the upper edge.
            Circle()
                .stroke(LinearGradient(
                    colors: [Color.white.opacity(selected ? 0.6 : 0.32), .clear],
                    startPoint: .top, endPoint: .center),
                    lineWidth: 1.5)

            // Outer ring (brighter when chosen).
            Circle()
                .stroke(OnAirTheme.violet.opacity(selected ? 1 : 0.5),
                        lineWidth: selected ? 2.5 : 1.5)

            content()
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.55), radius: 6, y: 4)                        // lift/depth
        .shadow(color: OnAirTheme.violet.opacity(selected ? 0.85 : 0), radius: 16)   // glow when chosen
        .scaleEffect(selected ? 1.06 : 1.0)
        .opacity(enabled ? 1 : 0.4)
        .allowsHitTesting(enabled)
        .contentShape(Circle())
        .onTapGesture(count: tapCount) { action() }
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
    }
}
