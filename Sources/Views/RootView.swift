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
            } else if state.isConnected {
                ControllerView()
            } else {
                ScanView()
            }
        }
        .animation(.default, value: selectedModel)
        .animation(.default, value: state.isConnected)
    }
}
