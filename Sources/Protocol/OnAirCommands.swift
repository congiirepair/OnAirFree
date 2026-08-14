//
//  OnAirCommands.swift
//  OnAirFree
//
//  Full BLE command set, ported 1:1 from the recovered Android source
//  (com.masoairOnair.isv.even.CommandConstant). These are the exact byte
//  frames your suspension controller expects — do not change the bytes.
//

import Foundation

/// Every command is a space-separated hex string, exactly as in the Android app.
/// `bytes` converts it to the raw `Data` written to the BLE characteristic.
enum OnAirCommand {

    // MARK: Primary protocol  "@ECU" framing  (40 45 43 55 ... 0D 0A)

    // Ride height presets
    static let low        = "40 45 43 55 B4 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let onair      = "40 45 43 55 B4 00 00 00 00 00 00 00 00 00 02 0D 0A"
    static let high       = "40 45 43 55 B4 00 00 00 00 00 00 00 00 00 03 0D 0A"

    // All-down (dump all struts) — press & hold ~3s in the original app
    static let allDown        = "40 45 43 55 B3 00 00 00 00 00 00 00 00 00 00 0D 0A"
    static let allDownEnable  = "40 45 43 55 C1 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let allDownDisable = "40 45 43 55 C1 00 00 00 00 00 00 00 00 00 02 0D 0A"

    // Manual wheel control (hold to move, release to stop)
    static let frontWheelUp        = "40 45 43 55 B0 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let backWheelUp         = "40 45 43 55 B0 00 00 00 00 00 00 00 00 00 02 0D 0A"
    static let frontBackWheelUp    = "40 45 43 55 B0 00 00 00 00 00 00 00 00 00 03 0D 0A"
    static let wheelUpStop         = "40 45 43 55 B0 00 00 00 00 00 00 00 00 00 04 0D 0A"

    static let frontWheelDown      = "40 45 43 55 B1 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let backWheelDown       = "40 45 43 55 B1 00 00 00 00 00 00 00 00 00 02 0D 0A"
    static let frontBackWheelDown  = "40 45 43 55 B1 00 00 00 00 00 00 00 00 00 03 0D 0A"
    static let wheelDownStop       = "40 45 43 55 B1 00 00 00 00 00 00 00 00 00 04 0D 0A"

    // Auto / leveling
    static let openAuto   = "40 45 43 55 B6 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let closeAuto  = "40 45 43 55 B6 00 00 00 00 00 00 00 00 00 02 0D 0A"
    static let autoLevel1 = "40 45 43 55 BE 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let autoLevel2 = "40 45 43 55 BE 00 00 00 00 00 00 00 00 00 02 0D 0A"
    static let autoLevel3 = "40 45 43 55 BE 00 00 00 00 00 00 00 00 00 03 0D 0A"

    // Memory heights: save current height into slot 1/2/3
    static let setMemory1 = "40 45 43 55 BC 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let setMemory2 = "40 45 43 55 BC 00 00 00 00 00 00 00 00 00 02 0D 0A"
    static let setMemory3 = "40 45 43 55 BC 00 00 00 00 00 00 00 00 00 03 0D 0A"

    // Repair mode
    static let openRepairMode  = "40 45 43 55 B7 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let closeRepairMode = "40 45 43 55 B7 00 00 00 00 00 00 00 00 00 02 0D 0A"

    // Smart-spend mode
    static let smartSpendOn  = "40 45 43 55 C8 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let smartSpendOff = "40 45 43 55 C8 00 00 00 00 00 00 00 00 00 02 0D 0A"

    // Queries / misc
    static let getAirBottlePressure = "40 45 43 55 B8 00 00 00 00 00 00 00 00 00 00 0D 0A"
    static let getDeviceInfo        = "40 45 43 55 C0 00 00 00 00 00 00 00 00 00 00 0D 0A"
    static let forcedToAir          = "40 45 43 55 BD 00 00 00 00 00 00 00 00 00 00 0D 0A"
    static let restoreExitSettings  = "40 45 43 55 BF 00 00 00 00 00 00 00 00 00 00 0D 0A"

    static let setValue1 = "40 45 43 55 B5 00 00 00 00 00 00 00 00 00 01 0D 0A"
    static let setValue2 = "40 45 43 55 B5 00 00 00 00 00 00 00 00 00 02 0D 0A"
    static let setValue3 = "40 45 43 55 B5 00 00 00 00 00 00 00 00 00 03 0D 0A"
    static let setValue4 = "40 45 43 55 B5 00 00 00 00 00 00 00 00 00 04 0D 0A"
    static let setValue5 = "40 45 43 55 B5 00 00 00 00 00 00 00 00 00 05 0D 0A"

    // MARK: Secondary protocol  (AA C1 ... EE)  — used by the memory-remote variant
    static let execMemory1 = "AA C1 01 00 00 EE"
    static let execMemory2 = "AA C1 00 10 00 EE"
    static let execMemory3 = "AA C1 00 08 00 EE"
    static let callMemory1 = "AA C1 00 11 00 EE"
    static let callMemory2 = "AA C1 00 12 00 EE"
    static let callMemory3 = "AA C1 00 13 00 EE"
    static let upKeyDown   = "AA C6 00 02 00 EE"
    static let upKeyUp     = "AA C4 00 31 00 EE"
    static let downKeyDown = "AA C7 00 40 00 EE"
    static let downKeyUp   = "AA C4 00 32 00 EE"
}

/// Prefixes of device→app status frames (see FrameParser).
enum OnAirResponse {
    static let ledUpDownPrefix  = "40 41 50 50 F0"   // up/down + LED state
    static let airVolumePrefix  = "40 41 50 50 F4"   // tank pressure + speed
    static let deviceStatePrefix = "40 41 50 50 FC"  // full device status
    static let warningPrefix    = "40 41 50 50 FD"   // fault flags
    static let autoPrefix       = "40 41 50 50 F2"   // auto on/off
    static let repairPrefix     = "40 41 50 50 F3"   // service/repair mode on/off
    static let smartSpendPrefix = "40 41 50 50 A0"   // smart-spend on
}

extension String {
    /// Convert a hex string like "40 45 43 55 ..." into `Data`.
    /// Mirrors UtilsBle.HexStringTobytes — whitespace is ignored.
    var onairHexData: Data {
        let cleaned = self.filter { $0.isHexDigit }
        var data = Data()
        var index = cleaned.startIndex
        while index < cleaned.endIndex, cleaned.index(after: index) < cleaned.endIndex {
            let next = cleaned.index(index, offsetBy: 2)
            if let byte = UInt8(cleaned[index..<next], radix: 16) {
                data.append(byte)
            }
            index = next
        }
        return data
    }
}

extension Data {
    /// "40 41 50 50 ..." — mirrors UtilsBle.bytesToHexString (upper-case, space-separated).
    var onairHexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
