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

    // MARK: - None

    @Test func noneReturnsIdenticalCoordinates() {
        let smoother = PolygonSmoother.none
        let result = smoother.smooth(triangle)
        #expect(result.count == triangle.count)
        for (a, b) in zip(result, triangle) {
            #expect(a.latitude == b.latitude)
            #expect(a.longitude == b.longitude)
        }
    }

    @Test func noneHandlesEmptyInput() {
        let smoother = PolygonSmoother.none
        let result = smoother.smooth([])
        #expect(result.isEmpty)
    }

    // MARK: - Chaikin

    @Test func chaikinIncreasesVertexCount() {
        let smoother = PolygonSmoother.chaikin(iterations: 1)
        let result = smoother.smooth(triangle)
        // 3 vertices * 2 = 6 after one pass
        #expect(result.count == triangle.count * 2)
    }

    @Test func chaikinTwoIterationsDoublesAgain() {
        let smoother = PolygonSmoother.chaikin(iterations: 2)
        let result = smoother.smooth(triangle)
        // 3 * 2 * 2 = 12 after two passes
        #expect(result.count == triangle.count * 4)
    }

    @Test func chaikinDefaultIterationsIsTwo() {
        let smoother = PolygonSmoother.chaikin()
        let result = smoother.smooth(triangle)
        // Default is 2 iterations: 3 * 4 = 12
        #expect(result.count == triangle.count * 4)
    }

    @Test func chaikinZeroIterationsReturnsOriginal() {
        let smoother = PolygonSmoother.chaikin(iterations: 0)
        let result = smoother.smooth(triangle)
        #expect(result.count == triangle.count)
    }

    @Test func chaikinWithTwoVerticesReturnsOriginal() {
        let smoother = PolygonSmoother.chaikin(iterations: 2)
        let twoPoints = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
        ]
        let result = smoother.smooth(twoPoints)
        #expect(result.count == 2)
    }

    @Test func chaikinPointsStayWithinBounds() {
        let smoother = PolygonSmoother.chaikin(iterations: 3)
        let result = smoother.smooth(square)
        for coord in result {
            #expect(coord.latitude >= 0 && coord.latitude <= 1)
            #expect(coord.longitude >= 0 && coord.longitude <= 1)
        }
    }

    @Test func chaikinPreservesClosedShape() {
        // After smoothing, the last point's "next" wraps to the first,
        // so the polygon should still be implicitly closed.
        let smoother = PolygonSmoother.chaikin(iterations: 2)
        let result = smoother.smooth(square)
        // Smoothed polygon should have vertices, no duplicates at start/end
        let first = result.first!
        let last = result.last!
        let isClosed = (first.latitude == last.latitude && first.longitude == last.longitude)
        #expect(!isClosed, "Smoothed polygon should not have duplicate closing point")
    }

    // MARK: - Equality

    @Test func noneEqualsNone() {
        #expect(PolygonSmoother.none == PolygonSmoother.none)
    }

    @Test func chaikinEqualitySameIterations() {
        #expect(PolygonSmoother.chaikin(iterations: 3) == PolygonSmoother.chaikin(iterations: 3))
    }

    @Test func chaikinInequalityDifferentIterations() {
        #expect(PolygonSmoother.chaikin(iterations: 2) != PolygonSmoother.chaikin(iterations: 3))
    }

    @Test func noneNotEqualToChaikin() {
        #expect(PolygonSmoother.none != PolygonSmoother.chaikin())
    }

    // MARK: - Hashable

    @Test func hashConsistency() {
        let a = PolygonSmoother.chaikin(iterations: 2)
        let b = PolygonSmoother.chaikin(iterations: 2)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func canBeUsedInSet() {
        let set: Set<PolygonSmoother> = [
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

    // MARK: - CustomStringConvertible

    @Test func descriptionForNone() {
        #expect(String(describing: PolygonSmoother.none) == "none")
    }

    @Test func descriptionForChaikinDefault() {
        #expect(String(describing: PolygonSmoother.chaikin()) == "chaikin(2)")
    }

    @Test func descriptionForChaikinCustomIterations() {
        #expect(String(describing: PolygonSmoother.chaikin(iterations: 5)) == "chaikin(5)")
    }
}
