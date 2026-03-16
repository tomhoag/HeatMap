//
//  MarchingSquares.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//
// References: https://en.wikipedia.org/wiki/Marching_squares

import CoreLocation
import Foundation

/// A single contour polygon at a specific density level.
struct ContourPolygon: Sendable, Identifiable {
    let id = UUID()
    /// The contour level index (0 = lowest density).
    let level: Int
    /// The density threshold for this contour.
    let threshold: Double
    /// The closed polygon vertices as geographic coordinates.
    let coordinates: [CLLocationCoordinate2D]
}

/// The result of contour extraction: all polygons across all levels.
struct ContourResult: Sendable {
    let polygons: [ContourPolygon]
}

/// Extracts contour polygons from a density grid using the marching squares algorithm.
enum MarchingSquares {

    // MARK: - Public

    /// Extracts contour polygons from the density grid at evenly spaced
    /// threshold levels.
    ///
    /// - Parameters:
    ///   - grid: The density grid to extract contours from.
    ///   - levels: The number of contour levels.
    /// - Returns: A `ContourResult` containing all extracted polygons,
    ///   sorted from lowest level (outermost) to highest (innermost).
    static func extractContours(
        from grid: DensityGrid,
        levels: Int
    ) -> ContourResult {
        guard grid.rows > 1, grid.columns > 1, levels > 0 else {
            return ContourResult(polygons: [])
        }

        let range = grid.maxDensity - grid.minDensity
        guard range > 0 else {
            return ContourResult(polygons: [])
        }

        var allPolygons: [ContourPolygon] = []

        for level in 0..<levels {
            let fraction = Double(level + 1) / Double(levels + 1)
            let threshold = grid.minDensity + range * fraction

            let segments = generateSegments(grid: grid, threshold: threshold)
            let rings = assembleRings(from: segments)

            for ring in rings {
                let coordinates = ring.map { grid.coordinate(row: $0.row, col: $0.col) }
                guard coordinates.count >= 3 else { continue }
                allPolygons.append(
                    ContourPolygon(
                        level: level,
                        threshold: threshold,
                        coordinates: coordinates
                    )
                )
            }
        }

        return ContourResult(polygons: allPolygons)
    }

    // MARK: - Marching Squares Core

    /// A point in grid space (fractional row and column).
    private struct GridPoint: Sendable {
        let row: Double
        let col: Double
    }

    /// A directed segment between two grid points.
    private struct Segment: Sendable {
        let start: GridPoint
        let end: GridPoint
    }

    /// Quantized key for matching segment endpoints.
    /// Rounds to 6 decimal places to avoid floating-point mismatch.
    private struct PointKey: Hashable, Sendable {
        let row: Int
        let col: Int

        init(_ point: GridPoint) {
            self.row = Int(round(point.row * 1_000_000))
            self.col = Int(round(point.col * 1_000_000))
        }
    }

    /// Lookup table for the 16 marching squares cases.
    /// Each case maps to a list of edge pairs (edgeA, edgeB).
    /// Edges: 0 = top, 1 = right, 2 = bottom, 3 = left.
    /// A segment goes from the interpolated point on edgeA to edgeB.
    private static let edgeTable: [[(Int, Int)]] = [
        [],               // Case 0:  none inside
        [(3, 2)],         // Case 1:  BL
        [(2, 1)],         // Case 2:  BR
        [(3, 1)],         // Case 3:  BL + BR
        [(1, 0)],         // Case 4:  TR
        [(3, 0), (1, 2)], // Case 5:  BL + TR (saddle, default)
        [(2, 0)],         // Case 6:  BR + TR
        [(3, 0)],         // Case 7:  BL + BR + TR
        [(0, 3)],         // Case 8:  TL
        [(0, 2)],         // Case 9:  TL + BL
        [(0, 3), (2, 1)], // Case 10: TL + BR (saddle, default)
        [(0, 1)],         // Case 11: TL + BL + BR
        [(1, 3)],         // Case 12: TL + TR
        [(1, 2)],         // Case 13: TL + TR + BL
        [(2, 3)],         // Case 14: TL + TR + BR
        [],               // Case 15: all inside
    ]

    /// Alternate edge table entries for saddle cases when disambiguated
    /// with cell center value >= threshold.
    private static let saddleCase5Alt: [(Int, Int)] = [(3, 2), (1, 0)]
    private static let saddleCase10Alt: [(Int, Int)] = [(0, 1), (2, 3)]

