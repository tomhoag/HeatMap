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
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8, longitude: -98.5),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
    )

    @State private var points: [HeatMapPoint] = []
    @State private var radius: Double = 150_000
    @State private var contourLevels: Double = 10
    @State private var selectedGradient: GradientOption = .thermal
    @State private var selectedSmoother: SmootherOption = .chaikin2
    @State private var showControls = false
    @Namespace private var namespace

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

        var smoother: AnyPolygonSmoother {
            switch self {
            case .none: .none
            case .chaikin1: .chaikin(iterations: 1)
            case .chaikin2: .chaikin(iterations: 2)
            case .chaikin3: .chaikin(iterations: 3)
            }
        }
    }

    var body: some View {
        Map(position: $position) {
            if !points.isEmpty {
                HeatMapLayer(
                    points: points,
                    configuration: HeatMapConfiguration(
                        radius: radius,
                        contourLevels: Int(contourLevels),
                        gridResolution: 120,
                        gradient: selectedGradient.gradient,
                        smoother: selectedSmoother.smoother
                    )
                )
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .task {
            loadPoints()
        }
        .overlay(alignment: .bottomTrailing) {
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
                        controlPanel
                            .glassEffectID("controls", in: namespace)
                    }
                }
            }
            .padding()
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
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
        }
        .padding()
        .background {
            Color.clear
                .glassEffect(in: .rect(cornerRadius: 16))
        }
    }

    private func loadPoints() {
        guard let url = Bundle.main.url(forResource: "heatmap_points", withExtension: "json"),
              let loaded = try? GSODLoader.load(from: url) else { return }
        points = loaded
    }

    /// Sample points scattered around San Francisco.
    static let samplePoints: [HeatMapPoint] = [
        // Financial District cluster
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), weight: 10),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4180), weight: 8),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4170), weight: 9),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7745, longitude: -122.4200), weight: 7),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7742, longitude: -122.4188), weight: 6),

        // North Beach cluster
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7800, longitude: -122.4100), weight: 8),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7805, longitude: -122.4110), weight: 7),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7795, longitude: -122.4095), weight: 5),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7810, longitude: -122.4105), weight: 6),

        // Mission cluster
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7690, longitude: -122.4220), weight: 6),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7685, longitude: -122.4230), weight: 5),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7695, longitude: -122.4215), weight: 4),

        // Scattered points
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7770, longitude: -122.4160), weight: 3),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7730, longitude: -122.4250), weight: 4),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7820, longitude: -122.4080), weight: 2),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7710, longitude: -122.4150), weight: 5),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4130), weight: 3),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7735, longitude: -122.4210), weight: 6),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7780, longitude: -122.4185), weight: 4),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7725, longitude: -122.4175), weight: 7),
    ]
}

#Preview {
    ContentView()
}
