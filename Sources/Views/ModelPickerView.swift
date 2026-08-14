//
//  ModelPickerView.swift
//  First-run car-model selection. Mirrors the Android ChoesModeFragment,
//  which stores the choice under the "deviceType" key. No login required.
//

import SwiftUI

struct ModelPickerView: View {
    @Binding var selectedModel: String

    // Values mirror Common.SELECT_MODE_* in the Android source.
    private let models: [(label: String, value: String)] = [
        ("Tesla Model 3", "model3"),
        ("Tesla Model Y", "modelY"),
        ("XPeng P7",      "xPengP7"),
    ]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "car.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Choose your model")
                .font(.largeTitle.bold())
            Text("Select the vehicle your OnAir system is installed on.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 14) {
                ForEach(models, id: \.value) { model in
                    Button {
                        selectedModel = model.value
                    } label: {
                        Text(model.label)
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 28)
            Spacer()
        }
    }
}
