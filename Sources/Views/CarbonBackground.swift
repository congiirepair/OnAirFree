//
//  CarbonBackground.swift
//  Full-screen carbon-fiber backdrop (a seamless 2x2 twill tile) with a soft
//  center light and darkened edges for depth.
//

import SwiftUI

struct CarbonBackground: View {
    var body: some View {
        ZStack {
            Color.black
            Image("carbon_tile")
                .resizable(resizingMode: .tile)
            RadialGradient(colors: [Color.white.opacity(0.05), .clear, Color.black.opacity(0.55)],
                           center: .center, startRadius: 80, endRadius: 640)
        }
        .ignoresSafeArea()
    }
}
