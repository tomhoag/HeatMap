//
//  PolygonSmoother.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation

/// A type that smooths a closed polygon's coordinates.
///
/// Conforming types receive an array of coordinates representing a closed
/// polygon (without a duplicate closing point) and return a smoothed version.
///
/// The HeatMap package includes two built-in smoothers accessible via
/// ``AnyPolygonSmoother``:
///
/// ```swift
/// let config = HeatMapConfiguration(smoother: .chaikin(iterations: 3))
/// ```
///
/// You can also implement your own:
///
/// ```swift
/// struct BezierSmoother: PolygonSmoother {
///     func smooth(
///         _ coordinates: [CLLocationCoordinate2D]
///     ) -> [CLLocationCoordinate2D] {
///         // Custom smoothing logic
///     }
/// }
///
/// let config = HeatMapConfiguration(
///     smoother: AnyPolygonSmoother(BezierSmoother())
/// )
/// ```
///
/// ## Topics
///
/// ### Requirements
///
/// - ``smooth(_:)``
///
/// ### Built-in Smoothers
///
/// - ``AnyPolygonSmoother``
public protocol PolygonSmoother: Sendable, Hashable {
    /// Smooths a closed polygon represented as an array of coordinates.
    ///
    /// The input array does **not** include a duplicate closing point —
    /// the polygon is implicitly closed (last vertex connects back to first).
    /// The returned array should also omit the closing duplicate.
    ///
    /// - Parameter coordinates: The polygon vertices to smooth.
    /// - Returns: The smoothed polygon vertices.
    func smooth(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D]
}

// MARK: - Type-Erased Wrapper

/// A type-erased polygon smoother.
///
/// Use the convenience statics to configure smoothing in a
/// ``HeatMapConfiguration``:
///
/// ```swift
/// .chaikin()              // Chaikin corner-cutting, 2 iterations (default)
/// .chaikin(iterations: 3) // 3 iterations for smoother curves
/// .none                   // No smoothing
/// ```
///
/// Wrap a custom ``PolygonSmoother`` conformance:
///
/// ```swift
/// let custom = AnyPolygonSmoother(MyCustomSmoother())
/// ```
///
/// `AnyPolygonSmoother` preserves `Equatable` and `Hashable` semantics
/// of the wrapped smoother, so two wrappers are equal when their underlying
/// smoothers are equal.
///
/// ## Topics
///
/// ### Factory Methods
///
/// - ``none``
/// - ``chaikin(iterations:)``
///
/// ### Wrapping a Custom Smoother
///
/// - ``init(_:)``
public struct AnyPolygonSmoother: PolygonSmoother {
    private let _smooth: @Sendable ([CLLocationCoordinate2D]) -> [CLLocationCoordinate2D]
    private let _hash: @Sendable (inout Hasher) -> Void
    private let _equals: @Sendable (Any) -> Bool
    private let typeID: ObjectIdentifier
    // The wrapped smoother conforms to Sendable, but is stored as Any for equality checks.
    nonisolated(unsafe) private let unwrapped: Any

    /// Creates a type-erased smoother wrapping the given value.
    ///
    /// - Parameter smoother: A concrete ``PolygonSmoother`` to wrap.
    public init<S: PolygonSmoother>(_ smoother: S) {
        _smooth = { smoother.smooth($0) }
        _hash = { smoother.hash(into: &$0) }
        _equals = { other in
            guard let other = other as? S else { return false }
            return smoother == other
        }
        typeID = ObjectIdentifier(S.self)
        unwrapped = smoother
    }

    public func smooth(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        _smooth(coordinates)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeID)
        _hash(&hasher)
    }

    public static func == (lhs: AnyPolygonSmoother, rhs: AnyPolygonSmoother) -> Bool {
        guard lhs.typeID == rhs.typeID else { return false }
        return lhs._equals(rhs.unwrapped)
    }
}

extension AnyPolygonSmoother {
    /// No smoothing applied.
    ///
    /// Wraps a ``NullSmoother`` that returns coordinates unchanged.
    public static let none = AnyPolygonSmoother(NullSmoother())

    /// Chaikin's corner-cutting with the given number of iterations.
    ///
    /// Wraps a ``ChaikinSmoother``. Each iteration doubles the vertex count,
    /// producing progressively smoother curves.
    ///
    /// - Parameter iterations: The number of subdivision passes. Default: `2`.
    /// - Returns: A type-erased smoother configured for Chaikin smoothing.
    public static func chaikin(iterations: Int = 2) -> AnyPolygonSmoother {
        AnyPolygonSmoother(ChaikinSmoother(iterations: iterations))
    }
}

// MARK: - Built-in Smoothers

/// A smoother that applies no transformation (pass-through).
///
/// Returns the input coordinates unchanged. Use ``AnyPolygonSmoother/none``
/// to access this smoother through the type-erased wrapper.
struct NullSmoother: PolygonSmoother {
    init() {}

    func smooth(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        coordinates
    }
}

/// Chaikin's corner-cutting algorithm for polygon smoothing.
///
/// Each iteration replaces every edge with two new points at the 25% and 75%
/// positions, doubling the vertex count per pass. The result converges toward
/// a quadratic B-spline curve while preserving the polygon's overall shape.
///
/// Use ``AnyPolygonSmoother/chaikin(iterations:)`` for convenient access
/// in a ``HeatMapConfiguration``.
///
/// - Reference: [Chaikin, G. (1974). "An algorithm for high-speed curve generation.](https://www.sciencedirect.com/science/article/abs/pii/0146664X74900288)"
struct ChaikinSmoother: PolygonSmoother {
    /// The number of subdivision passes.
    let iterations: Int

    /// Creates a Chaikin smoother.
    ///
    /// - Parameter iterations: The number of subdivision passes. Default: `2`.
    ///   Values less than `1` result in no smoothing.
    init(iterations: Int = 2) {
        self.iterations = iterations
    }

    func smooth(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
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
