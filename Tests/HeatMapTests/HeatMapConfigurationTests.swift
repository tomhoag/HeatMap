import Testing
@testable import HeatMap

struct HeatMapConfigurationTests {

    @Test func defaultValues() {
        let config = HeatMapConfiguration()
        #expect(config.radius == 500)
        #expect(config.contourLevels == 10)
        #expect(config.gridResolution == 100)
        #expect(config.gradient == .thermal)
        #expect(config.paddingFactor == 1.5)
        #expect(config.fillOpacity == 1.0)
    }

    @Test func customInitialization() {
        let config = HeatMapConfiguration(
            radius: 300,
            contourLevels: 5,
            gridResolution: 50,
            gradient: .warm,
            paddingFactor: 2.0,
            fillOpacity: 0.7
        )
        #expect(config.radius == 300)
        #expect(config.contourLevels == 5)
        #expect(config.gridResolution == 50)
        #expect(config.gradient == .warm)
        #expect(config.paddingFactor == 2.0)
        #expect(config.fillOpacity == 0.7)
    }

    @Test func partialCustomInitialization() {
        let config = HeatMapConfiguration(radius: 200)
        #expect(config.radius == 200)
        #expect(config.contourLevels == 10)
        #expect(config.gridResolution == 100)
        #expect(config.gradient == .thermal)
        #expect(config.paddingFactor == 1.5)
        #expect(config.fillOpacity == 1.0)
    }

    @Test func hashableEquality() {
        let a = HeatMapConfiguration()
        let b = HeatMapConfiguration()
        #expect(a == b)
    }

    @Test func hashableInequality() {
        let a = HeatMapConfiguration(radius: 100)
        let b = HeatMapConfiguration(radius: 200)
        #expect(a != b)
    }

    @Test func usableAsSetElement() {
        let a = HeatMapConfiguration()
        let b = HeatMapConfiguration()
        let c = HeatMapConfiguration(radius: 100)
        let set: Set<HeatMapConfiguration> = [a, b, c]
        #expect(set.count == 2)
    }

    @Test func usableAsDictionaryKey() {
        let config = HeatMapConfiguration(radius: 300)
        let dict: [HeatMapConfiguration: String] = [config: "test"]
        #expect(dict[HeatMapConfiguration(radius: 300)] == "test")
    }

    @Test func mutability() {
        var config = HeatMapConfiguration()
        config.radius = 999
        #expect(config.radius == 999)
    }

    @Test func radiusClampsToMinimum() {
        let config = HeatMapConfiguration(radius: -10)
        #expect(config.radius == 1)
    }

    @Test func contourLevelsClampsToMinimum() {
        let config = HeatMapConfiguration(contourLevels: 0)
        #expect(config.contourLevels == 1)
    }

    @Test func gridResolutionClampsToMinimum() {
        let config = HeatMapConfiguration(gridResolution: 1)
        #expect(config.gridResolution == 2)
    }

    @Test func paddingFactorClampsToMinimum() {
        let config = HeatMapConfiguration(paddingFactor: -0.5)
        #expect(config.paddingFactor == 0)
    }

    @Test func fillOpacityClampsToMinimum() {
        let config = HeatMapConfiguration(fillOpacity: -0.5)
        #expect(config.fillOpacity == 0)
    }

    @Test func fillOpacityClampsToMaximum() {
        let config = HeatMapConfiguration(fillOpacity: 2.0)
        #expect(config.fillOpacity == 1.0)
    }

    // MARK: - CustomStringConvertible

    @Test func descriptionContainsAllFields() {
        let config = HeatMapConfiguration()
        let desc = String(describing: config)
        #expect(desc.contains("radius: 500.0m"))
        #expect(desc.contains("levels: 10"))
        #expect(desc.contains("grid: 100"))
        #expect(desc.contains("gradient: HeatMapGradient.thermal"))
        #expect(desc.contains("padding: 1.5"))
        #expect(desc.contains("fillOpacity: 1.0"))
        #expect(desc.contains("smoother: chaikin(2)"))
    }

    @Test func descriptionReflectsCustomValues() {
        let config = HeatMapConfiguration(
            radius: 300,
            contourLevels: 5,
            gridResolution: 50,
            gradient: .cool,
            fillOpacity: 0.5,
            smoother: .none
        )
        let desc = String(describing: config)
        #expect(desc.contains("radius: 300.0m"))
        #expect(desc.contains("levels: 5"))
        #expect(desc.contains("grid: 50"))
        #expect(desc.contains("gradient: HeatMapGradient.cool"))
        #expect(desc.contains("fillOpacity: 0.5"))
        #expect(desc.contains("smoother: none"))
    }
}
