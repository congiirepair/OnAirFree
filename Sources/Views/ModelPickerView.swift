//
//  ModelPickerView.swift
//  Pixel-matched recreation of activity_choes_mode.xml — the OnAir logo over a
//  "Vehicle Model" dropdown that reveals the selectable models. No login.
//  Selecting one stores the deviceType (like the original) and continues.
//

import SwiftUI

struct ModelPickerView: View {
    @Binding var selectedModel: String
    @State private var expanded = false

    var body: some View {
        ZStack {
            SpaceBackground()

            GeometryReader { geo in
                VStack(spacing: 18) {
                    Spacer().frame(height: geo.size.height * 0.22)

                    Image("image_onair").resizable().scaledToFit()
                        .frame(width: 180, height: 76)

                    // "Vehicle Model" selector
                    Button {
                        withAnimation(.easeInOut) { expanded.toggle() }
                    } label: {
                        HStack {
                            Text("Vehicle Model")
                            Spacer()
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(OnAirTheme.text)
                        .padding(.horizontal, 22).frame(height: 46)
                        .frame(width: 240)
                        .overlay(RoundedRectangle(cornerRadius: 23)
                            .stroke(OnAirTheme.buttonLine, lineWidth: 2))
                    }

                    if expanded {
                        VStack(spacing: 0) {
                            ForEach(CarModels.all) { model in
                                Button {
                                    selectedModel = model.id      // store deviceType, then RootView advances
                                } label: {
                                    Text(model.display)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(OnAirTheme.background)
                                        .frame(maxWidth: .infinity).frame(height: 40)
                                        .background(OnAirTheme.menuLine)
                                        .overlay(Divider().background(OnAirTheme.background), alignment: .bottom)
                                }
                            }
                        }
                        .frame(width: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
