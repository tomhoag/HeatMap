import CoreLocation
import Testing
@testable import HeatMap

struct PolygonSmootherTests {

    // A simple triangle for testing
    let triangle: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 0),
        CLLocationCoordinate2D(latitude: 0.5, longitude: 1),
    ]

    // A square for testing
    let square: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1),
        CLLocationCoordinate2D(latitude: 0, longitude: 1),
    ]

    // MARK: - NullSmoother

    @Test func nullSmootherReturnsIdenticalCoordinates() {
        let smoother = NullSmoother()
        let result = smoother.smooth(triangle)
        #expect(result.count == triangle.count)
        for (a, b) in zip(result, triangle) {
            #expect(a.latitude == b.latitude)
            #expect(a.longitude == b.longitude)
        }
    }

    @Test func nullSmootherHandlesEmptyInput() {
        let smoother = NullSmoother()
        let result = smoother.smooth([])
        #expect(result.isEmpty)
    }

    // MARK: - ChaikinSmoother

    @Test func chaikinIncreasesVertexCount() {
        let smoother = ChaikinSmoother(iterations: 1)
        let result = smoother.smooth(triangle)
        // 3 vertices * 2 = 6 after one pass
        #expect(result.count == triangle.count * 2)
    }

    @Test func chaikinTwoIterationsDoublesAgain() {
        let smoother = ChaikinSmoother(iterations: 2)
        let result = smoother.smooth(triangle)
        // 3 * 2 * 2 = 12 after two passes
        #expect(result.count == triangle.count * 4)
    }

    @Test func chaikinDefaultIterationsIsTwo() {
        let smoother = ChaikinSmoother()
        #expect(smoother.iterations == 2)
    }

    @Test func chaikinZeroIterationsReturnsOriginal() {
        let smoother = ChaikinSmoother(iterations: 0)
        let result = smoother.smooth(triangle)
        #expect(result.count == triangle.count)
    }

    @Test func chaikinWithTwoVerticesReturnsOriginal() {
        let smoother = ChaikinSmoother(iterations: 2)
        let twoPoints = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
        ]
        let result = smoother.smooth(twoPoints)
        #expect(result.count == 2)
    }

    @Test func chaikinPointsStayWithinBounds() {
        let smoother = ChaikinSmoother(iterations: 3)
        let result = smoother.smooth(square)
        for coord in result {
            #expect(coord.latitude >= 0 && coord.latitude <= 1)
            #expect(coord.longitude >= 0 && coord.longitude <= 1)
        }
    }

    @Test func chaikinPreservesClosedShape() {
        // After smoothing, the last point's "next" wraps to the first,
        // so the polygon should still be implicitly closed.
        let smoother = ChaikinSmoother(iterations: 2)
        let result = smoother.smooth(square)
        // Smoothed polygon should have vertices, no duplicates at start/end
        let first = result.first!
        let last = result.last!
        let isClosed = (first.latitude == last.latitude && first.longitude == last.longitude)
        #expect(!isClosed, "Smoothed polygon should not have duplicate closing point")
    }

    // MARK: - AnyPolygonSmoother

    @Test func anySmootherNoneIsIdentity() {
        let smoother = AnyPolygonSmoother.none
        let result = smoother.smooth(triangle)
        #expect(result.count == triangle.count)
    }

    @Test func anySmootherChaikinSmooths() {
        let smoother = AnyPolygonSmoother.chaikin(iterations: 1)
        let result = smoother.smooth(triangle)
        #expect(result.count == triangle.count * 2)
    }

    @Test func anySmootherDefaultChaikinHasTwoIterations() {
        let smoother = AnyPolygonSmoother.chaikin()
        let result = smoother.smooth(triangle)
        // 2 iterations: 3 * 4 = 12
        #expect(result.count == triangle.count * 4)
    }

    // MARK: - Equality

    @Test func nullSmootherEquality() {
        #expect(NullSmoother() == NullSmoother())
    }

    @Test func chaikinSmootherEqualitySameIterations() {
        #expect(ChaikinSmoother(iterations: 3) == ChaikinSmoother(iterations: 3))
    }

    @Test func chaikinSmootherInequalityDifferentIterations() {
        #expect(ChaikinSmoother(iterations: 2) != ChaikinSmoother(iterations: 3))
    }

    @Test func anySmootherEqualitySameType() {
        let a = AnyPolygonSmoother.chaikin(iterations: 2)
        let b = AnyPolygonSmoother.chaikin(iterations: 2)
        #expect(a == b)
    }

    @Test func anySmootherInequalityDifferentParams() {
        let a = AnyPolygonSmoother.chaikin(iterations: 2)
        let b = AnyPolygonSmoother.chaikin(iterations: 3)
        #expect(a != b)
    }

    @Test func anySmootherInequalityDifferentTypes() {
        let a = AnyPolygonSmoother.none
        let b = AnyPolygonSmoother.chaikin()
        #expect(a != b)
    }

    // MARK: - Custom Smoother Protocol Conformance

    @Test func customSmootherViaProtocol() {
        // A custom smoother that reverses the coordinates
        struct ReverseSmoother: PolygonSmoother {
            func smooth(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
                coordinates.reversed()
            }
        }

        let smoother = AnyPolygonSmoother(ReverseSmoother())
        let result = smoother.smooth(triangle)
        #expect(result.count == triangle.count)
        #expect(result.first!.latitude == triangle.last!.latitude)
        #expect(result.first!.longitude == triangle.last!.longitude)
    }

    // MARK: - Hashable

    @Test func anySmootherHashConsistency() {
        let a = AnyPolygonSmoother.chaikin(iterations: 2)
        let b = AnyPolygonSmoother.chaikin(iterations: 2)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func anySmootherCanBeUsedInSet() {
        let set: Set<AnyPolygonSmoother> = [
            .none,
            .chaikin(iterations: 1),
            .chaikin(iterations: 2),
            .chaikin(iterations: 2),  // duplicate
        ]
        #expect(set.count == 3)
    }

    // MARK: - Configuration Integration

    @Test func defaultConfigurationUsesChaikin() {
        let config = HeatMapConfiguration()
        let result = config.smoother.smooth(triangle)
        // Default is Chaikin with 2 iterations: 3 * 4 = 12
        #expect(result.count == triangle.count * 4)
    }

    @Test func configurationWithNoSmoothing() {
        let config = HeatMapConfiguration(smoother: .none)
        let result = config.smoother.smooth(triangle)
        #expect(result.count == triangle.count)
    }
}
