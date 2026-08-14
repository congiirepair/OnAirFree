//
//  CarModels.swift
//  The selectable vehicle models, matching the original ChoesModeFragment.
//  `id` is the exact value stored as "deviceType" in the original app
//  (Common.SELECT_* — kept verbatim, including the original's quirks).
//

import Foundation

struct CarModel: Identifiable, Hashable {
    let id: String       // stored deviceType value (e.g. "model3")
    let display: String  // dropdown label
    let image: String    // asset-catalog image name
    let brand: String    // Controller top line
    let line: String     // Controller second line
}

enum CarModels {
    static let all: [CarModel] = [
        CarModel(id: "model3",         display: "TESLA MODEL 3",   image: "car_mode3",           brand: "TESLA",  line: "MODEL 3"),
        CarModel(id: "modelY",         display: "TESLA MODEL Y",   image: "car_modey",           brand: "TESLA",  line: "MODEL Y"),
        CarModel(id: "xPengP7",        display: "XPENG P7",        image: "car_peng7",           brand: "XPENG",  line: "P7"),
        CarModel(id: "lexusLM",        display: "LEXUS LM",        image: "car_lexus_lm",        brand: "LEXUS",  line: "LM"),
        CarModel(id: "toyotaAIphard",  display: "TOYOTA ALPHARD",  image: "car_toyota_alphard",  brand: "TOYOTA", line: "ALPHARD"),
        CarModel(id: "toyotaVeIIfire", display: "TOYOTA VELLFIRE", image: "car_toyota_vellfire", brand: "TOYOTA", line: "VELLFIRE"),
        CarModel(id: "zeekr001",       display: "ZEEKR 001",       image: "car_zeekr_001",       brand: "ZEEKR",  line: "001"),
    ]

    static func by(id: String) -> CarModel {
        all.first { $0.id == id } ?? all[0]
    }
}
