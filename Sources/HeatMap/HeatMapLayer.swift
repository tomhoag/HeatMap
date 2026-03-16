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
/// For large datasets, computing contours on the main actor can block the
/// UI. Use this type to move the work off the main actor:
///
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
///
/// ## Topics
///
/// ### Computing Contours
///
/// - ``compute(from:configuration:)``
public struct HeatMapContours: Sendable {
    /// The extracted contour polygons.
    let polygons: [ContourPolygon]

    /// The number of contour levels used during extraction.
    let levels: Int

    /// The gradient associated with these contours.
    let gradient: HeatMapGradient

    /// Computes contours from the given points and configuration.
    ///
    /// This method builds a ``DensityGrid``, extracts contour polygons via
    /// the marching squares algorithm, and applies the configured polygon
    /// smoother. It is `Sendable`-safe and can be called from any isolation
    /// context.
    ///
    /// - Parameters:
    ///   - points: The weighted geographic data points.
    ///   - configuration: The rendering configuration. Defaults to
    ///     ``HeatMapConfiguration/init(radius:contourLevels:gridResolution:gradient:paddingFactor:smoother:)``.
    /// - Returns: A ``HeatMapContours`` value ready to pass to
    ///   ``HeatMapLayer/init(contours:)``.
    public static func compute<P: HeatMapable>(
        from points: [P],
        configuration: HeatMapConfiguration = HeatMapConfiguration()
    ) -> HeatMapContours {
        let grid = DensityGrid.compute(from: points, configuration: configuration)
        let result = MarchingSquares.extractContours(
            from: grid,
            levels: configuration.contourLevels
        )
        let smoothed = result.polygons.map { polygon in
            ContourPolygon(
                level: polygon.level,
                threshold: polygon.threshold,
                coordinates: configuration.smoother.smooth(polygon.coordinates)
            )
        }
        return HeatMapContours(
            polygons: smoothed,
            levels: configuration.contourLevels,
            gradient: configuration.gradient
        )
    }
}

/// A heat map layer rendered as filled contour polygons inside a SwiftUI `Map`.
///
/// Place this inside a `Map` content builder to visualize geographic density
/// data:
///
/// ```swift
/// Map {
///     HeatMapLayer(points: myPoints)
/// }
/// ```
///
/// Customize the appearance and behavior through ``HeatMapConfiguration``:
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
///
/// For large datasets, pre-compute contours off the main actor using
/// ``HeatMapContours/compute(from:configuration:)`` and pass the result
/// to ``init(contours:)``.
///
/// ## Topics
///
/// ### Creating a Layer
///
/// - ``init(points:configuration:)``
/// - ``init(contours:)``
///
/// ### Pre-computing Contours
///
/// - ``HeatMapContours``
public struct HeatMapLayer: MapContent {
    /// The contour polygons to render.
    private let contours: [ContourPolygon]

    /// The gradient used to color each contour level.
    private let gradient: HeatMapGradient

    /// The total number of contour levels, used for color mapping.
    private let totalLevels: Int

    /// Creates a heat map layer from weighted geographic points.
    ///
    /// The density grid and contour polygons are computed synchronously.
    /// For large datasets, use ``HeatMapContours/compute(from:configuration:)``
    /// to pre-compute off the main actor.
    ///
    /// - Parameters:
    ///   - points: The weighted geographic points to visualize. Must conform
    ///     to ``HeatMapable``.
    ///   - configuration: The rendering configuration. Defaults to
    ///     ``HeatMapConfiguration/init(radius:contourLevels:gridResolution:gradient:paddingFactor:smoother:)``.
    public init<P: HeatMapable>(
        points: [P],
        configuration: HeatMapConfiguration = HeatMapConfiguration()
    ) {
        let grid = DensityGrid.compute(from: points, configuration: configuration)
        let result = MarchingSquares.extractContours(
            from: grid,
            levels: configuration.contourLevels
        )
        self.contours = result.polygons.map { polygon in
            ContourPolygon(
                level: polygon.level,
                threshold: polygon.threshold,
                coordinates: configuration.smoother.smooth(polygon.coordinates)
            )
        }
        self.gradient = configuration.gradient
        self.totalLevels = configuration.contourLevels
    }

    /// Creates a heat map layer from pre-computed contours.
    ///
    /// Use this initializer with the output of
    /// ``HeatMapContours/compute(from:configuration:)`` to avoid blocking
    /// the main actor.
    ///
    /// - Parameter contours: Pre-computed contour data.
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
    ///
    /// - Parameter level: The zero-based contour level index.
    /// - Returns: The interpolated color for the given level.
    private func colorForLevel(_ level: Int) -> Color {
        guard totalLevels > 1 else {
            return gradient.colors.first ?? .clear
        }
        let fraction = Double(level) / Double(totalLevels - 1)
        return gradient.color(for: fraction)
    }
}
