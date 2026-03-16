//
//  HeatMapLayer.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import MapKit
import SwiftUI

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
/// For large datasets, pre-compute contours asynchronously using
/// ``HeatMapContours/compute(from:configuration:)-swift.type.method``
/// and pass the result to ``init(contours:)``.
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
        self.init(contours: HeatMapContours.compute(from: points, configuration: configuration))
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
        self.gradient = contours._gradient
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
