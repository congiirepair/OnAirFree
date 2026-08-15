//
//  DebugScreen.swift
//  Live Bluetooth diagnostics — the chosen write characteristic, and a colour-coded
//  log of every frame sent (TX) and received (RX). Test buttons fire each height
//  command directly so you can see exactly what goes out and what comes back.
//

import SwiftUI

struct DebugScreen: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var s: SuspensionState

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(s.isConnected ? "CONNECTED  \(s.connectedName)" : "NOT CONNECTED")
                    .foregroundColor(s.isConnected ? .green : .red)
                Text("write char: \(ble.writeCharInfo)").foregroundColor(.white)
                Text("pressure: \(s.airPressure)   height: \(s.height.rawValue)   auto: \(s.isAuto ? "on" : "off")")
                    .foregroundColor(OnAirTheme.gray)
            }
            .font(.system(size: 13, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))

            HStack(spacing: 8) {
                testBtn("LOW", OnAirCommand.low)
                testBtn("ONAIR", OnAirCommand.onair)
                testBtn("HIGH", OnAirCommand.high)
                testBtn("INFO", OnAirCommand.getDeviceInfo)
            }

            HStack {
                Button("Clear log") { ble.clearDebug() }
                    .font(.system(size: 13)).foregroundColor(OnAirTheme.gray)
                Spacer()
                Text("\(ble.debugLines.count) lines")
                    .font(.caption).foregroundColor(OnAirTheme.gray)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(ble.debugLines.enumerated()), id: \.offset) { i, line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(color(for: line))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(i)
                        }
                    }
                    .padding(8)
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.45)))
                .onChange(of: ble.debugLines.count) { _, c in
                    if c > 0 { withAnimation { proxy.scrollTo(c - 1, anchor: .bottom) } }
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 20)
    }

    private func testBtn(_ title: String, _ cmd: String) -> some View {
        Button(title) { ble.send(cmd) }
            .font(.system(size: 13, weight: .bold)).foregroundColor(.black)
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(Capsule().fill(Color.white))
    }

    private func color(for line: String) -> Color {
        if line.hasPrefix("TX FAIL") { return .red }
        if line.hasPrefix("TX")      { return Color(white: 0.95) }
        if line.hasPrefix("RX")      { return .green }
        if line.hasPrefix("→")       { return .yellow }
        return OnAirTheme.gray
    }
}
