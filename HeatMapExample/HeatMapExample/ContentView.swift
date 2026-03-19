//
//  ContentView.swift
//  HeatMapExample
//
//  Created by Tom Hoag on 3/16/26.
//

import HeatMap
import MapKit
import SwiftUI

struct ContentView: View {
    @State private var position: MapCameraPosition = .automatic

    @State private var points: [HeatMapPoint] = []
    @State private var contours: HeatMapContours?
    @State private var valueMin: Double = 0
    @State private var valueMax: Double = 1
    @State private var radius: Double = 500
    @State private var contourLevels: Double = 10
    @State private var selectedGradient: GradientOption = .thermal
    @State private var fillOpacity: Double = 0.8
    @State private var selectedRenderMode: RenderModeOption = .filled
    @State private var selectedIsolineColor: IsolineColorOption = .gradient
    @State private var isolineWidth: Double = 1
    @State private var selectedSpacing: SpacingOption = .auto
    @State private var selectedSmoother: SmootherOption = .chaikin2
    @State private var legendAxis: Axis = .vertical
    @State private var legendLabels: HeatMapLegend.LabelVisibility = .thresholds
    @State private var selectedDataset: DatasetOption = .texasFreeze
    @State private var showControls = false
    @State private var tapInfo: TapInfo?
    @Namespace private var namespace
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Hide the legend when isolines use a uniform color — all lines
    /// look identical so a gradient bar adds no information.
    private var showLegend: Bool {
        switch selectedRenderMode {
        case .isolines:
            return selectedIsolineColor == .gradient
        case .filled, .both:
            return true
        }
    }

    private var resolvedLegendLabels: HeatMapLegend.LabelVisibility {
        switch legendLabels {
        case .thresholds:
            return .customLowHigh(
                low: String(format: "%.1f°", valueMin),
                high: String(format: "%.1f°", valueMax)
            )
        default:
            return legendLabels
        }
    }

    private var configuration: HeatMapConfiguration {
        HeatMapConfiguration(
            radius: radius,
            contourLevels: Int(contourLevels),
            levelSpacing: selectedSpacing.spacing, gridResolution: 120,
            gradient: selectedGradient.gradient,
            fillOpacity: fillOpacity,
            renderMode: selectedRenderMode.renderMode(lineWidth: CGFloat(isolineWidth), color: selectedIsolineColor.color),
            smoother: selectedSmoother.smoother
        )
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let contours {
                    HeatMapLayer(contours: contours)
                }
            }
            .onTapGesture { screenPoint in
                guard let coordinate = proxy.convert(screenPoint, from: .local),
                      let contours else {
                    tapInfo = nil
                    return
                }
                let hit = contours.contours(containing: coordinate)
                if let innermost = hit.last {
                    tapInfo = TapInfo(
                        coordinate: coordinate,
                        screenPoint: screenPoint,
                        level: innermost.level,
                        threshold: innermost.threshold,
                        totalLevels: contours.levelCount
                    )
                } else {
                    tapInfo = nil
                }
            }
            .mapStyle(
                .hybrid(
                    elevation: .automatic,
                    pointsOfInterest: .excludingAll,
                    showsTraffic: false
                )
            )
            .task(id: selectedDataset) {
                loadPoints(selectedDataset)
                tapInfo = nil
                contours = try? await HeatMapContours.compute(
                    from: points,
                    configuration: configuration
                )
            }
            .task(id: configuration) {
                guard !points.isEmpty else { return }
                tapInfo = nil
                contours = try? await HeatMapContours.compute(
                    from: points,
                    configuration: configuration
                )
            }
            .overlay {
                if let tapInfo {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level \(tapInfo.level + 1) of \(tapInfo.totalLevels)")
                            .font(.headline)
                        Text("Threshold: \(tapInfo.threshold, specifier: "%.2f")")
                            .font(.subheadline)
                        Text("\(tapInfo.coordinate.latitude, specifier: "%.4f"), \(tapInfo.coordinate.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .glassEffect(in: .rect(cornerRadius: 12))
                    .fixedSize()
                    .position(x: tapInfo.screenPoint.x, y: tapInfo.screenPoint.y - 60)
                    .onTapGesture {
                        self.tapInfo = nil
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if let contours, showLegend {
                    HeatMapLegend(contours: contours)
                        .axis(legendAxis)
                        .labels(resolvedLegendLabels)
                        .padding(12)
                        .glassEffect(in: .rect(cornerRadius: 12))
                        .padding()
                }
            }
            .overlay(alignment: sizeClass == .compact ? .bottom : .bottomTrailing) {
                GlassEffectContainer {
                    VStack(alignment: .trailing) {
                        if !showControls {
                            Button("Controls", systemImage: "slider.horizontal.3") {
                                withAnimation(.smooth) {
                                    showControls = true
                                }
                            }
                            .buttonStyle(.glass)
                            .glassEffectID("controls", in: namespace)
                        } else {
                            ControlPanel(
                                selectedDataset: $selectedDataset,
                                radius: $radius,
                                contourLevels: $contourLevels,
                                selectedGradient: $selectedGradient,
                                fillOpacity: $fillOpacity,
                                selectedRenderMode: $selectedRenderMode,
                                selectedIsolineColor: $selectedIsolineColor,
                                isolineWidth: $isolineWidth,
                                selectedSpacing: $selectedSpacing,
                                selectedSmoother: $selectedSmoother,
                                legendAxis: $legendAxis,
                                legendLabels: $legendLabels,
                                showControls: $showControls
                            )
                            .glassEffectID("controls", in: namespace)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func loadPoints(_ dataset: DatasetOption) {
        guard let url = Bundle.main.url(forResource: dataset.resourceName, withExtension: "json"),
              let result = try? GSODLoader.load(from: url),
              !result.points.isEmpty else { return }
        points = result.points
        valueMin = result.valueMin
        valueMax = result.valueMax

//        let adaptive = HeatMapConfiguration.adaptive(for: result.points)
//        radius = adaptive.radius
        radius = 300_000

        let lats = result.points.map(\.coordinate.latitude)
        let lons = result.points.map(\.coordinate.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (lats.max()! - lats.min()!) * 1.1,
            longitudeDelta: (lons.max()! - lons.min()!) * 1.1
        )
        position = .region(MKCoordinateRegion(center: center, span: span))
    }
}

private struct TapInfo {
    let coordinate: CLLocationCoordinate2D
    let screenPoint: CGPoint
    let level: Int
    let threshold: Double
    let totalLevels: Int
}

#Preview {
    ContentView()
}
