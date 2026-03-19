//
//  AnnularAssembly.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/19/26.
//

import CoreLocation

/// Assembles flat contour polygons into annular (ring-shaped) polygons
/// by assigning each polygon its spatially contained next-level polygons
/// as interior holes.
///
/// After marching squares extracts contour polygons and smoothing is
/// applied, this post-processing step pairs each polygon at level N with
/// the level N+1 polygons that lie within it. The result is a set of
/// non-overlapping annular polygons that can be rendered with
/// `MKPolygon(coordinates:count:interiorPolygons:)` to eliminate opacity
/// stacking artifacts.
enum AnnularAssembly {

    /// Converts a flat array of contour polygons into annular polygons.
    ///
    /// For each polygon at level N, finds all polygons at level N+1 whose
    /// first vertex is contained within the level N polygon, and assigns
    /// them as interior holes. The innermost level (highest level index)
    /// has no holes.
    ///
    /// This method checks for `Task` cancellation between levels. When
    /// called outside of a `Task` context, the cancellation checks are
    /// a no-op.
    ///
    /// - Parameter polygons: Flat contour polygons sorted by level
    ///   (ascending).
    /// - Returns: Polygons with ``HeatMapPolygon/interiorPolygons``
    ///   populated.
    /// - Throws: `CancellationError` if the current task is cancelled.
    static func assembleAnnular(
        _ polygons: [HeatMapPolygon]
    ) throws -> [HeatMapPolygon] {
        guard !polygons.isEmpty else { return [] }

        let grouped = Dictionary(grouping: polygons, by: \.level)
        let sortedLevels = grouped.keys.sorted()

        var result: [HeatMapPolygon] = []
        result.reserveCapacity(polygons.count)

        for (levelIndex, level) in sortedLevels.enumerated() {
            try Task.checkCancellation()

            let outerPolygons = grouped[level]!

            guard levelIndex < sortedLevels.count - 1 else {
                result.append(contentsOf: outerPolygons)
                continue
            }

            let nextLevel = sortedLevels[levelIndex + 1]
            let innerCandidates = grouped[nextLevel]!

            for outer in outerPolygons {
                let holes = findInteriorPolygons(
                    outer: outer,
                    candidates: innerCandidates
                )
                result.append(HeatMapPolygon(
                    id: outer.id,
                    level: outer.level,
                    threshold: outer.threshold,
                    coordinates: outer.coordinates,
                    interiorPolygons: holes
                ))
            }
        }

        return result
    }

    // MARK: - Private

    /// Finds which candidate polygons are spatially inside the outer
    /// polygon.
    ///
    /// Tests the first vertex of each candidate against the outer
    /// polygon's boundary. This is sufficient for contour polygons
    /// from the same density field because they are properly nested
    /// (never partially overlapping).
    ///
    /// - Parameters:
    ///   - outer: The outer polygon to test against.
    ///   - candidates: The next-level polygons to check.
    /// - Returns: Coordinate arrays of candidates that lie inside the
    ///   outer polygon.
    private static func findInteriorPolygons(
        outer: HeatMapPolygon,
        candidates: [HeatMapPolygon]
    ) -> [[CLLocationCoordinate2D]] {
        var holes: [[CLLocationCoordinate2D]] = []
        for inner in candidates {
            guard let firstVertex = inner.coordinates.first else { continue }
            if outer.contains(firstVertex) {
                holes.append(inner.coordinates)
            }
        }
        return holes
    }
}
