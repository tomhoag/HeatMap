//
//  HeatMapLayer.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import MapKit
import SwiftUI

/// Pre-computed contour data for use with ``HeatMapLayer``.
///
/// Use this type to compute contours off the main actor for large datasets:
/// ```swift
/// @State private var contours: HeatMapContours?
///
/// Map {
///     if let contours {
///         HeatMapLayer(contours: contours)
///     }
/// }
/// .task {
///     contours = HeatMapContours.compute(from: largePointArray)
/// }
/// ```
public struct HeatMapContours: Sendable {
    let polygons: [ContourPolygon]
    let levels: Int
    let gradient: HeatMapGradient

    /// Computes contours from the given points and configuration.
    ///
    /// This method is safe to call from any actor context.
    public static func compute(
        from points: [HeatMapPoint],
        configuration: HeatMapConfiguration = HeatMapConfiguration()
    ) -> HeatMapContours {
        let grid = DensityGrid.compute(from: points, configuration: configuration)
        let result = MarchingSquares.extractContours(
            from: grid,
            levels: configuration.contourLevels
        )
        return HeatMapContours(
            polygons: result.polygons,
            levels: configuration.contourLevels,
            gradient: configuration.gradient
        )
    }
}

/// A heat map layer rendered as contour polygons inside a SwiftUI ``Map``.
///
/// Place this inside a `Map` content builder to display geographic data
/// as a density visualization:
///
/// ```swift
/// Map {
///     HeatMapLayer(points: myPoints)
/// }
/// ```
///
/// Customize the appearance with a configuration:
///
/// ```swift
/// Map {
///     HeatMapLayer(
///         points: myPoints,
///         configuration: HeatMapConfiguration(
///             radius: 300,
///             contourLevels: 12,
///             gradient: .thermal
///         )
///     )
/// }
/// ```
public struct HeatMapLayer: MapContent {
    private let contours: [ContourPolygon]
    private let gradient: HeatMapGradient
    private let totalLevels: Int

    /// Creates a heat map layer from weighted geographic points.
    ///
    /// The density grid and contour polygons are computed synchronously.
    /// For large datasets, use ``HeatMapContours/compute(from:configuration:)``
    /// to pre-compute off the main actor.
    ///
    /// - Parameters:
    ///   - points: The weighted geographic points to visualize.
    ///   - configuration: The rendering configuration. Defaults to
    ///     ``HeatMapConfiguration/init(radius:contourLevels:gridResolution:gradient:paddingFactor:)``.
    public init(
        points: [HeatMapPoint],
        configuration: HeatMapConfiguration = HeatMapConfiguration()
    ) {
        let grid = DensityGrid.compute(from: points, configuration: configuration)
        let result = MarchingSquares.extractContours(
            from: grid,
            levels: configuration.contourLevels
        )
        self.contours = result.polygons
        self.gradient = configuration.gradient
        self.totalLevels = configuration.contourLevels
    }

    /// Creates a heat map layer from pre-computed contours.
    ///
    /// - Parameter contours: Pre-computed contour data from
    ///   ``HeatMapContours/compute(from:configuration:)``.
    public init(contours: HeatMapContours) {
        self.contours = contours.polygons
        self.gradient = contours.gradient
        self.totalLevels = contours.levels
    }

    @MainActor
    public var body: some MapContent {
        ForEach(contours) { polygon in
            MapPolygon(coordinates: polygon.coordinates)
                .foregroundStyle(colorForLevel(polygon.level))
        }
    }

    /// Maps a contour level index to a color from the gradient.
    private func colorForLevel(_ level: Int) -> Color {
        guard totalLevels > 1, !gradient.colors.isEmpty else {
            return gradient.colors.first ?? .clear
        }
        let fraction = Double(level) / Double(totalLevels - 1)
        let scaledIndex = fraction * Double(gradient.colors.count - 1)
        let index = min(Int(scaledIndex), gradient.colors.count - 1)
        return gradient.colors[index]
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.775, longitude: -122.418),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )

    Map(position: $position) {
        HeatMapLayer(
            points: HeatMapLayer.samplePoints,
            configuration: HeatMapConfiguration(
                radius: 300,
                contourLevels: 8,
                gradient: .thermal
            )
        )
    }
}

private extension HeatMapLayer {
    /// Sample points around San Francisco for previewing.
    static let samplePoints: [HeatMapPoint] = [
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), weight: 10),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4180), weight: 8),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7735, longitude: -122.4210), weight: 6),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4165), weight: 9),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7740, longitude: -122.4150), weight: 4),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7770, longitude: -122.4200), weight: 7),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7725, longitude: -122.4175), weight: 5),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4140), weight: 3),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7780, longitude: -122.4185), weight: 8),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7710, longitude: -122.4160), weight: 6),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7765, longitude: -122.4220), weight: 4),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7745, longitude: -122.4130), weight: 7),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7790, longitude: -122.4170), weight: 5),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7730, longitude: -122.4205), weight: 9),
        HeatMapPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7720, longitude: -122.4190), weight: 6),
    ]
}
