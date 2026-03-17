//
//  ControlPanel.swift
//  HeatMapExample
//
//  Created by Tom Hoag on 3/16/26.
//

import HeatMap
import SwiftUI

enum GradientOption: String, CaseIterable, Identifiable {
    case thermal = "Thermal"
    case warm = "Warm"
    case cool = "Cool"

    var id: String { rawValue }

    var gradient: HeatMapGradient {
        switch self {
        case .thermal: .thermal
        case .warm: .warm
        case .cool: .cool
        }
    }
}

enum SmootherOption: String, CaseIterable, Identifiable {
    case none = "None"
    case chaikin1 = "Chaikin 1"
    case chaikin2 = "Chaikin 2"
    case chaikin3 = "Chaikin 3"

    var id: String { rawValue }

    var smoother: PolygonSmoother {
        switch self {
        case .none: .none
        case .chaikin1: .chaikin(iterations: 1)
        case .chaikin2: .chaikin(iterations: 2)
        case .chaikin3: .chaikin(iterations: 3)
        }
    }
}

enum LabelVisibilityOption: String, CaseIterable, Identifiable {
    case thresholds = "Thresholds"
    case lowHigh = "Low/High"
    case hidden = "Hidden"

    var id: String { rawValue }

    var visibility: HeatMapLegend.LabelVisibility {
        switch self {
        case .thresholds: .thresholds
        case .lowHigh: .lowHigh
        case .hidden: .hidden
        }
    }
}

struct ControlPanel: View {
    @Binding var radius: Double
    @Binding var contourLevels: Double
    @Binding var selectedGradient: GradientOption
    @Binding var fillOpacity: Double
    @Binding var selectedSmoother: SmootherOption
    @Binding var legendAxis: Axis
    @Binding var legendLabels: HeatMapLegend.LabelVisibility
    @Binding var showControls: Bool

    @State private var selectedLabelVisibility: LabelVisibilityOption = .thresholds

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Controls")
                    .font(.headline)
                Spacer()
                Button("Done", systemImage: "xmark.circle.fill") {
                    withAnimation(.smooth) {
                        showControls = false
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
            }

            // MARK: Heat Map
            VStack(spacing: 8) {
                Text("Heat Map")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Gradient", selection: $selectedGradient) {
                    ForEach(GradientOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Smoothing", selection: $selectedSmoother) {
                    ForEach(SmootherOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                LabeledContent("Radius: \(Int(radius / 1000))km") {
                    Slider(value: $radius, in: 50_000...300_000, step: 10_000)
                }

                LabeledContent("Levels: \(Int(contourLevels))") {
                    Slider(value: $contourLevels, in: 3...20, step: 1)
                }

                LabeledContent("Opacity: \(Int(fillOpacity * 100))%") {
                    Slider(value: $fillOpacity, in: 0...1, step: 0.05)
                }
            }

            Divider()

            // MARK: Legend
            VStack(spacing: 8) {
                Text("Legend")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Picker("Orientation", selection: $legendAxis) {
                        Text("Vertical").tag(Axis.vertical)
                        Text("Horizontal").tag(Axis.horizontal)
                    }
                    .pickerStyle(.segmented)

                    Picker("Labels", selection: $selectedLabelVisibility) {
                        ForEach(LabelVisibilityOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedLabelVisibility) { _, newValue in
                        legendLabels = newValue.visibility
                    }
                }
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}
