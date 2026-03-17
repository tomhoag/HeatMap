//
//  HeatMapPolygon+Contains.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import CoreLocation

extension HeatMapPolygon {
    /// Returns whether the given coordinate lies inside this polygon.
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
    /// - Returns: `true` if the coordinate is inside the polygon.
    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard coordinates.count >= 3 else { return false }

        let testLat = coordinate.latitude
        let testLon = coordinate.longitude
        var inside = false

        var j = coordinates.count - 1
        for i in 0..<coordinates.count {
            let yi = coordinates[i].latitude
            let xi = coordinates[i].longitude
            let yj = coordinates[j].latitude
            let xj = coordinates[j].longitude

            // Check if the ray crosses this edge
            if ((yi > testLat) != (yj > testLat)) &&
                (testLon < (xj - xi) * (testLat - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }

        return inside
    }
}
