//
//  ControlPanel.swift
//  HeatMapExample
//
//  Created by Tom Hoag on 3/16/26.
//

import HeatMap
import SwiftUI

struct ControlPanel: View {
    @Binding var selectedDataset: DatasetOption
    @Binding var radius: Double
    @Binding var contourLevels: Double
    @Binding var selectedGradient: GradientOption
    @Binding var fillOpacity: Double
    @Binding var selectedRenderMode: RenderModeOption
    @Binding var selectedIsolineColor: IsolineColorOption
    @Binding var selectedSpacing: SpacingOption
    @Binding var selectedSmoother: SmootherOption
    @Binding var legendAxis: Axis
    @Binding var legendLabels: HeatMapLegend.LabelVisibility
    @Binding var showControls: Bool

    @State private var selectedLabelVisibility: LabelVisibilityOption = .thresholds
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isCompact: Bool { sizeClass == .compact }

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

            if isCompact {
                ScrollView {
                    compactContent
                }
                .scrollIndicators(.hidden)
            } else {
                regularContent
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
        .frame(maxHeight: isCompact ? 400 : nil)
    }

    // MARK: - Compact Layout (iPhone)

    private var compactContent: some View {
        VStack(spacing: 12) {
            // Heat Map section
            Text("Heat Map")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            menuRow("Dataset") {
                Picker("Dataset", selection: $selectedDataset) {
                    ForEach(DatasetOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            menuRow("Render") {
                Picker("Render", selection: $selectedRenderMode) {
                    ForEach(RenderModeOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            LabeledContent("Radius: \(Int(radius / 1000))km") {
                Slider(value: $radius, in: 50_000...300_000, step: 10_000)
            }

            LabeledContent("Levels: \(Int(contourLevels))") {
                Slider(value: $contourLevels, in: 3...20, step: 1)
            }

            menuRow("Smoothing") {
                Picker("Smoothing", selection: $selectedSmoother) {
                    ForEach(SmootherOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            menuRow("Spacing") {
                Picker("Spacing", selection: $selectedSpacing) {
                    ForEach(SpacingOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            menuRow("Gradient") {
                Picker("Gradient", selection: $selectedGradient) {
                    ForEach(GradientOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            LabeledContent("Opacity: \(Int(fillOpacity * 100))%") {
                Slider(value: $fillOpacity, in: 0...1, step: 0.05)
            }

            if selectedRenderMode != .filled {
                menuRow("Line Color") {
                    Picker("Line Color", selection: $selectedIsolineColor) {
                        ForEach(IsolineColorOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }

            Divider()

            // Legend section
            Text("Legend")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            menuRow("Orientation") {
                Picker("Orientation", selection: $legendAxis) {
                    Text("Vertical").tag(Axis.vertical)
                    Text("Horizontal").tag(Axis.horizontal)
                }
            }

            menuRow("Labels") {
                Picker("Labels", selection: $selectedLabelVisibility) {
                    ForEach(LabelVisibilityOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .onChange(of: selectedLabelVisibility) { _, newValue in
                    legendLabels = newValue.visibility
                }
            }
        }
    }

    // MARK: - Regular Layout (iPad)

    private var regularContent: some View {
        VStack(spacing: 8) {
            // MARK: Heat Map
            Text("Heat Map")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                menuRow("Dataset") {
                    Picker("Dataset", selection: $selectedDataset) {
                        ForEach(DatasetOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                menuRow("Render") {
                    Picker("Render", selection: $selectedRenderMode) {
                        ForEach(RenderModeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                LabeledContent("Radius: \(Int(radius / 1000))km") {
                    Slider(value: $radius, in: 50_000...300_000, step: 10_000)
                }

                LabeledContent("Levels: \(Int(contourLevels))") {
                    Slider(value: $contourLevels, in: 3...20, step: 1)
                }

                menuRow("Smoothing") {
                    Picker("Smoothing", selection: $selectedSmoother) {
                        ForEach(SmootherOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                menuRow("Spacing") {
                    Picker("Spacing", selection: $selectedSpacing) {
                        ForEach(SpacingOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                menuRow("Gradient") {
                    Picker("Gradient", selection: $selectedGradient) {
                        ForEach(GradientOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }

            LabeledContent("Opacity: \(Int(fillOpacity * 100))%") {
                Slider(value: $fillOpacity, in: 0...1, step: 0.05)
            }

            if selectedRenderMode != .filled {
                menuRow("Line Color") {
                    Picker("Line Color", selection: $selectedIsolineColor) {
                        ForEach(IsolineColorOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }

            Divider()

            // MARK: Legend
            Text("Legend")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                menuRow("Orientation") {
                    Picker("Orientation", selection: $legendAxis) {
                        Text("Vertical").tag(Axis.vertical)
                        Text("Horizontal").tag(Axis.horizontal)
                    }
                }

                menuRow("Labels") {
                    Picker("Labels", selection: $selectedLabelVisibility) {
                        ForEach(LabelVisibilityOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .onChange(of: selectedLabelVisibility) { _, newValue in
                        legendLabels = newValue.visibility
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func menuRow<P: View>(_ label: String, @ViewBuilder picker: () -> P) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
            picker()
                .pickerStyle(.menu)
        }
    }
}

#Preview {
    @Previewable @State var selectedDataset: DatasetOption = .texasFreeze
    @Previewable @State var radius: Double = 150_000
    @Previewable @State var contourLevels: Double = 10
    @Previewable @State var selectedGradient: GradientOption = .thermal
    @Previewable @State var fillOpacity: Double = 1.0
    @Previewable @State var selectedRenderMode: RenderModeOption = .filled
    @Previewable @State var selectedIsolineColor: IsolineColorOption = .gradient
    @Previewable @State var selectedSpacing: SpacingOption = .linear
    @Previewable @State var selectedSmoother: SmootherOption = .chaikin2
    @Previewable @State var legendAxis: Axis = .vertical
    @Previewable @State var legendLabels: HeatMapLegend.LabelVisibility = .thresholds
    @Previewable @State var showControls = true

    ControlPanel(
        selectedDataset: $selectedDataset,
        radius: $radius,
        contourLevels: $contourLevels,
        selectedGradient: $selectedGradient,
        fillOpacity: $fillOpacity,
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
