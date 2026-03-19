//
//  HeatMapContours.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation

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
///         HeatMapLayer(contours: contours, style: style)
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
/// - ``thresholds``
///
/// ### Hit Testing
///
/// - ``contours(containing:)``
///
/// ### Contour Data
///
/// - ``HeatMapPolygon``
public struct HeatMapContours: Sendable, Equatable {
    /// Two contour results are equal when they have the same level count
    /// and polygon identities (in order).
    public static func == (lhs: HeatMapContours, rhs: HeatMapContours) -> Bool {
        lhs.levels == rhs.levels
            && lhs.polygons.count == rhs.polygons.count
            && zip(lhs.polygons, rhs.polygons).allSatisfy { $0.id == $1.id }
    }

    /// The extracted contour polygons.
    let polygons: [HeatMapPolygon]

    /// The number of contour levels used during extraction.
    let levels: Int

    /// The density threshold values used during contour extraction.
    let thresholdValues: [Double]

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

    /// The density threshold values used during contour extraction.
    ///
    /// Each value corresponds to the boundary between two contour levels.
    /// The array is sorted ascending and has ``levelCount`` elements.
    public var thresholds: [Double] { thresholdValues }

    /// Synchronously computes contours from the given points and configuration.
    ///
    /// This method builds a ``DensityGrid``, extracts contour polygons via
    /// the marching squares algorithm, and applies the configured polygon
    /// smoother. It is `Sendable`-safe and can be called from any isolation
    /// context.
    ///
    /// This overload runs synchronously. The internal pipeline includes
    /// `Task.checkCancellation()` calls, but outside of a `Task` context
    /// those checks are no-ops and the method cannot throw.
    ///
    /// - Parameters:
    ///   - points: The weighted geographic data points.
    ///   - configuration: The computation configuration.
    /// - Returns: A ``HeatMapContours`` value ready to pass to
    ///   ``HeatMapLayer/init(contours:style:)``.
    public static func compute<P: HeatMapable>(
        from points: [P],
        configuration: HeatMapConfiguration = HeatMapConfiguration()
    ) -> HeatMapContours {
        // Outside a Task context, Task.checkCancellation() never throws.
        // swiftlint:disable:next force_try
        try! computeCore(from: points, configuration: configuration)
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
    ///   - configuration: The computation configuration.
    /// - Returns: A ``HeatMapContours`` value ready to pass to
    ///   ``HeatMapLayer/init(contours:style:)``.
    /// - Throws: `CancellationError` if the Task is cancelled during computation.
    public static func compute<P: HeatMapable>(
        from points: [P],
        configuration: HeatMapConfiguration = HeatMapConfiguration()
    ) async throws -> HeatMapContours {
        let points = Array(points)
        let configuration = configuration
        return try await Task.detached {
            try computeCore(from: points, configuration: configuration)
        }.value
    }

    // MARK: - Private

    /// Shared implementation for both the synchronous and async compute
    /// entry points.
    ///
    /// Each stage checks for `Task` cancellation at natural boundaries.
    /// When called outside of a `Task` context (i.e. from the synchronous
    /// overload), those checks are no-ops.
    private static func computeCore<P: HeatMapable>(
        from points: [P],
        configuration: HeatMapConfiguration
    ) throws -> HeatMapContours {
        // 1. Density grid (checks cancellation internally between points)
        let grid = try DensityGrid.compute(from: points, configuration: configuration)

        // 2. Resolve thresholds
        let thresholds = configuration.levelSpacing.resolveThresholds(
            levels: configuration.contourLevels,
            minDensity: grid.minDensity,
            maxDensity: grid.maxDensity,
            densityValues: grid.values
        )

        // 3. Contour extraction (checks between each level internally)
        let result = try MarchingSquares.extractContours(
            from: grid,
            thresholds: thresholds
        )

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
        let annular = try AnnularAssembly.assembleAnnular(smoothed)

        return HeatMapContours(
            polygons: annular,
            levels: thresholds.count,
            thresholdValues: thresholds
        )
    }
}
