//
//  ConstellationView.swift
//  A glowing constellation that changes with the ride-height setting.
//  Each setting (Low / On Air / High / All Down) has its own star pattern;
//  changing setting cross-fades to the new one.
//

import SwiftUI

struct ConstellationView: View {
    let height: SuspensionState.Height
    var accent: Color = OnAirTheme.violet

    // Normalized (0...1) points per setting. Sequential points are connected.
    private func pattern(_ h: SuspensionState.Height) -> [CGPoint] {
        switch h {
        case .low:                       // low, flat sweep
            return [p(0.08,0.62), p(0.28,0.52), p(0.46,0.60), p(0.63,0.50), p(0.82,0.58), p(0.95,0.52)]
        case .high:                      // ascending toward the sky
            return [p(0.06,0.74), p(0.24,0.62), p(0.42,0.46), p(0.60,0.34), p(0.80,0.20), p(0.95,0.10)]
        case .allDown:                   // collapsed low cluster
            return [p(0.16,0.70), p(0.34,0.76), p(0.51,0.70), p(0.68,0.77), p(0.85,0.70), p(0.51,0.60)]
        default:                         // On Air / none — balanced zigzag
            return [p(0.08,0.55), p(0.27,0.34), p(0.45,0.50), p(0.63,0.30), p(0.81,0.45), p(0.95,0.28)]
        }
    }
    private func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    var body: some View {
        Canvas { ctx, size in
            let pts = pattern(height).map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
            // connecting lines
            var line = Path()
            line.move(to: pts[0])
            for pt in pts.dropFirst() { line.addLine(to: pt) }
            ctx.stroke(line, with: .color(accent.opacity(0.55)), lineWidth: 2)
            // star nodes
            for pt in pts {
                let r: CGFloat = 5
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r*2, height: r*2)),
                         with: .color(accent))
                let r2: CGFloat = 2
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r2, y: pt.y - r2, width: r2*2, height: r2*2)),
                         with: .color(.white))
            }
        }
        .shadow(color: accent.opacity(0.8), radius: 8)
        .id(height)                                   // new identity per setting…
        .transition(.opacity)                         // …so the change cross-fades
        .allowsHitTesting(false)
    }
}
