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
struct DensityGrid: Sendable {
    /// Row-major storage: `values[row * columns + column]`.
    let values: [Double]
    let rows: Int
    let columns: Int

    /// The geographic bounding box of the grid (with padding applied).
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    /// The size of each grid cell in degrees.
    let latitudeStep: Double
    let longitudeStep: Double

    /// The minimum and maximum density values in the grid.
    let minDensity: Double
    let maxDensity: Double

    /// Approximate meters per degree of latitude.
    private static let metersPerDegreeLat: Double = 111_320

    /// Returns approximate meters per degree of longitude at the given latitude.
    private static func metersPerDegreeLon(at latitude: Double) -> Double {
        metersPerDegreeLat * cos(latitude * .pi / 180)
    }

    /// Computes a density grid from the given heat map points.
    ///
    /// This method is nonisolated and `Sendable`-safe, suitable for
    /// calling from a background context.
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
        let deltaLat = padding / metersPerDegreeLat
        let deltaLon = padding / metersPerDegreeLon(at: centerLat)

        minLat -= deltaLat
        maxLat += deltaLat
        minLon -= deltaLon
        maxLon += deltaLon

        // 3. Determine grid dimensions based on aspect ratio in meters
        let heightMeters = (maxLat - minLat) * metersPerDegreeLat
        let widthMeters = (maxLon - minLon) * metersPerDegreeLon(at: centerLat)

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
        let kernelRadiusLat = (3.0 * sigma) / metersPerDegreeLat
        let kernelRadiusLon = (3.0 * sigma) / metersPerDegreeLon(at: centerLat)

        var grid = [Double](repeating: 0, count: rows * columns)

        for point in points {
            let pointLat = point.coordinate.latitude
            let pointLon = point.coordinate.longitude

            // Determine affected row/column range
            let rowStart = max(0, Int((pointLat - kernelRadiusLat - minLat) / latStep))
            let rowEnd = min(rows - 1, Int((pointLat + kernelRadiusLat - minLat) / latStep))
            let colStart = max(0, Int((pointLon - kernelRadiusLon - minLon) / lonStep))
            let colEnd = min(columns - 1, Int((pointLon + kernelRadiusLon - minLon) / lonStep))

            for row in rowStart...rowEnd {
                let cellLat = minLat + (Double(row) + 0.5) * latStep
                let dy = (cellLat - pointLat) * metersPerDegreeLat

                for col in colStart...colEnd {
                    let cellLon = minLon + (Double(col) + 0.5) * lonStep
                    let dx = (cellLon - pointLon) * metersPerDegreeLon(at: cellLat)

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
    func value(row: Int, col: Int) -> Double {
        guard row >= 0, row < rows, col >= 0, col < columns else { return 0 }
        return values[row * columns + col]
    }

    /// Converts a grid position (fractional row, fractional column) to
    /// a geographic coordinate.
    func coordinate(row: Double, col: Double) -> CLLocationCoordinate2D {
        let latitude = minLatitude + row * latitudeStep
        let longitude = minLongitude + col * longitudeStep
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
