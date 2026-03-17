//
//  HeatMapContours.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation
import SwiftUI

/// A single contour polygon representing an iso-density region.
///
/// Each contour has a ``level`` index (0 = lowest density), a density
/// ``threshold``, and an array of geographic ``coordinates`` forming
/// a closed polygon.
///
/// You don't create `HeatMapPolygon` values directly. Instead, access
/// them through ``HeatMapContours/contours`` after computing contours:
///
/// ```swift
/// let result = await HeatMapContours.compute(from: points)
/// for contour in result.contours {
///     print("Level \(contour.level): \(contour.coordinates.count) vertices")
/// }
/// ```
///
/// The contour geometry is useful for advanced use cases such as hit
/// testing, exporting polygon data, or building custom visualizations
/// outside of ``HeatMapLayer``.
///
/// ## Topics
///
/// ### Identifying the Contour
///
/// - ``id``
/// - ``level``
/// - ``threshold``
///
/// ### Accessing Geometry
///
/// - ``coordinates``
public struct HeatMapPolygon: Sendable, Identifiable, Equatable {
    /// Two contours are equal when they share the same ``id``.
    public static func == (lhs: HeatMapPolygon, rhs: HeatMapPolygon) -> Bool {
        lhs.id == rhs.id
    }

    /// A unique identifier for this contour polygon.
    public let id: UUID

    /// The contour level index, starting at 0 for the lowest density.
    ///
    /// Multiple contour polygons may share the same level when the density
    /// field has disconnected regions at a given threshold.
    public let level: Int

    /// The density threshold for this contour.
    ///
    /// Points inside this polygon have a density value at or above this
    /// threshold.
    public let threshold: Double

    /// The closed polygon vertices as geographic coordinates.
    ///
    /// The polygon is implicitly closed — the last vertex connects back
    /// to the first without a duplicate closing point. The coordinates
    /// have already been smoothed by the configured ``PolygonSmoother``.
    public let coordinates: [CLLocationCoordinate2D]
}

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
///     contours = await HeatMapContours.compute(from: largePointArray)
/// }
/// ```
///
/// ### Inspecting Contour Geometry
///
/// Beyond rendering, you can inspect the computed contours for hit testing,
/// data export, or building custom visualizations:
///
/// ```swift
/// let result = await HeatMapContours.compute(from: points)
/// print("\(result.contourCount) polygons across \(result.levelCount) levels")
///
/// for contour in result.contours {
///     // Access level, threshold, and geographic coordinates
///     print("Level \(contour.level): \(contour.coordinates.count) vertices")
/// }
/// ```
///
/// ## Topics
///
/// ### Computing Contours
///
/// - ``compute(from:configuration:)-swift.type.method``
///
/// ### Inspecting Results
///
/// - ``contours``
/// - ``contourCount``
/// - ``levelCount``
/// - ``gradient``
///
/// ### Contour Data
///
/// - ``HeatMapPolygon``
public struct HeatMapContours: Sendable, Equatable {
    /// Two contour results are equal when they have the same level count,
    /// gradient, and polygon identities (in order).
    public static func == (lhs: HeatMapContours, rhs: HeatMapContours) -> Bool {
        lhs.levels == rhs.levels
            && lhs._gradient == rhs._gradient
            && lhs.polygons.count == rhs.polygons.count
            && zip(lhs.polygons, rhs.polygons).allSatisfy { $0.id == $1.id }
    }

    /// The extracted contour polygons (internal representation).
    let polygons: [ContourPolygon]

    /// The number of contour levels used during extraction.
    let levels: Int

    /// The gradient used during computation (internal storage).
    let _gradient: HeatMapGradient

    /// The contour polygons as ``HeatMapPolygon`` values.
    ///
    /// Polygons are ordered from lowest level (outermost) to highest
    /// (innermost). Multiple polygons may share the same level if the
    /// density field has disconnected regions at that threshold.
    ///
    /// Use this property to access the underlying contour geometry for
    /// hit testing, exporting polygon data, or building custom
    /// visualizations outside of ``HeatMapLayer``.
    public var contours: [HeatMapPolygon] {
        polygons.map { polygon in
            HeatMapPolygon(
                id: polygon.id,
                level: polygon.level,
                threshold: polygon.threshold,
                coordinates: polygon.coordinates
            )
        }
    }

    /// The total number of contour polygons across all levels.
    ///
    /// This may be greater than ``levelCount`` when the density field
    /// has disconnected regions that produce multiple polygons at the
    /// same level.
    public var contourCount: Int { polygons.count }

    /// The number of contour levels used during extraction.
    ///
    /// This matches the ``HeatMapConfiguration/contourLevels`` value
    /// that was used to compute these contours.
    public var levelCount: Int { levels }

    /// The color gradient associated with these contours.
    ///
    /// This is the ``HeatMapGradient`` that was specified in the
    /// ``HeatMapConfiguration`` used during computation. It is also
    /// used by ``HeatMapLayer/init(contours:)`` to color the rendered
    /// polygons.
    public var gradient: HeatMapGradient { _gradient }

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
            _gradient: configuration.gradient
        )
    }

    /// Asynchronously computes contours from the given points and configuration.
    ///
    /// This method moves the density grid computation, contour extraction,
    /// and polygon smoothing off the calling actor, making it safe to call
    /// from the main actor without blocking the UI.
    ///
    /// ```swift
    /// .task {
    ///     contours = await HeatMapContours.compute(from: largePointArray)
    /// }
    /// ```
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
    ) async -> HeatMapContours {
        let points = Array(points)
        let configuration = configuration
        return await Task.detached {
            compute(from: points, configuration: configuration)
        }.value
    }
}
