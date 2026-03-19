//
//  HeatMapContours.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation
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
///     contours = try? await HeatMapContours.compute(from: largePointArray)
/// }
/// ```
///
/// ### Inspecting Contour Geometry
///
/// Beyond rendering, you can inspect the computed contours for hit testing,
/// data export, or building custom visualizations:
///
/// ```swift
/// let result = try await HeatMapContours.compute(from: points)
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
/// - ``fillOpacity``
/// - ``renderMode``
///
/// ### Hit Testing
///
/// - ``contours(containing:)``
///
/// ### Contour Data
///
/// - ``HeatMapPolygon``
public struct HeatMapContours: Sendable, Equatable {
    /// Two contour results are equal when they have the same level count,
    /// gradient, fill opacity, render mode, and polygon identities
    /// (in order).
    public static func == (lhs: HeatMapContours, rhs: HeatMapContours) -> Bool {
        lhs.levels == rhs.levels
            && lhs.configuration.gradient == rhs.configuration.gradient
            && lhs.configuration.fillOpacity == rhs.configuration.fillOpacity
            && lhs.configuration.renderMode == rhs.configuration.renderMode
            && lhs.polygons.count == rhs.polygons.count
            && zip(lhs.polygons, rhs.polygons).allSatisfy { $0.id == $1.id }
    }

    /// The extracted contour polygons.
    let polygons: [HeatMapPolygon]

    /// The number of contour levels used during extraction.
    let levels: Int

    /// The configuration used during computation.
    let configuration: HeatMapConfiguration

    /// The contour polygons as ``HeatMapPolygon`` values.
    ///
    /// Polygons are ordered from lowest level (outermost) to highest
    /// (innermost). Multiple polygons may share the same level if the
    /// density field has disconnected regions at that threshold.
    ///
    /// Use this property to access the underlying contour geometry for
    /// hit testing, exporting polygon data, or building custom
    /// visualizations outside of ``HeatMapLayer``.
    public var contours: [HeatMapPolygon] { polygons }

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
    public var gradient: HeatMapGradient { configuration.gradient }

    /// The fill opacity associated with these contours.
    ///
    /// This is the ``HeatMapConfiguration/fillOpacity`` value that was
    /// specified in the configuration used during computation. It is used
    /// by ``HeatMapLayer/init(contours:)`` to set the opacity of rendered
    /// polygons.
    public var fillOpacity: Double { configuration.fillOpacity }

    /// The render mode associated with these contours.
    ///
    /// This is the ``HeatMapConfiguration/renderMode`` value that was
    /// specified in the configuration used during computation. It is used
    /// by ``HeatMapLayer/init(contours:)`` to determine how contours
    /// are rendered (filled polygons, isolines, or both).
    public var renderMode: HeatMapRenderMode { configuration.renderMode }

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
        let thresholds = configuration.levelSpacing.resolveThresholds(
            levels: configuration.contourLevels,
            minDensity: grid.minDensity,
            maxDensity: grid.maxDensity,
            densityValues: grid.values
        )
        let result = MarchingSquares.extractContours(
            from: grid,
            thresholds: thresholds
        )
        let smoothed = result.map { polygon in
            HeatMapPolygon(
                level: polygon.level,
                threshold: polygon.threshold,
                coordinates: configuration.smoother.smooth(polygon.coordinates)
            )
        }
        // 5. Annular assembly — punch out next-level polygons as holes
        let annular = AnnularAssembly.assembleAnnular(smoothed)
        return HeatMapContours(
            polygons: annular,
            levels: thresholds.count,
            configuration: configuration
        )
    }

    /// Asynchronously computes contours from the given points and configuration.
    ///
    /// This method moves the density grid computation, contour extraction,
    /// and polygon smoothing off the calling actor, making it safe to call
    /// from the main actor without blocking the UI.
    ///
    /// The computation checks for Task cancellation at natural checkpoints
    /// (after the density grid, between contour levels, and between polygon
    /// smoothing passes). If the calling Task is cancelled, the method throws
    /// `CancellationError` and returns early.
    ///
    /// ```swift
    /// .task {
    ///     contours = try? await HeatMapContours.compute(from: largePointArray)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - points: The weighted geographic data points.
    ///   - configuration: The rendering configuration. Defaults to
    ///     ``HeatMapConfiguration/init(radius:contourLevels:gridResolution:gradient:paddingFactor:smoother:)``.
    /// - Returns: A ``HeatMapContours`` value ready to pass to
    ///   ``HeatMapLayer/init(contours:)``.
    /// - Throws: `CancellationError` if the Task is cancelled during computation.
    public static func compute<P: HeatMapable>(
        from points: [P],
        configuration: HeatMapConfiguration = HeatMapConfiguration()
    ) async throws -> HeatMapContours {
        let points = Array(points)
        let configuration = configuration
        return try await Task.detached {
            // 1. Density grid
            let grid = DensityGrid.compute(from: points, configuration: configuration)
            try Task.checkCancellation()

            // 2. Resolve thresholds
            let thresholds = configuration.levelSpacing.resolveThresholds(
                levels: configuration.contourLevels,
                minDensity: grid.minDensity,
                maxDensity: grid.maxDensity,
                densityValues: grid.values
            )

            // 3. Contour extraction (checks between each level internally)
            let result = try MarchingSquares.extractContoursCancellable(
                from: grid,
                thresholds: thresholds
            )
            try Task.checkCancellation()

            // 4. Smoothing (check between each polygon)
            let smoothed = try result.map { polygon in
                try Task.checkCancellation()
                return HeatMapPolygon(
                    level: polygon.level,
                    threshold: polygon.threshold,
                    coordinates: configuration.smoother.smooth(polygon.coordinates)
                )
            }

            // 5. Annular assembly — punch out next-level polygons as holes
            try Task.checkCancellation()
            let annular = try AnnularAssembly.assembleAnnularCancellable(smoothed)

            return HeatMapContours(
                polygons: annular,
                levels: thresholds.count,
                configuration: configuration
            )
        }.value
    }
}
