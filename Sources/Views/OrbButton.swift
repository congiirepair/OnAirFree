//
//  OrbButton.swift
//  A metallic circular control that pairs with the carbon-fiber theme: domed
//  gunmetal face, beveled rim (light top → dark bottom), glossy sheen, and a
//  lift shadow for depth. It's engageable — presses in (scale + darken) with a
//  haptic tap, and lights up bright white when its mode is selected.
//

import SwiftUI
import UIKit

struct OrbButton<Content: View>: View {
    var selected: Bool
    var size: CGFloat
    var tapCount: Int = 1
    var enabled: Bool = true
    let action: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var pressed = false

    var body: some View {
        ZStack {
            // Domed metal face — dark gunmetal, or bright when selected.
            Circle()
                .fill(LinearGradient(
                    colors: selected
                        ? [Color(white: 0.98), Color(white: 0.72)]
                        : [Color(white: 0.24), Color(white: 0.055)],
                    startPoint: .top, endPoint: .bottom))

            // Glossy top sheen.
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(selected ? 0.7 : 0.30), .clear],
                    center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: size * 0.55))

            // Beveled rim: light top edge → dark bottom edge = raised metal.
            Circle()
                .strokeBorder(LinearGradient(
                    colors: [Color.white.opacity(0.55), Color.black.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom), lineWidth: 3)

            // Thin definition ring inside the rim.
            Circle()
                .stroke(selected ? Color.black.opacity(0.22) : Color.white.opacity(0.32), lineWidth: 1)
                .padding(3)

            content()
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.6), radius: pressed ? 3 : 8, y: pressed ? 1 : 5)   // lift
        .shadow(color: Color.white.opacity(selected ? 0.5 : 0), radius: 16)                 // glow when chosen
        .brightness(pressed ? -0.06 : 0)
        .scaleEffect(pressed ? 0.93 : (selected ? 1.05 : 1.0))
        .opacity(enabled ? 1 : 0.4)
        .allowsHitTesting(enabled)
        .contentShape(Circle())
        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !pressed { pressed = true } }
                .onEnded { _ in pressed = false }
        )
        .onTapGesture(count: tapCount) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }
    }
}
