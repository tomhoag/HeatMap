//
//  HeatMapContours+HitTesting.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import CoreLocation

extension HeatMapContours {
    /// Returns the contour polygons that contain the given coordinate.
    ///
    /// The returned array preserves the default ordering — lowest level
    /// (outermost) first, highest level (innermost) last. A point inside
    /// a high-density region will typically be contained by multiple nested
    /// polygons at increasing levels.
    ///
    /// ```swift
    /// let hit = contours.contours(containing: tappedCoordinate)
    /// if let innermost = hit.last {
    ///     print("Density band: level \(innermost.level), threshold \(innermost.threshold)")
    /// }
    /// ```
    ///
    /// - Parameter coordinate: The geographic coordinate to test.
    /// - Returns: The contour polygons containing the coordinate, ordered
    ///   from lowest to highest level.
    public func contours(containing coordinate: CLLocationCoordinate2D) -> [HeatMapPolygon] {
        contours.filter { $0.contains(coordinate) }
    }
}
