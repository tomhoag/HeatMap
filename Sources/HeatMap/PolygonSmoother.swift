//
//  PolygonSmoother.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation

/// A polygon smoothing algorithm applied to extracted contour polygons.
///
/// Smoothing reduces the stair-step artifacts produced by the marching
/// squares algorithm. Use one of the built-in cases when creating a
/// ``HeatMapConfiguration``:
///
/// ```swift
/// let config = HeatMapConfiguration(smoother: .chaikin(iterations: 3))
/// ```
///
/// ## Topics
///
/// ### Smoothing Algorithms
///
/// - ``none``
/// - ``chaikin(iterations:)``
public enum PolygonSmoother: Sendable, Hashable {
    /// No smoothing applied. Returns coordinates unchanged.
    case none

    /// Chaikin's corner-cutting algorithm.
    ///
    /// Each iteration replaces every edge with two new points at the 25% and
    /// 75% positions, doubling the vertex count per pass. The result converges
    /// toward a quadratic B-spline curve while preserving the polygon's
    /// overall shape.
    ///
    /// - Parameter iterations: The number of subdivision passes. Default: `2`.
    ///   Values less than `1` result in no smoothing.
    ///
    /// - Reference: [Chaikin, G. (1974). "An algorithm for high-speed curve generation."](https://www.sciencedirect.com/science/article/abs/pii/0146664X74900288)
    case chaikin(iterations: Int = 2)

    /// Smooths a closed polygon represented as an array of coordinates.
    ///
    /// The input array does **not** include a duplicate closing point —
    /// the polygon is implicitly closed (last vertex connects back to first).
    /// The returned array also omits the closing duplicate.
    ///
    /// - Parameter coordinates: The polygon vertices to smooth.
    /// - Returns: The smoothed polygon vertices.
    func smooth(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        switch self {
        case .none:
            return coordinates
        case .chaikin(let iterations):
            return Self.chaikinSmooth(coordinates, iterations: iterations)
        }
    }

    /// Chaikin corner-cutting implementation.
    private static func chaikinSmooth(
        _ coordinates: [CLLocationCoordinate2D],
        iterations: Int
    ) -> [CLLocationCoordinate2D] {
        guard coordinates.count >= 3, iterations >= 1 else {
            return coordinates
        }

        var points = coordinates

        for _ in 0..<iterations {
            var newPoints: [CLLocationCoordinate2D] = []
            newPoints.reserveCapacity(points.count * 2)

            let count = points.count
            for i in 0..<count {
                let current = points[i]
                let next = points[(i + 1) % count]

                // Q point at 25% along edge
                let q = CLLocationCoordinate2D(
                    latitude: 0.75 * current.latitude + 0.25 * next.latitude,
                    longitude: 0.75 * current.longitude + 0.25 * next.longitude
                )
                // R point at 75% along edge
                let r = CLLocationCoordinate2D(
                    latitude: 0.25 * current.latitude + 0.75 * next.latitude,
                    longitude: 0.25 * current.longitude + 0.75 * next.longitude
                )

                newPoints.append(q)
                newPoints.append(r)
            }

            points = newPoints
        }

        return points
    }
}

extension PolygonSmoother: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .chaikin(let iterations):
            return "chaikin(\(iterations))"
        }
    }
}
