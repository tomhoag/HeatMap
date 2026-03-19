//
//  HeatMapPolygon.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation

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
/// let result = try await HeatMapContours.compute(from: points)
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
/// - ``interiorPolygons``
///
/// ### Geometry Queries
///
/// - ``contains(_:)``
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

    /// The interior polygon coordinates (holes) subtracted from this polygon.
    ///
    /// Each element is a closed polygon ring representing a cutout region.
    /// These correspond to the next-higher contour level polygons that are
    /// spatially contained within this polygon's outer ring. The innermost
    /// contour level has no interior polygons.
    ///
    /// When rendered, these holes create annular (ring-shaped) regions that
    /// show only the density band for this contour level, eliminating
    /// opacity stacking artifacts from overlapping polygons.
    public let interiorPolygons: [[CLLocationCoordinate2D]]

    /// Creates a polygon with the given identifier.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for this polygon.
    ///   - level: The zero-based contour level index.
    ///   - threshold: The density threshold value.
    ///   - coordinates: The polygon vertices in geographic coordinates.
    ///   - interiorPolygons: Coordinate arrays for holes to cut out.
    ///     Defaults to an empty array (no holes).
    public init(
        id: UUID,
        level: Int,
        threshold: Double,
        coordinates: [CLLocationCoordinate2D],
        interiorPolygons: [[CLLocationCoordinate2D]] = []
    ) {
        self.id = id
        self.level = level
        self.threshold = threshold
        self.coordinates = coordinates
        self.interiorPolygons = interiorPolygons
    }

    /// Creates a polygon with an auto-generated identifier.
    ///
    /// Used internally by the marching squares algorithm.
    ///
    /// - Parameters:
    ///   - level: The zero-based contour level index.
    ///   - threshold: The density threshold value.
    ///   - coordinates: The polygon vertices in geographic coordinates.
    ///   - interiorPolygons: Coordinate arrays for holes to cut out.
    ///     Defaults to an empty array (no holes).
    init(
        level: Int,
        threshold: Double,
        coordinates: [CLLocationCoordinate2D],
        interiorPolygons: [[CLLocationCoordinate2D]] = []
    ) {
        self.id = UUID()
        self.level = level
        self.threshold = threshold
        self.coordinates = coordinates
        self.interiorPolygons = interiorPolygons
    }
}