    /// Generates all directed edge segments for a given threshold.
    ///
    /// Rows are processed in parallel using `DispatchQueue.concurrentPerform`.
    /// Each row writes to its own slot, so no synchronization is needed.
    private static func generateSegments(
        grid: DensityGrid,
        threshold: Double
    ) -> [Segment] {
        let rowCount = grid.rows - 1
        guard rowCount > 0 else { return [] }

        // Pre-allocate one array per row to collect segments without contention.
        // Each concurrent iteration writes only to its own index, so this is safe.
        nonisolated(unsafe) let rowSegments = UnsafeMutableBufferPointer<[Segment]>.allocate(capacity: rowCount)
        rowSegments.initialize(repeating: [])

        DispatchQueue.concurrentPerform(iterations: rowCount) { row in
            var localSegments: [Segment] = []

            for col in 0..<(grid.columns - 1) {
                let tl = grid.value(row: row, col: col)
                let tr = grid.value(row: row, col: col + 1)
                let br = grid.value(row: row + 1, col: col + 1)
                let bl = grid.value(row: row + 1, col: col)

                var caseIndex = 0
                if tl >= threshold { caseIndex |= 8 }
                if tr >= threshold { caseIndex |= 4 }
                if br >= threshold { caseIndex |= 2 }
                if bl >= threshold { caseIndex |= 1 }

                // Skip cases with no edges
                guard caseIndex != 0, caseIndex != 15 else { continue }

                // Disambiguate saddle cases
                let edges: [(Int, Int)]
                if caseIndex == 5 {
                    let center = (tl + tr + br + bl) / 4.0
                    edges = center >= threshold ? saddleCase5Alt : edgeTable[5]
                } else if caseIndex == 10 {
                    let center = (tl + tr + br + bl) / 4.0
                    edges = center >= threshold ? saddleCase10Alt : edgeTable[10]
                } else {
                    edges = edgeTable[caseIndex]
                }

                let corners = (tl: tl, tr: tr, br: br, bl: bl)

                for (edgeA, edgeB) in edges {
                    let start = interpolateEdge(
                        edge: edgeA, row: row, col: col,
                        corners: corners, threshold: threshold
                    )
                    let end = interpolateEdge(
                        edge: edgeB, row: row, col: col,
                        corners: corners, threshold: threshold
                    )
                    localSegments.append(Segment(start: start, end: end))
                }
            }

            rowSegments[row] = localSegments
        }

        let segments = Array(rowSegments).flatMap { $0 }
        rowSegments.deinitialize()
        rowSegments.deallocate()
        return segments
    }

    /// Computes the interpolated point on a cell edge.
    ///
    /// - Parameters:
    ///   - edge: The edge index (0=top, 1=right, 2=bottom, 3=left).
    ///   - row: The top-left row of the 2x2 cell.
    ///   - col: The top-left column of the 2x2 cell.
    ///   - corners: The four corner values (tl, tr, br, bl).
    ///   - threshold: The contour threshold.
    /// - Returns: The interpolated position as a `GridPoint`.
    private static func interpolateEdge(
        edge: Int,
        row: Int,
        col: Int,
        corners: (tl: Double, tr: Double, br: Double, bl: Double),
        threshold: Double
    ) -> GridPoint {
        switch edge {
        case 0: // Top edge: between TL and TR
            let t = safeLerp(threshold, corners.tl, corners.tr)
            return GridPoint(row: Double(row), col: Double(col) + t)
        case 1: // Right edge: between TR and BR
            let t = safeLerp(threshold, corners.tr, corners.br)
            return GridPoint(row: Double(row) + t, col: Double(col + 1))
        case 2: // Bottom edge: between BL and BR
            let t = safeLerp(threshold, corners.bl, corners.br)
            return GridPoint(row: Double(row + 1), col: Double(col) + t)
        case 3: // Left edge: between TL and BL
            let t = safeLerp(threshold, corners.tl, corners.bl)
            return GridPoint(row: Double(row) + t, col: Double(col))
        default:
            return GridPoint(row: Double(row), col: Double(col))
        }
    }

    /// Safe linear interpolation factor: returns `(threshold - v0) / (v1 - v0)`,
    /// clamped to [0, 1] to avoid division by zero.
    private static func safeLerp(_ threshold: Double, _ v0: Double, _ v1: Double) -> Double {
        let denom = v1 - v0
        guard abs(denom) > 1e-12 else { return 0.5 }
        return min(max((threshold - v0) / denom, 0), 1)
    }

    // MARK: - Polygon Assembly

    /// Assembles directed segments into closed polygon rings.
    ///
    /// Uses a dictionary keyed by quantized start points to chain
    /// segments together into closed rings.
    private static func assembleRings(from segments: [Segment]) -> [[GridPoint]] {
        guard !segments.isEmpty else { return [] }

        // Build adjacency map: quantized start point -> list of segments
        var adjacency: [PointKey: [Segment]] = [:]
        for segment in segments {
            let key = PointKey(segment.start)
            adjacency[key, default: []].append(segment)
        }

        var rings: [[GridPoint]] = []

        // Consume segments until none remain
        while !adjacency.isEmpty {
            // Pick any starting segment
            guard let firstKey = adjacency.keys.first,
                  var segmentList = adjacency[firstKey],
                  !segmentList.isEmpty else { break }

            let firstSegment = segmentList.removeLast()
            if segmentList.isEmpty {
                adjacency.removeValue(forKey: firstKey)
            } else {
                adjacency[firstKey] = segmentList
            }

            var ring: [GridPoint] = [firstSegment.start, firstSegment.end]
            let startKey = PointKey(firstSegment.start)

            // Follow the chain
            var maxIterations = segments.count
            while maxIterations > 0 {
                maxIterations -= 1

                let currentKey = PointKey(ring[ring.count - 1])

                // Check if we've closed the ring
                if currentKey == startKey, ring.count > 2 {
                    break
                }

                guard var nextList = adjacency[currentKey],
                      !nextList.isEmpty else { break }

                let next = nextList.removeLast()
                if nextList.isEmpty {
                    adjacency.removeValue(forKey: currentKey)
                } else {
                    adjacency[currentKey] = nextList
                }

                ring.append(next.end)
            }

            // Only keep closed rings with enough vertices
            if ring.count >= 4 {
                // Remove the duplicate closing point
                ring.removeLast()
                rings.append(ring)
            }
        }

        return rings
    }
}
