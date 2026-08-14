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
                .opacity(0.38)                       // fade the weave so it's subtle
            // darken overall, strongest toward the edges
            RadialGradient(colors: [Color.black.opacity(0.30), Color.black.opacity(0.78)],
                           center: .center, startRadius: 90, endRadius: 700)
        }
        .ignoresSafeArea()
    }
}
