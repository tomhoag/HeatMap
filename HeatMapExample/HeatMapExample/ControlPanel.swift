//
//  ControlPanel.swift
//  HeatMapExample
//
//  Created by Tom Hoag on 3/16/26.
//

import HeatMap
import SwiftUI

struct ControlPanel: View {
    @Binding var radius: Double
    @Binding var contourLevels: Double
    @Binding var selectedGradient: GradientOption
    @Binding var fillOpacity: Double
    @Binding var selectedStroke: StrokeOption
    @Binding var selectedRenderMode: RenderModeOption
    @Binding var selectedIsolineColor: IsolineColorOption
    @Binding var selectedSpacing: SpacingOption
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

                LabeledContent("Render:") {
                    Picker("Render", selection: $selectedRenderMode) {
                        ForEach(RenderModeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Row 1: Radius, Levels, Smoothing
                HStack(spacing: 12) {
                    LabeledContent("Radius: \(Int(radius / 1000))km") {
                        Slider(value: $radius, in: 50_000...300_000, step: 10_000)
                    }

                    LabeledContent("Levels: \(Int(contourLevels))") {
                        Slider(value: $contourLevels, in: 3...20, step: 1)
                    }

                    LabeledContent("Smoothing:") {
                        Picker("Smoothing", selection: $selectedSmoother) {
                            ForEach(SmootherOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Row 2: Spacing, Gradient
                HStack(spacing: 12) {
                    LabeledContent("Spacing:") {
                        Picker("Spacing", selection: $selectedSpacing) {
                            ForEach(SpacingOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    LabeledContent("Gradient:") {
                        Picker("Gradient", selection: $selectedGradient) {
                            ForEach(GradientOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Row 3: Stroke, Opacity
                HStack(spacing: 12) {
                    LabeledContent("Stroke:") {
                        Picker("Stroke", selection: $selectedStroke) {
                            ForEach(StrokeOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    LabeledContent("Opacity: \(Int(fillOpacity * 100))%") {
                        Slider(value: $fillOpacity, in: 0...1, step: 0.05)
                    }
                }

                if selectedRenderMode != .filled {
                    LabeledContent("Line Color:") {
                        Picker("Line Color", selection: $selectedIsolineColor) {
                            ForEach(IsolineColorOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }

            Divider()

            // MARK: Legend
            VStack(spacing: 8) {
                Text("Legend")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                LabeledContent("Orientation:") {
                    Picker("Orientation", selection: $legendAxis) {
                        Text("Vertical").tag(Axis.vertical)
                        Text("Horizontal").tag(Axis.horizontal)
                    }
                    .pickerStyle(.segmented)
                }

                LabeledContent("Labels:") {
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

#Preview {
    @Previewable @State var radius: Double = 150_000
    @Previewable @State var contourLevels: Double = 10
    @Previewable @State var selectedGradient: GradientOption = .thermal
    @Previewable @State var fillOpacity: Double = 1.0
    @Previewable @State var selectedStroke: StrokeOption = .none
    @Previewable @State var selectedRenderMode: RenderModeOption = .filled
    @Previewable @State var selectedIsolineColor: IsolineColorOption = .gradient
    @Previewable @State var selectedSpacing: SpacingOption = .linear
    @Previewable @State var selectedSmoother: SmootherOption = .chaikin2
    @Previewable @State var legendAxis: Axis = .vertical
    @Previewable @State var legendLabels: HeatMapLegend.LabelVisibility = .thresholds
    @Previewable @State var showControls = true

    ControlPanel(
        radius: $radius,
        contourLevels: $contourLevels,
        selectedGradient: $selectedGradient,
        fillOpacity: $fillOpacity,
        selectedStroke: $selectedStroke,
        selectedRenderMode: $selectedRenderMode,
        selectedIsolineColor: $selectedIsolineColor,
        selectedSpacing: $selectedSpacing,
        selectedSmoother: $selectedSmoother,
        legendAxis: $legendAxis,
        legendLabels: $legendLabels,
        showControls: $showControls
    )
    .padding()
}
