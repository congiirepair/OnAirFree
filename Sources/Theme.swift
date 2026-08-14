//
//  Theme.swift
//  Black & white / carbon-fiber theme. The `mono*` tokens are the monochrome
//  accent used for rings, text, glows and selected states.
//

import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

enum OnAirTheme {
    // Core surfaces
    static let background   = Color(hex: 0x0A0A0A)   // near-black
    static let text         = Color.white
    static let gray         = Color(hex: 0x8A8A8A)   // neutral gray
    static let divider      = Color(hex: 0x2A2A2A)
    static let line         = Color(hex: 0x333333)
    static let buttonLine   = Color(hex: 0xBBBBBB)
    static let menuLine     = Color(hex: 0xC8C8C8)
    static let deviceItemBg = Color(white: 0.14)
    static let errorText    = Color.white
    static let primary      = Color(hex: 0x1A1A1A)
    static let blue         = Color(hex: 0x2A2A2A)
    static let accent       = Color.white            // B&W accent (buttons/pills)

    // Monochrome accent (rings, text, glows, selected) — replaces the old violet.
    static let mono      = Color.white
    static let monoSoft  = Color(white: 0.72)
    static let monoGlow  = Color.white

    // Carbon surfaces
    static let carbon    = Color(hex: 0x0C0C0C)
    static let panel     = Color(white: 0.11)
}
