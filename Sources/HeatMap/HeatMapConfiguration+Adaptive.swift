//
//  HeatMapConfiguration+Adaptive.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation
import Foundation

extension HeatMapConfiguration {

    /// Approximate meters per degree of latitude.
    private static let metersPerDegreeLat: Double = 111_320

    /// Returns the approximate meters per degree of longitude at the given latitude.
    private static func metersPerDegreeLon(at latitude: Double) -> Double {
        metersPerDegreeLat * cos(latitude * .pi / 180)
    }

    /// Creates a configuration with parameters derived from the given points.
    ///
    /// The method examines the geographic spread and density of the input
    /// data to choose a reasonable ``radius`` and ``gridResolution``. This
    /// is a convenient starting point when you don't know the scale of
    /// your data in advance.
    ///
    /// ```swift
    /// let config = HeatMapConfiguration.adaptive(for: points)
    /// let contours = try await HeatMapContours.compute(from: points, configuration: config)
    /// ```
    ///
    /// Because the returned properties are `var`, you can override
    /// individual values after the fact:
    ///
    /// ```swift
    /// var config = HeatMapConfiguration.adaptive(for: points)
    /// config.gradient = .cool
    /// ```
    ///
    /// > Important: The returned configuration is a snapshot of the current
    /// > point set. If points are added or removed dynamically, the
    /// > configuration will not automatically update — you must call
    /// > `adaptive(for:)` again. This can cause visual discontinuities
    /// > (changes in radius or resolution) when the data changes. For
    /// > stable visuals with dynamic data, prefer setting configuration
    /// > values explicitly.
    ///
    /// - Parameter points: The weighted geographic data points.
    /// - Returns: A configuration whose ``radius`` and ``gridResolution``
    ///   are tuned to the spatial distribution of `points`. All other
    ///   properties use their defaults.
    public static func adaptive<P: HeatMapable>(for points: [P]) -> HeatMapConfiguration {
        guard points.count >= 2 else {
            return HeatMapConfiguration()
        }

        // 1. Compute bounding box
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude

        for point in points {
            minLat = min(minLat, point.coordinate.latitude)
            maxLat = max(maxLat, point.coordinate.latitude)
            minLon = min(minLon, point.coordinate.longitude)
            maxLon = max(maxLon, point.coordinate.longitude)
        }

        // 2. Convert to meters
        let centerLat = (minLat + maxLat) / 2
        let heightMeters = (maxLat - minLat) * metersPerDegreeLat
        let widthMeters = (maxLon - minLon) * metersPerDegreeLon(at: centerLat)
        let area = heightMeters * widthMeters

        // 3. Estimate radius from mean inter-point spacing
        let spacing = sqrt(area / Double(points.count))
        let radius = min(max(spacing, 50), 50_000)

        // 4. Derive grid resolution so cell size ≈ radius / 3
        let longerAxis = max(heightMeters, widthMeters)
        let cellSize = radius / 3.0
        let resolution = Int((longerAxis / cellSize).rounded())
        let clampedResolution = min(max(resolution, 20), 300)

        return HeatMapConfiguration(
            radius: radius,
            gridResolution: clampedResolution
        )
    }
}
