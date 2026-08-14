//
//  Navigation.swift
//  Screen routing for the app shell (mirrors MainActivity's fragment switching).
//

import SwiftUI

enum Screen: Hashable {
    case controller, menu, deviceList
    case language, smartSpeed, airTank, serviceMode
    case errorNotification, guide, myAccount, allDown, factoryReset, engineer, debug

    /// Toolbar title (empty on the controller, like the original).
    var title: String {
        switch self {
        case .controller:       return ""
        case .menu:             return ""
        case .deviceList:       return "Bluetooth"
        case .language:         return "Language"
        case .smartSpeed:       return "Smart Speed"
        case .airTank:          return "Air Tank Pressure"
        case .serviceMode:      return "Service Mode"
        case .errorNotification:return "Error Notification"
        case .guide:            return "Guide"
        case .myAccount:        return "My Account"
        case .allDown:          return "All Down"
        case .factoryReset:     return "Factory Reset"
        case .engineer:         return "Engineer Mode"
        case .debug:            return "Debug Mode"
        }
    }
}

final class NavModel: ObservableObject {
    @Published var screen: Screen = .controller

    func go(_ s: Screen) { screen = s }
    func back() { screen = .controller }
    func openMenu() { screen = .menu }
}

/// A menu row (order matches the original menu_string_arry).
struct MenuEntry: Identifiable {
    let id = UUID()
    let title: String
    let screen: Screen
    let requiresConnection: Bool
    let hidden: Bool          // engineer/debug: revealed by a triple-tap

    static let all: [MenuEntry] = [
        MenuEntry(title: "Bluetooth",         screen: .deviceList,        requiresConnection: false, hidden: false),
        MenuEntry(title: "Language",          screen: .language,          requiresConnection: false, hidden: false),
        MenuEntry(title: "Smart Speed",       screen: .smartSpeed,        requiresConnection: false, hidden: false),
        MenuEntry(title: "Air Tank Pressure", screen: .airTank,           requiresConnection: true,  hidden: false),
        MenuEntry(title: "Service Mode",      screen: .serviceMode,       requiresConnection: true,  hidden: false),
        MenuEntry(title: "Error Notification",screen: .errorNotification, requiresConnection: false, hidden: false),
        MenuEntry(title: "Guide",             screen: .guide,             requiresConnection: false, hidden: false),
        MenuEntry(title: "My Account",        screen: .myAccount,         requiresConnection: false, hidden: false),
        MenuEntry(title: "All Down",          screen: .allDown,           requiresConnection: true,  hidden: false),
        MenuEntry(title: "Factory Reset",     screen: .factoryReset,      requiresConnection: true,  hidden: false),
        MenuEntry(title: "Engineer Mode",     screen: .engineer,          requiresConnection: false, hidden: true),
        MenuEntry(title: "Debug Mode",        screen: .debug,             requiresConnection: false, hidden: true),
    ]
}
