//
//  RootView.swift
//  Routing: first-run model picker → device scan/connect → controller.
//  There is NO login anywhere in this app (free for everyone).
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var state: SuspensionState
    @AppStorage("selectedModel") private var selectedModel = ""

    var body: some View {
        Group {
            if selectedModel.isEmpty {
                // First launch after install — choose your car model (like the Android app).
                ModelPickerView(selectedModel: $selectedModel)
            } else {
                // Controller is the default; the shell's toolbar handles menu + connect.
                AppShell()
            }
        }
        .animation(.default, value: selectedModel)
    }
}
