//
//  ContentView.swift
//  SimpleHeatMapExample
//
//  Created by Tom Hoag on 3/18/26.
//

import CoreLocation
import HeatMap
import MapKit
import SwiftUI

/// A weighted geographic point for heat map rendering.
struct HeatMapPoint: HeatMapable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let weight: Double
}

struct ContentView: View {
    @State private var contours: HeatMapContours?

    /// Sample points scattered around San Francisco.
    private let points: [HeatMapPoint] = [
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
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7725, longitude: -122.4175), weight: 7)
    ]

    var body: some View {
        Map {
            if let contours {
                HeatMapLayer(contours: contours)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .task {
            let config = HeatMapConfiguration.adaptive(for: points)
            contours = try? await HeatMapContours.compute(
                from: points,
                configuration: config
            )
        }
    }
}

#Preview {
    ContentView()
}
