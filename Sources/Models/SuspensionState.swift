//
//  SuspensionState.swift
//  OnAirFree
//
//  Observable snapshot of the controller state, plus the frame parser.
//  Bit layouts are ported 1:1 from com.masoairOnair.isv.utils.UtilsViewStatus
//  (setAirDeviceStatus / setAirVolueParse / setLedStatus / setWaringStatus).
//  All reads are indexed from the END of the frame, exactly like the Android code.
//

import Foundation
import Combine

@MainActor
final class SuspensionState: ObservableObject {

    // Connection
    @Published var isConnected = false
    @Published var connectedName = ""

    // Ride height (mutually exclusive, like the Android setters)
    enum Height: String { case none, low, onair, high, allDown }
    @Published var height: Height = .none

    // Modes
    @Published var isAuto = false
    @Published var allDownEnable = false
    @Published var smartSpeedEnable = false
    @Published var smartSpeedMode = false
    @Published var autoLevel1 = false
    @Published var autoLevel2 = false
    @Published var autoLevel3 = false
    @Published var isRepairMode = false

    // Live values
    @Published var airPressure = "0"     // tank pressure (AirVolue)
    @Published var currentSpeed = 0

    // Up/down LED indicators
    @Published var ledUp = false
    @Published var ledDown = false
    @Published var ledStop = false

    // Warnings / faults
    @Published var warnFrontHeightSensor = false
    @Published var warnBackHeightSensor = false
    @Published var warnAirTank = false
    @Published var warnAirPump = false
    @Published var warnDevice = false
    @Published var warnMcu = false
    var anyWarning: Bool {
        warnFrontHeightSensor || warnBackHeightSensor || warnAirTank || warnAirPump || warnDevice
    }

    /// Reset everything on disconnect (mirrors UtilsViewStatus.resetData).
    func reset() {
        isConnected = false
        height = .none
        isAuto = false; allDownEnable = false
        smartSpeedEnable = false; smartSpeedMode = false
        autoLevel1 = false; autoLevel2 = false; autoLevel3 = false
        isRepairMode = false
        airPressure = "0"; currentSpeed = 0
        ledUp = false; ledDown = false; ledStop = false
        warnFrontHeightSensor = false; warnBackHeightSensor = false
        warnAirTank = false; warnAirPump = false; warnDevice = false; warnMcu = false
    }
}

/// Turns an incoming notification frame into state updates.
@MainActor
enum FrameParser {

    static func apply(_ data: Data, to s: SuspensionState) {
        let hex = data.onairHexString              // e.g. "40 41 50 50 FC ... 0D 0A"
        let b = [UInt8](data)
        guard b.count >= 6 else { return }
        let n = b.count

        // Helper: byte counted from the end (Android uses bArr[len-3] etc.)
        func fromEnd(_ k: Int) -> UInt8 { b[n - k] }

        if hex.contains(OnAirResponse.deviceStatePrefix) {          // 40 41 50 50 FC
            let s3 = fromEnd(3), s4 = fromEnd(4), s5 = fromEnd(5), s6 = fromEnd(6)
            setHeight(s, low: s3 & 1 == 1, onair: s3 & 2 == 2,
                         high: s3 & 4 == 4, allDown: s3 & 8 == 8)
            s.isAuto           = s4 & 1 == 1
            s.allDownEnable    = s4 & 2 == 2
            s.smartSpeedEnable = s4 & 4 == 4
            s.smartSpeedMode   = s4 & 8 == 8
            s.autoLevel1       = s5 & 1 == 1
            s.autoLevel2       = s5 & 2 == 2
            s.autoLevel3       = s5 & 4 == 4
            s.isRepairMode     = s6 & 1 == 1

        } else if hex.contains(OnAirResponse.airVolumePrefix) {     // 40 41 50 50 F4
            s.airPressure  = byteToPressureString(fromEnd(3))
            s.currentSpeed = Int(fromEnd(4))

        } else if hex.contains(OnAirResponse.ledUpDownPrefix) {     // 40 41 50 50 F0
            let s3 = fromEnd(3), s4 = fromEnd(4)
            s.ledUp   = s3 & 1 == 1
            s.ledDown = s3 & 2 == 2
            s.ledStop = s3 & 4 == 4
            if s3 & 1 == 1 || s3 & 2 == 2 {
                setHeight(s, low: s4 & 1 == 1, onair: s4 & 2 == 2,
                             high: s4 & 4 == 4, allDown: s4 & 8 == 8)
            }

        } else if hex.contains(OnAirResponse.warningPrefix) {       // 40 41 50 50 FD
            let s3 = fromEnd(3), s4 = fromEnd(4), s5 = fromEnd(5), s6 = fromEnd(6)
            s.warnFrontHeightSensor = s3 & 1 == 1
            s.warnBackHeightSensor  = s3 & 2 == 2
            s.warnAirTank           = s4 & 1 == 1
            s.warnAirPump           = s5 & 1 == 1
            s.warnDevice            = s5 & 4 == 4       // matches UtilsViewStatus (2nd setIsDvcWarining wins)
            s.warnMcu               = s6 & 1 == 1

        } else if hex.contains(OnAirResponse.autoPrefix) {          // 40 41 50 50 F2
            // "close auto" is the ...02 variant; anything else = auto on
            s.isAuto = !hex.trimmingCharacters(in: .whitespaces)
                .hasSuffix("F2 00 00 00 02 0D 0A")

        } else if hex.contains(OnAirResponse.repairPrefix) {        // 40 41 50 50 F3
            s.isRepairMode = hex.contains("F3 00 00 00 01")         // ...01 open, ...02 close

        } else if hex.contains(OnAirResponse.smartSpendPrefix) {    // 40 41 50 50 A0
            s.smartSpeedMode = hex.contains("A0 00 00 00 01")
        }
    }

    /// Only one height flag wins, matching the mutually-exclusive Android setters.
    private static func setHeight(_ s: SuspensionState,
                                  low: Bool, onair: Bool, high: Bool, allDown: Bool) {
        if allDown { s.height = .allDown }
        else if high { s.height = .high }
        else if onair { s.height = .onair }
        else if low { s.height = .low }
    }

    /// Mirrors UtilsBle.ByteToString. (The original's "240" special case compares
    /// the decimal string to "1100000000", which can never match a 0-255 byte, so
    /// the effective behavior — here and in the original — is just the byte value.)
    private static func byteToPressureString(_ byte: UInt8) -> String {
        String(Int(byte))
    }
}
