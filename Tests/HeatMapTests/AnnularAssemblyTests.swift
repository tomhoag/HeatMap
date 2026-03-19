import CoreLocation
import Testing
@testable import HeatMap

struct AnnularAssemblyTests {

    // MARK: - Helpers

    private func makeSquare(
        center: (lat: Double, lon: Double),
        size: Double,
        level: Int,
        threshold: Double
    ) -> HeatMapPolygon {
        let half = size / 2
        return HeatMapPolygon(
            level: level,
            threshold: threshold,
            coordinates: [
                CLLocationCoordinate2D(latitude: center.lat - half, longitude: center.lon - half),
                CLLocationCoordinate2D(latitude: center.lat - half, longitude: center.lon + half),
                CLLocationCoordinate2D(latitude: center.lat + half, longitude: center.lon + half),
                CLLocationCoordinate2D(latitude: center.lat + half, longitude: center.lon - half),
            ]
        )
    }

    // MARK: - Basic Cases

    @Test func emptyInputReturnsEmpty() {
        let result = AnnularAssembly.assembleAnnular([])
        #expect(result.isEmpty)
    }

    @Test func singleLevelHasNoHoles() {
        let polygon = makeSquare(center: (1, 1), size: 2, level: 0, threshold: 1.0)
        let result = AnnularAssembly.assembleAnnular([polygon])
        #expect(result.count == 1)
        #expect(result[0].interiorPolygons.isEmpty)
    }

    @Test func twoNestedLevelsCreatesHole() {
        let outer = makeSquare(center: (1, 1), size: 4, level: 0, threshold: 1.0)
        let inner = makeSquare(center: (1, 1), size: 2, level: 1, threshold: 2.0)
        let result = AnnularAssembly.assembleAnnular([outer, inner])

        #expect(result.count == 2)

        let level0 = result.first { $0.level == 0 }!
        #expect(level0.interiorPolygons.count == 1)

        let level1 = result.first { $0.level == 1 }!
        #expect(level1.interiorPolygons.isEmpty)
    }

    @Test func threeLevelNesting() {
        let l0 = makeSquare(center: (5, 5), size: 6, level: 0, threshold: 1.0)
        let l1 = makeSquare(center: (5, 5), size: 4, level: 1, threshold: 2.0)
        let l2 = makeSquare(center: (5, 5), size: 2, level: 2, threshold: 3.0)
        let result = AnnularAssembly.assembleAnnular([l0, l1, l2])

        let r0 = result.first { $0.level == 0 }!
        let r1 = result.first { $0.level == 1 }!
        let r2 = result.first { $0.level == 2 }!

        #expect(r0.interiorPolygons.count == 1)
        #expect(r1.interiorPolygons.count == 1)
        #expect(r2.interiorPolygons.isEmpty)
    }

    // MARK: - Disconnected Regions

    @Test func disconnectedRegionsGetCorrectHoles() {
        let outerA = makeSquare(center: (0, 0), size: 4, level: 0, threshold: 1.0)
        let outerB = makeSquare(center: (10, 10), size: 4, level: 0, threshold: 1.0)
        let innerA = makeSquare(center: (0, 0), size: 2, level: 1, threshold: 2.0)
        let innerB = makeSquare(center: (10, 10), size: 2, level: 1, threshold: 2.0)

        let result = AnnularAssembly.assembleAnnular([outerA, outerB, innerA, innerB])

        let level0s = result.filter { $0.level == 0 }
        #expect(level0s.count == 2)
        for outer in level0s {
            #expect(outer.interiorPolygons.count == 1)
        }

        let level1s = result.filter { $0.level == 1 }
        #expect(level1s.count == 2)
        for inner in level1s {
            #expect(inner.interiorPolygons.isEmpty)
        }
    }

    // MARK: - Identity Preservation

    @Test func preservesPolygonIdentity() {
        let outer = makeSquare(center: (1, 1), size: 4, level: 0, threshold: 1.0)
        let inner = makeSquare(center: (1, 1), size: 2, level: 1, threshold: 2.0)
        let result = AnnularAssembly.assembleAnnular([outer, inner])

        #expect(result.first { $0.level == 0 }?.id == outer.id)
        #expect(result.first { $0.level == 1 }?.id == inner.id)
    }

    @Test func preservesCoordinates() {
        let outer = makeSquare(center: (1, 1), size: 4, level: 0, threshold: 1.0)
        let inner = makeSquare(center: (1, 1), size: 2, level: 1, threshold: 2.0)
        let result = AnnularAssembly.assembleAnnular([outer, inner])

        let r0 = result.first { $0.level == 0 }!
        #expect(r0.coordinates.count == outer.coordinates.count)
    }

    // MARK: - Integration with Real Contours

    @Test func innermostLevelHasNoHoles() {
        let config = HeatMapConfiguration(contourLevels: 5)
        let contours = HeatMapContours.compute(from: tightCluster, configuration: config)
        let maxLevel = contours.contours.map(\.level).max()!
        let innermost = contours.contours.filter { $0.level == maxLevel }
        for polygon in innermost {
            #expect(polygon.interiorPolygons.isEmpty)
        }
    }

    @Test func nonInnermostLevelsHaveHoles() {
        let config = HeatMapConfiguration(contourLevels: 5)
        let contours = HeatMapContours.compute(from: tightCluster, configuration: config)
        let maxLevel = contours.contours.map(\.level).max() ?? 0
        let nonInnermost = contours.contours.filter { $0.level < maxLevel }
        let hasHoles = nonInnermost.contains { !$0.interiorPolygons.isEmpty }
        #expect(hasHoles)
    }
}
