import CoreLocation
import Testing
@testable import HeatMap

struct DensityGridTests {

    let defaultConfig = HeatMapConfiguration()

    // MARK: - Empty / Degenerate Input

    @Test func emptyPointsReturnsEmptyGrid() {
        let grid = DensityGrid.compute(from: [TestPoint](), configuration: defaultConfig)
        #expect(grid.rows == 0)
        #expect(grid.columns == 0)
        #expect(grid.values.isEmpty)
        #expect(grid.minDensity == 0)
        #expect(grid.maxDensity == 0)
    }

    // MARK: - Single Point

    @Test func singlePointProducesNonZeroDensity() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)
        #expect(grid.rows >= 2)
        #expect(grid.columns >= 2)
        #expect(grid.maxDensity > 0)
    }

    @Test func singlePointPeakNearCenter() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)

        // Find the cell with the maximum density
        var maxVal = 0.0
        var maxRow = 0
        var maxCol = 0
        for row in 0..<grid.rows {
            for col in 0..<grid.columns {
                let v = grid.value(row: row, col: col)
                if v > maxVal {
                    maxVal = v
                    maxRow = row
                    maxCol = col
                }
            }
        }

        // The peak should be roughly in the center half of the grid
        let rowFraction = Double(maxRow) / Double(grid.rows)
        let colFraction = Double(maxCol) / Double(grid.columns)
        #expect(rowFraction > 0.25 && rowFraction < 0.75)
        #expect(colFraction > 0.25 && colFraction < 0.75)
    }

    // MARK: - Grid Dimensions

    @Test func gridDimensionsRespectResolution() {
        let config = HeatMapConfiguration(gridResolution: 50)
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: config)
        // For a single point, bounding box is a square after padding, so both axes = resolution
        #expect(grid.rows == 50 || grid.columns == 50)
    }

    @Test func gridDimensionsMinimumTwo() {
        let config = HeatMapConfiguration(gridResolution: 2)
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: config)
        #expect(grid.rows >= 2)
        #expect(grid.columns >= 2)
    }

    // MARK: - Weight

    @Test func higherWeightProducesHigherDensity() {
        let light = TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 1.0)
        let heavy = TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 5.0)

        let gridLight = DensityGrid.compute(from: [light], configuration: defaultConfig)
        let gridHeavy = DensityGrid.compute(from: [heavy], configuration: defaultConfig)

        // maxDensity scales linearly with weight
        let ratio = gridHeavy.maxDensity / gridLight.maxDensity
        #expect(abs(ratio - 5.0) < 0.01)
    }

    // MARK: - Padding

    @Test func paddingExpandsBoundingBox() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)
        #expect(grid.minLatitude < sanFrancisco.coordinate.latitude)
        #expect(grid.maxLatitude > sanFrancisco.coordinate.latitude)
        #expect(grid.minLongitude < sanFrancisco.coordinate.longitude)
        #expect(grid.maxLongitude > sanFrancisco.coordinate.longitude)
    }

    @Test func paddingFactorAffectsBounds() {
        let configSmall = HeatMapConfiguration(paddingFactor: 1.0)
        let configLarge = HeatMapConfiguration(paddingFactor: 3.0)

        let gridSmall = DensityGrid.compute(from: [sanFrancisco], configuration: configSmall)
        let gridLarge = DensityGrid.compute(from: [sanFrancisco], configuration: configLarge)

        let latRangeSmall = gridSmall.maxLatitude - gridSmall.minLatitude
        let latRangeLarge = gridLarge.maxLatitude - gridLarge.minLatitude
        #expect(latRangeLarge > latRangeSmall)
    }

    // MARK: - value(row:col:)

    @Test func valueOutOfBoundsReturnsZero() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)
        #expect(grid.value(row: -1, col: 0) == 0)
        #expect(grid.value(row: 0, col: -1) == 0)
        #expect(grid.value(row: grid.rows, col: 0) == 0)
        #expect(grid.value(row: 0, col: grid.columns) == 0)
    }

    @Test func valueInBoundsReturnsPositive() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)
        var foundPositive = false
        for row in 0..<grid.rows {
            for col in 0..<grid.columns {
                if grid.value(row: row, col: col) > 0 {
                    foundPositive = true
                    break
                }
            }
            if foundPositive { break }
        }
        #expect(foundPositive)
    }

    // MARK: - coordinate(row:col:)

    @Test func coordinateAtOrigin() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)
        let origin = grid.coordinate(row: 0, col: 0)
        #expect(abs(origin.latitude - grid.minLatitude) < 1e-6)
        #expect(abs(origin.longitude - grid.minLongitude) < 1e-6)
    }

    @Test func coordinateMonotonicity() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)
        let a = grid.coordinate(row: 0, col: 0)
        let b = grid.coordinate(row: 1, col: 0)
        let c = grid.coordinate(row: 0, col: 1)
        #expect(b.latitude > a.latitude)
        #expect(c.longitude > a.longitude)
    }

    // MARK: - Density Behavior

    @Test func densityDecaysWithDistance() {
        let grid = DensityGrid.compute(from: [sanFrancisco], configuration: defaultConfig)

        // Find the peak cell
        var maxVal = 0.0
        var maxRow = 0
        var maxCol = 0
        for row in 0..<grid.rows {
            for col in 0..<grid.columns {
                let v = grid.value(row: row, col: col)
                if v > maxVal {
                    maxVal = v
                    maxRow = row
                    maxCol = col
                }
            }
        }

        // A cell 5 steps away should have a lower density
        let offset = min(5, grid.rows - maxRow - 1)
        guard offset > 0 else { return }
        let farValue = grid.value(row: maxRow + offset, col: maxCol)
        #expect(farValue < maxVal)
    }

    @Test func multiplePointsProduceHigherDensityThanSingle() {
        let single = [TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 1.0)]
        let triple = [
            TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 1.0),
            TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 1.0),
            TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 1.0),
        ]

        let gridSingle = DensityGrid.compute(from: single, configuration: defaultConfig)
        let gridTriple = DensityGrid.compute(from: triple, configuration: defaultConfig)
        #expect(gridTriple.maxDensity > gridSingle.maxDensity)
    }

    @Test func collocatedPointsDensityEqualsSum() {
        let twoPoints = [
            TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 3.0),
            TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 4.0),
        ]
        let onePoint = [
            TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 7.0),
        ]

        let gridTwo = DensityGrid.compute(from: twoPoints, configuration: defaultConfig)
        let gridOne = DensityGrid.compute(from: onePoint, configuration: defaultConfig)

        #expect(abs(gridTwo.maxDensity - gridOne.maxDensity) < 1e-6)
    }

    @Test func radiusAffectsSpread() {
        // A narrower radius concentrates density more, resulting in a higher
        // peak value for the same weight. A wider radius spreads the density
        // over a larger area, producing a lower peak.
        let configNarrow = HeatMapConfiguration(radius: 100)
        let configWide = HeatMapConfiguration(radius: 1000)

        let gridNarrow = DensityGrid.compute(from: [sanFrancisco], configuration: configNarrow)
        let gridWide = DensityGrid.compute(from: [sanFrancisco], configuration: configWide)

        #expect(gridNarrow.maxDensity > gridWide.maxDensity)
    }
}
