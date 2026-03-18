//
//  DensityGrid.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation
import Foundation

/// A 2D grid of density values computed from weighted geographic points
/// using Gaussian kernel density estimation.
///
/// The grid is constructed over a padded bounding box that encloses all
/// input points. Each cell accumulates contributions from nearby points
/// using a Gaussian kernel whose spread is controlled by
/// ``HeatMapConfiguration/radius``.
///
/// You don't create a `DensityGrid` directly. Instead, it is built
/// internally by ``HeatMapLayer`` and ``HeatMapContours`` during contour
/// extraction.
///
/// ## Topics
///
/// ### Computing the Grid
///
/// - ``compute(from:configuration:)``
///
/// ### Querying Values
///
/// - ``value(row:col:)``
/// - ``coordinate(row:col:)``
struct DensityGrid: Sendable {
    /// Row-major storage: `values[row * columns + column]`.
    let values: [Double]

    /// The number of rows in the grid.
    let rows: Int

    /// The number of columns in the grid.
    let columns: Int

    /// The southern boundary of the grid in degrees latitude.
    let minLatitude: Double

    /// The northern boundary of the grid in degrees latitude.
    let maxLatitude: Double

    /// The western boundary of the grid in degrees longitude.
    let minLongitude: Double

    /// The eastern boundary of the grid in degrees longitude.
    let maxLongitude: Double

    /// The height of each grid cell in degrees latitude.
    let latitudeStep: Double

    /// The width of each grid cell in degrees longitude.
    let longitudeStep: Double

    /// The smallest density value found in the grid.
    let minDensity: Double

    /// The largest density value found in the grid.
    let maxDensity: Double

    /// Computes a density grid from the given heat map points.
    ///
    /// The algorithm:
    /// 1. Computes the bounding box of all points.
    /// 2. Pads the bounding box by ``HeatMapConfiguration/radius`` ×
    ///    ``HeatMapConfiguration/paddingFactor``.
    /// 3. Divides the region into a grid whose longer axis has
    ///    ``HeatMapConfiguration/gridResolution`` cells.
    /// 4. Accumulates a Gaussian kernel contribution from each point into
    ///    every cell within 3σ (where σ = radius / 3).
    ///
    /// This method is `Sendable`-safe and can be called from any isolation
    /// context.
    ///
    /// - Parameters:
    ///   - points: The weighted geographic data points.
    ///   - configuration: The parameters controlling grid size, kernel radius,
    ///     and padding.
    /// - Returns: A fully populated density grid.
    static func compute<P: HeatMapable>(
        from points: [P],
        configuration: HeatMapConfiguration
    ) -> DensityGrid {
        guard !points.isEmpty else {
            return DensityGrid(
                values: [], rows: 0, columns: 0,
                minLatitude: 0, maxLatitude: 0,
                minLongitude: 0, maxLongitude: 0,
                latitudeStep: 0, longitudeStep: 0,
                minDensity: 0, maxDensity: 0
            )
        }

        // 1. Compute bounding box of all points
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

        // 2. Expand bounding box by radius * paddingFactor
        let padding = configuration.radius * configuration.paddingFactor
        let centerLat = (minLat + maxLat) / 2
        let deltaLat = padding / GeoConversions.metersPerDegreeLat
        let deltaLon = padding / GeoConversions.metersPerDegreeLon(at: centerLat)

        minLat -= deltaLat
        maxLat += deltaLat
        minLon -= deltaLon
        maxLon += deltaLon

        // 3. Determine grid dimensions based on aspect ratio in meters
        let heightMeters = (maxLat - minLat) * GeoConversions.metersPerDegreeLat
        let widthMeters = (maxLon - minLon) * GeoConversions.metersPerDegreeLon(at: centerLat)

        let resolution = max(configuration.gridResolution, 2)
        let rows: Int
        let columns: Int

        if heightMeters >= widthMeters {
            rows = resolution
            columns = max(2, Int(Double(resolution) * widthMeters / heightMeters))
        } else {
            columns = resolution
            rows = max(2, Int(Double(resolution) * heightMeters / widthMeters))
        }

        let latStep = (maxLat - minLat) / Double(rows)
        let lonStep = (maxLon - minLon) / Double(columns)

        // 4. Accumulate Gaussian kernel density
        let sigma = configuration.radius / 3.0
        let twoSigmaSquared = 2.0 * sigma * sigma
        // Only visit cells within 3 * sigma of each point
        let kernelRadiusLat = (3.0 * sigma) / GeoConversions.metersPerDegreeLat
        let kernelRadiusLon = (3.0 * sigma) / GeoConversions.metersPerDegreeLon(at: centerLat)

        var grid = [Double](repeating: 0, count: rows * columns)

        for point in points {
            assert(point.weight >= 0, "HeatMapable.weight must be non-negative, got \(point.weight)")
            let pointLat = point.coordinate.latitude
            let pointLon = point.coordinate.longitude

            // Determine affected row/column range
            let rowStart = max(0, Int((pointLat - kernelRadiusLat - minLat) / latStep))
            let rowEnd = min(rows - 1, Int((pointLat + kernelRadiusLat - minLat) / latStep))
            let colStart = max(0, Int((pointLon - kernelRadiusLon - minLon) / lonStep))
            let colEnd = min(columns - 1, Int((pointLon + kernelRadiusLon - minLon) / lonStep))

            for row in rowStart...rowEnd {
                let cellLat = minLat + (Double(row) + 0.5) * latStep
                let dy = (cellLat - pointLat) * GeoConversions.metersPerDegreeLat
                let lonScale = GeoConversions.metersPerDegreeLon(at: cellLat)

                for col in colStart...colEnd {
                    let cellLon = minLon + (Double(col) + 0.5) * lonStep
                    let dx = (cellLon - pointLon) * lonScale

                    let distanceSquared = dx * dx + dy * dy
                    let value = point.weight * exp(-distanceSquared / twoSigmaSquared)
                    grid[row * columns + col] += value
                }
            }
        }

        // 5. Find min/max density
        var gridMin = Double.greatestFiniteMagnitude
        var gridMax = -Double.greatestFiniteMagnitude
        for value in grid {
            gridMin = min(gridMin, value)
            gridMax = max(gridMax, value)
        }

        return DensityGrid(
            values: grid,
            rows: rows,
            columns: columns,
            minLatitude: minLat,
            maxLatitude: maxLat,
            minLongitude: minLon,
            maxLongitude: maxLon,
            latitudeStep: latStep,
            longitudeStep: lonStep,
            minDensity: gridMin,
            maxDensity: gridMax
        )
    }

    /// Returns the density value at the given row and column.
    ///
    /// - Parameters:
    ///   - row: The zero-based row index.
    ///   - col: The zero-based column index.
    /// - Returns: The density value, or `0` if the indices are out of bounds.
    func value(row: Int, col: Int) -> Double {
        guard row >= 0, row < rows, col >= 0, col < columns else { return 0 }
        return values[row * columns + col]
    }

    /// Converts a fractional grid position to a geographic coordinate.
    ///
    /// - Parameters:
    ///   - row: The fractional row position (0 = southern boundary).
    ///   - col: The fractional column position (0 = western boundary).
    /// - Returns: The corresponding geographic coordinate.
    func coordinate(row: Double, col: Double) -> CLLocationCoordinate2D {
        let latitude = minLatitude + row * latitudeStep
        let longitude = minLongitude + col * longitudeStep
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
