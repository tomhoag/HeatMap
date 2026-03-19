import CoreLocation
import Testing
@testable import HeatMap

struct HitTestingTests {

    // MARK: - Test Polygons

    /// A triangle around (1, 1).
    private let triangle = HeatMapPolygon(
        id: UUID(),
        level: 0,
        threshold: 1.0,
        coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 2, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 2),
        ]
    )

    /// A unit square from (0,0) to (1,1).
    private let square = HeatMapPolygon(
        id: UUID(),
        level: 0,
        threshold: 1.0,
        coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 0),
        ]
    )

    // MARK: - HeatMapPolygon.contains

    @Test func pointInsideTriangle() {
        let point = CLLocationCoordinate2D(latitude: 1, longitude: 0.5)
        #expect(triangle.contains(point))
    }

    @Test func pointOutsideTriangle() {
        let point = CLLocationCoordinate2D(latitude: 5, longitude: 5)
        #expect(!triangle.contains(point))
    }

    @Test func pointInsideSquare() {
        let point = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)
        #expect(square.contains(point))
    }

    @Test func pointOutsideSquare() {
        let point = CLLocationCoordinate2D(latitude: 2, longitude: 2)
        #expect(!square.contains(point))
    }

    @Test func emptyCoordinatesReturnsFalse() {
        let polygon = HeatMapPolygon(
            id: UUID(), level: 0, threshold: 1.0, coordinates: []
        )
        let point = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        #expect(!polygon.contains(point))
    }

    @Test func singleCoordinateReturnsFalse() {
        let polygon = HeatMapPolygon(
            id: UUID(), level: 0, threshold: 1.0,
            coordinates: [CLLocationCoordinate2D(latitude: 0, longitude: 0)]
        )
        let point = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        #expect(!polygon.contains(point))
    }

    @Test func twoCoordinatesReturnsFalse() {
        let polygon = HeatMapPolygon(
            id: UUID(), level: 0, threshold: 1.0,
            coordinates: [
                CLLocationCoordinate2D(latitude: 0, longitude: 0),
                CLLocationCoordinate2D(latitude: 1, longitude: 1),
            ]
        )
        let point = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)
        #expect(!polygon.contains(point))
    }

    @Test func pointOnVertexDoesNotCrash() {
        // Implementation-defined result; just verify no crash
        let point = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        _ = triangle.contains(point)
    }

    @Test func pointOnEdgeDoesNotCrash() {
        // Midpoint of first edge; implementation-defined result
        let point = CLLocationCoordinate2D(latitude: 1, longitude: 0)
        _ = triangle.contains(point)
    }

    // MARK: - HeatMapContours.contours(containing:)

    @Test func coordinateInsideContoursReturnsNonEmpty() {
        let contours = HeatMapContours.compute(from: tightCluster)
        // Use the centroid of the cluster
        let center = CLLocationCoordinate2D(latitude: 37.775, longitude: -122.4186)
        let hit = contours.contours(containing: center)
        #expect(!hit.isEmpty)
    }

    @Test func coordinateFarOutsideReturnsEmpty() {
        let contours = HeatMapContours.compute(from: tightCluster)
        let farAway = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let hit = contours.contours(containing: farAway)
        #expect(hit.isEmpty)
    }

    @Test func resultIsOrderedByLevel() {
        let contours = HeatMapContours.compute(from: tightCluster)
        let center = CLLocationCoordinate2D(latitude: 37.775, longitude: -122.4186)
        let hit = contours.contours(containing: center)
        for i in 1..<hit.count {
            #expect(hit[i].level >= hit[i - 1].level)
        }
    }

    @Test func innerPointHitsHigherLevelThanOuterPoint() {
        let config = HeatMapConfiguration(contourLevels: 10)
        let contours = HeatMapContours.compute(from: tightCluster, configuration: config)
        // Center of the cluster (should be inside a high-level band)
        let inner = CLLocationCoordinate2D(latitude: 37.775, longitude: -122.4186)
        // Edge of the cluster (should be inside a lower-level band)
        let outer = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4220)
        let innerHit = contours.contours(containing: inner)
        let outerHit = contours.contours(containing: outer)
        // With annular polygons, each point typically matches exactly one band
        if let innerBand = innerHit.last, let outerBand = outerHit.last {
            #expect(innerBand.level >= outerBand.level)
        }
    }

    // MARK: - Hole-Aware Containment

    @Test func pointInsideHoleReturnsFalse() {
        let polygon = HeatMapPolygon(
            id: UUID(), level: 0, threshold: 1.0,
            coordinates: [
                CLLocationCoordinate2D(latitude: 0, longitude: 0),
                CLLocationCoordinate2D(latitude: 0, longitude: 4),
                CLLocationCoordinate2D(latitude: 4, longitude: 4),
                CLLocationCoordinate2D(latitude: 4, longitude: 0),
            ],
            interiorPolygons: [[
                CLLocationCoordinate2D(latitude: 1, longitude: 1),
                CLLocationCoordinate2D(latitude: 1, longitude: 3),
                CLLocationCoordinate2D(latitude: 3, longitude: 3),
                CLLocationCoordinate2D(latitude: 3, longitude: 1),
            ]]
        )
        let holePoint = CLLocationCoordinate2D(latitude: 2, longitude: 2)
        #expect(!polygon.contains(holePoint))
    }

    @Test func pointInAnnularRingReturnsTrue() {
        let polygon = HeatMapPolygon(
            id: UUID(), level: 0, threshold: 1.0,
            coordinates: [
                CLLocationCoordinate2D(latitude: 0, longitude: 0),
                CLLocationCoordinate2D(latitude: 0, longitude: 4),
                CLLocationCoordinate2D(latitude: 4, longitude: 4),
                CLLocationCoordinate2D(latitude: 4, longitude: 0),
            ],
            interiorPolygons: [[
                CLLocationCoordinate2D(latitude: 1, longitude: 1),
                CLLocationCoordinate2D(latitude: 1, longitude: 3),
                CLLocationCoordinate2D(latitude: 3, longitude: 3),
                CLLocationCoordinate2D(latitude: 3, longitude: 1),
            ]]
        )
        let ringPoint = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)
        #expect(polygon.contains(ringPoint))
    }

    @Test func pointOutsideAnnularPolygonReturnsFalse() {
        let polygon = HeatMapPolygon(
            id: UUID(), level: 0, threshold: 1.0,
            coordinates: [
                CLLocationCoordinate2D(latitude: 0, longitude: 0),
                CLLocationCoordinate2D(latitude: 0, longitude: 4),
                CLLocationCoordinate2D(latitude: 4, longitude: 4),
                CLLocationCoordinate2D(latitude: 4, longitude: 0),
            ],
            interiorPolygons: [[
                CLLocationCoordinate2D(latitude: 1, longitude: 1),
                CLLocationCoordinate2D(latitude: 1, longitude: 3),
                CLLocationCoordinate2D(latitude: 3, longitude: 3),
                CLLocationCoordinate2D(latitude: 3, longitude: 1),
            ]]
        )
        let outsidePoint = CLLocationCoordinate2D(latitude: 5, longitude: 5)
        #expect(!polygon.contains(outsidePoint))
    }

    @Test func noHolesBackwardCompatible() {
        let polygon = HeatMapPolygon(
            id: UUID(), level: 0, threshold: 1.0,
            coordinates: [
                CLLocationCoordinate2D(latitude: 0, longitude: 0),
                CLLocationCoordinate2D(latitude: 0, longitude: 2),
                CLLocationCoordinate2D(latitude: 2, longitude: 2),
                CLLocationCoordinate2D(latitude: 2, longitude: 0),
            ]
        )
        let inside = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        #expect(polygon.contains(inside))
    }

    @Test func separatedClustersHitTestIndependent() {
        let contours = HeatMapContours.compute(from: separatedClusters)
        // Point inside SF cluster
        let sfPoint = CLLocationCoordinate2D(latitude: 37.775, longitude: -122.4187)
        // Point inside Oakland cluster
        let oaklandPoint = CLLocationCoordinate2D(latitude: 37.8047, longitude: -122.2716)
        let sfHit = contours.contours(containing: sfPoint)
        let oaklandHit = contours.contours(containing: oaklandPoint)
        // The SF polygons should not contain the Oakland point and vice versa
        let sfIDs = Set(sfHit.map(\.id))
        let oaklandIDs = Set(oaklandHit.map(\.id))
        #expect(sfIDs.isDisjoint(with: oaklandIDs))
    }
}
