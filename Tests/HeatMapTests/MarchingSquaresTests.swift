import CoreLocation
import Testing
@testable import HeatMap

struct MarchingSquaresTests {

    let defaultConfig = HeatMapConfiguration()

    /// Generates linearly spaced thresholds matching the old `levels:` behavior.
    private func linearThresholds(for grid: DensityGrid, levels: Int) -> [Double] {
        LevelSpacing.linear.resolveThresholds(
            levels: levels,
            minDensity: grid.minDensity,
            maxDensity: grid.maxDensity
        )
    }

    // MARK: - Empty / Degenerate Input

    @Test func emptyGridReturnsNoPolygons() {
        let grid = DensityGrid.compute(from: [TestPoint](), configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        #expect(result.isEmpty)
    }

    @Test func uniformGridReturnsNoPolygons() {
        // All values identical → range == 0 → no thresholds to cross
        let grid = DensityGrid(
            values: [1, 1, 1, 1],
            rows: 2, columns: 2,
            minLatitude: 37.0, maxLatitude: 38.0,
            minLongitude: -123.0, maxLongitude: -122.0,
            latitudeStep: 1.0, longitudeStep: 1.0,
            minDensity: 1, maxDensity: 1
        )
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        #expect(result.isEmpty)
    }

    @Test func singleCellGridReturnsNoPolygons() {
        let grid = DensityGrid(
            values: [5],
            rows: 1, columns: 1,
            minLatitude: 37.0, maxLatitude: 38.0,
            minLongitude: -123.0, maxLongitude: -122.0,
            latitudeStep: 1.0, longitudeStep: 1.0,
            minDensity: 5, maxDensity: 5
        )
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        #expect(result.isEmpty)
    }

    @Test func emptyThresholdsReturnsNoPolygons() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: [])
        #expect(result.isEmpty)
    }

    // MARK: - Basic Contour Extraction

    @Test func singleLevelProducesPolygons() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 1))
        #expect(!result.isEmpty)
    }

    @Test func multiLevelProducesPolygonsAtMultipleLevels() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        let distinctLevels = Set(result.map(\.level))
        #expect(distinctLevels.count > 1)
    }

    // MARK: - Polygon Validity

    @Test func polygonsHaveAtLeastThreeCoordinates() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        for polygon in result {
            #expect(polygon.coordinates.count >= 3)
        }
    }

    @Test func polygonCoordinatesAreGeographic() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        for polygon in result {
            for coord in polygon.coordinates {
                #expect(coord.latitude >= -90 && coord.latitude <= 90)
                #expect(coord.longitude >= -180 && coord.longitude <= 180)
            }
        }
    }

    @Test func polygonLevelsAreInRange() {
        let levels = 5
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let thresholds = linearThresholds(for: grid, levels: levels)
        let result = MarchingSquares.extractContours(from: grid, thresholds: thresholds)
        for polygon in result {
            #expect(polygon.level >= 0 && polygon.level < levels)
        }
    }

    @Test func polygonThresholdsAreOrdered() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))

        // Group thresholds by level
        var thresholdByLevel: [Int: Double] = [:]
        for polygon in result {
            thresholdByLevel[polygon.level] = polygon.threshold
        }

        let sortedLevels = thresholdByLevel.keys.sorted()
        for i in 1..<sortedLevels.count {
            let prev = thresholdByLevel[sortedLevels[i - 1]]!
            let curr = thresholdByLevel[sortedLevels[i]]!
            #expect(curr > prev)
        }
    }

    @Test func thresholdsBetweenMinAndMax() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        for polygon in result {
            #expect(polygon.threshold > grid.minDensity)
            #expect(polygon.threshold < grid.maxDensity)
        }
    }

    // MARK: - Scaling

    @Test func moreLevelsProduceMoreOrEqualPolygons() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let resultFew = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 3))
        let resultMany = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 10))
        #expect(resultMany.count >= resultFew.count)
    }

    // MARK: - Identity

    @Test func contourPolygonsHaveUniqueIDs() {
        let grid = DensityGrid.compute(from: tightCluster, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        let ids = Set(result.map(\.id))
        #expect(ids.count == result.count)
    }

    // MARK: - Smoke Test

    @Test func contoursFromSeparatedClusters() {
        let grid = DensityGrid.compute(from: separatedClusters, configuration: defaultConfig)
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 5))
        // Two separated clusters should produce multiple polygons at the same level
        #expect(!result.isEmpty)
    }

    // MARK: - Constructed Grid Tests

    @Test func knownGradientProducesContour() {
        // 3x3 grid with a peak in the center
        let grid = DensityGrid(
            values: [
                0, 0, 0,
                0, 10, 0,
                0, 0, 0,
            ],
            rows: 3, columns: 3,
            minLatitude: 37.0, maxLatitude: 38.0,
            minLongitude: -123.0, maxLongitude: -122.0,
            latitudeStep: 0.5, longitudeStep: 0.5,
            minDensity: 0, maxDensity: 10
        )
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 1))
        #expect(!result.isEmpty)
        // The single contour should surround the center cell
        #expect(result[0].coordinates.count >= 3)
    }

    @Test func symmetricPeakProducesClosedContour() {
        // 5x5 grid with symmetric peak
        let values: [Double] = [
            0, 0, 0, 0, 0,
            0, 2, 4, 2, 0,
            0, 4, 8, 4, 0,
            0, 2, 4, 2, 0,
            0, 0, 0, 0, 0,
        ]
        let grid = DensityGrid(
            values: values,
            rows: 5, columns: 5,
            minLatitude: 37.0, maxLatitude: 38.0,
            minLongitude: -123.0, maxLongitude: -122.0,
            latitudeStep: 0.25, longitudeStep: 0.25,
            minDensity: 0, maxDensity: 8
        )
        let result = MarchingSquares.extractContours(from: grid, thresholds: linearThresholds(for: grid, levels: 3))
        #expect(!result.isEmpty)
        // Each polygon should be closed (first ≈ last coordinate not required
        // since assembleRings removes the closing duplicate, but should have ≥ 3 vertices)
        for polygon in result {
            #expect(polygon.coordinates.count >= 3)
        }
    }
}
