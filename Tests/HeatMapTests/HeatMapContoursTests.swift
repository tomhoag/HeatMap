import Testing
@testable import HeatMap

struct HeatMapContoursTests {

    let defaultConfig = HeatMapConfiguration()

    @Test func computeFromEmptyPoints() {
        let contours = HeatMapContours.compute(
            from: [TestPoint](),
            configuration: defaultConfig
        )
        #expect(contours.polygons.isEmpty)
    }

    @Test func computeFromCluster() {
        let contours = HeatMapContours.compute(
            from: tightCluster,
            configuration: defaultConfig
        )
        #expect(!contours.polygons.isEmpty)
    }

    @Test func computePreservesLevels() {
        let config = HeatMapConfiguration(contourLevels: 7)
        let contours = HeatMapContours.compute(from: tightCluster, configuration: config)
        #expect(contours.levels == 7)
    }

    @Test func computePreservesGradient() {
        let config = HeatMapConfiguration(gradient: .cool)
        let contours = HeatMapContours.compute(from: tightCluster, configuration: config)
        #expect(contours.gradient == .cool)
    }

    @Test func defaultConfiguration() {
        let contours = HeatMapContours.compute(from: tightCluster)
        #expect(contours.levels == 10)
        #expect(contours.gradient == .thermal)
    }

    // MARK: - Async Compute

    @Test func asyncComputePreservesConfiguration() async {
        let config = HeatMapConfiguration(contourLevels: 5, gradient: .warm)
        let contours = await HeatMapContours.compute(from: tightCluster, configuration: config)
        #expect(contours.levels == 5)
        #expect(contours.gradient == .warm)
        #expect(!contours.polygons.isEmpty)
    }

    @Test func asyncComputeFromEmptyPoints() async {
        let contours = await HeatMapContours.compute(from: [TestPoint]())
        #expect(contours.polygons.isEmpty)
    }
}
