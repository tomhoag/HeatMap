//
//  HeatMapPolygon+Contains.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import CoreLocation

extension HeatMapPolygon {
    /// Returns whether the given coordinate lies inside this polygon's
    /// annular region.
    ///
    /// A coordinate is considered inside if it lies within the outer ring
    /// and does not lie inside any interior polygon (hole). This correctly
    /// models annular polygons where the next-higher contour level is
    /// punched out.
    ///
    /// Uses the ray-casting (even-odd) algorithm: a horizontal ray is cast
    /// from the test point to the right, and the number of polygon edge
    /// crossings is counted. An odd count means the point is inside.
    ///
    /// The polygon is implicitly closed — the last vertex connects back to
    /// the first. Polygons with fewer than three coordinates always return
    /// `false`.
    ///
    /// - Parameter coordinate: The geographic coordinate to test.
    /// - Returns: `true` if the coordinate is inside the polygon's
    ///   annular region (inside the outer ring but not inside any hole).
    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard Self.rayCast(coordinate: coordinate, in: coordinates) else {
            return false
        }
        for hole in interiorPolygons {
            if Self.rayCast(coordinate: coordinate, in: hole) {
                return false
            }
        }
        return true
    }

    /// Ray-casting (even-odd) point-in-polygon test on a coordinate ring.
    ///
    /// - Parameters:
    ///   - coordinate: The point to test.
    ///   - ring: The polygon ring vertices (must have at least 3).
    /// - Returns: `true` if the point is inside the ring.
    private static func rayCast(
        coordinate: CLLocationCoordinate2D,
        in ring: [CLLocationCoordinate2D]
    ) -> Bool {
        guard ring.count >= 3 else { return false }

        let testLat = coordinate.latitude
        let testLon = coordinate.longitude
        var inside = false

        var j = ring.count - 1
        for i in 0..<ring.count {
            let yi = ring[i].latitude
            let xi = ring[i].longitude
            let yj = ring[j].latitude
            let xj = ring[j].longitude

            if ((yi > testLat) != (yj > testLat)) &&
                (testLon < (xj - xi) * (testLat - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }

        return inside
    }
}
