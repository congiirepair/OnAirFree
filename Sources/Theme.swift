//
//  Theme.swift
//  Colors ported from the original app's res/values/colors.xml so the iOS
//  build matches the Android dark theme exactly.
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

/// The OnAir palette (values from colors.xml).
enum OnAirTheme {
    static let background   = Color(hex: 0x161719)   // colorBackground / black
    static let primary      = Color(hex: 0x232C37)   // colorPrimary(Dark)
    static let accent       = Color(hex: 0x1E90FF)   // btntextcolor (dodger blue)
    static let blue         = Color(hex: 0x123256)   // blue
    static let gray         = Color(hex: 0x8B97A6)   // colorGray
    static let divider      = Color(hex: 0x5A6573)   // colorDivider
    static let line         = Color(hex: 0x37393B)   // color_line
    static let buttonLine   = Color(hex: 0xBBBBBB)   // color_butten_line
    static let menuLine      = Color(hex: 0xBCC3C7)  // color_menu_line / editext
    static let text         = Color.white            // color_text
    static let deviceItemBg = Color(hex: 0x8B97A6).opacity(0.53) // colorDeviceListItemBg (#888b97a6)
    static let errorText    = Color.white
}
