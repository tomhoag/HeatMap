//
//  GeoConversions.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import Foundation

/// Internal geo-conversion utilities shared across the package.
enum GeoConversions {
    /// Approximate meters per degree of latitude.
    static let metersPerDegreeLat: Double = 111_320

    /// Returns the approximate meters per degree of longitude at the given latitude.
    ///
    /// Longitude degrees shrink toward the poles due to the convergence of
    /// meridians. This method applies a cosine correction.
    ///
    /// - Parameter latitude: The latitude in degrees.
    /// - Returns: The approximate distance in meters of one degree of longitude.
    static func metersPerDegreeLon(at latitude: Double) -> Double {
        metersPerDegreeLat * cos(latitude * .pi / 180)
    }
}
