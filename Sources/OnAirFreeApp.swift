//
//  OnAirFreeApp.swift
//  OnAirFree — free, no-login iOS port of the MyOnair air-suspension app.
//

import SwiftUI

@main
struct OnAirFreeApp: App {
    @StateObject private var ble = BLEManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(ble)
                .environmentObject(ble.state)   // nested state observed directly by views
        }
    }
}
