//
//  HeatMapContours+HitTesting.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import CoreLocation

extension HeatMapContours {
    /// Returns the contour polygons whose density band contains the
    /// given coordinate.
    ///
    /// Each polygon represents an annular density band — the region
    /// between its threshold and the next level's threshold. A
    /// coordinate typically falls within exactly one polygon (the band
    /// it sits in) rather than all enclosing levels.
    ///
    /// The returned array preserves the default ordering — lowest level
    /// (outermost) first, highest level (innermost) last.
    ///
    /// ```swift
    /// let hit = contours.contours(containing: tappedCoordinate)
    /// if let band = hit.first {
    ///     print("Density band: level \(band.level), threshold \(band.threshold)")
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
