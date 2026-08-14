//
//  StarfieldView.swift
//  GPU-drawn animated starfield — stars drift slowly upward and twinkle.
//  Uses TimelineView(.animation) + Canvas so it's smooth and battery-friendly.
//

import SwiftUI

/// Deterministic RNG so the star layout is stable across redraws.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

struct StarfieldView: View {
    private struct Star {
        let x: Double, y: Double, r: Double, phase: Double, twSpeed: Double, drift: Double
    }
    private let stars: [Star]

    init(count: Int = 130, seed: UInt64 = 7) {
        var rng = SeededRNG(seed: seed)
        stars = (0..<count).map { _ in
            Star(x: .random(in: 0...1, using: &rng),
                 y: .random(in: 0...1, using: &rng),
                 r: .random(in: 0.6...2.3, using: &rng),
                 phase: .random(in: 0...(2 * .pi), using: &rng),
                 twSpeed: .random(in: 0.6...2.0, using: &rng),
                 drift: .random(in: 0.004...0.02, using: &rng))
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for s in stars {
                    var y = s.y - (t * s.drift).truncatingRemainder(dividingBy: 1.0)
                    if y < 0 { y += 1 }
                    let twinkle = 0.35 + 0.5 * (0.5 + 0.5 * sin(t * s.twSpeed + s.phase))
                    let d = s.r * 2
                    let rect = CGRect(x: s.x * size.width, y: y * size.height, width: d, height: d)
                    ctx.fill(Path(ellipseIn: rect),
                             with: .color(OnAirTheme.starColor.opacity(twinkle)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Full-screen space backdrop: violet gradient + drifting stars.
struct SpaceBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [OnAirTheme.spaceTop, OnAirTheme.spaceMid, OnAirTheme.spaceBottom],
                           startPoint: .top, endPoint: .bottom)
            StarfieldView()
        }
        .ignoresSafeArea()
    }
}
