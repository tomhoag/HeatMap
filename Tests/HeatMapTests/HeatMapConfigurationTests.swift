import Testing
@testable import HeatMap

struct HeatMapConfigurationTests {

    @Test func defaultValues() {
        let config = HeatMapConfiguration()
        #expect(config.radius == 500)
        #expect(config.contourLevels == 10)
        #expect(config.levelSpacing == .auto)
        #expect(config.gridResolution == 100)
        #expect(config.paddingFactor == 1.5)
    }

    @Test func customInitialization() {
        let config = HeatMapConfiguration(
            radius: 300,
            contourLevels: 5,
            levelSpacing: .logarithmic,
            gridResolution: 50,
            paddingFactor: 2.0
        )
        #expect(config.radius == 300)
        #expect(config.contourLevels == 5)
        #expect(config.levelSpacing == .logarithmic)
        #expect(config.gridResolution == 50)
        #expect(config.paddingFactor == 2.0)
    }

    @Test func partialCustomInitialization() {
        let config = HeatMapConfiguration(radius: 200)
        #expect(config.radius == 200)
        #expect(config.contourLevels == 10)
        #expect(config.gridResolution == 100)
        #expect(config.paddingFactor == 1.5)
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

    // MARK: - LevelSpacing

    @Test func customSpacingOverridesContourLevels() {
        let config = HeatMapConfiguration(
            contourLevels: 10,
            levelSpacing: .custom([1.0, 2.0, 3.0])
        )
        #expect(config.contourLevels == 3)
        #expect(config.levelSpacing == .custom([1.0, 2.0, 3.0]))
    }

    @Test func emptyCustomSpacingKeepsContourLevels() {
        let config = HeatMapConfiguration(
            contourLevels: 10,
            levelSpacing: .custom([])
        )
        #expect(config.contourLevels == 10)
    }

    @Test func levelSpacingHashableEquality() {
        let a = HeatMapConfiguration(levelSpacing: .logarithmic)
        let b = HeatMapConfiguration(levelSpacing: .logarithmic)
        #expect(a == b)
    }

    @Test func levelSpacingHashableInequality() {
        let a = HeatMapConfiguration(levelSpacing: .linear)
        let b = HeatMapConfiguration(levelSpacing: .logarithmic)
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test func descriptionContainsAllFields() {
        let config = HeatMapConfiguration()
        let desc = String(describing: config)
        #expect(desc.contains("radius: 500.0m"))
        #expect(desc.contains("levels: 10"))
        #expect(desc.contains("spacing: auto"))
        #expect(desc.contains("grid: 100"))
        #expect(desc.contains("padding: 1.5"))
        #expect(desc.contains("smoother: chaikin(2)"))
    }

    @Test func descriptionReflectsCustomValues() {
        let config = HeatMapConfiguration(
            radius: 300,
            contourLevels: 5,
            levelSpacing: .logarithmic,
            gridResolution: 50,
            smoother: .none
        )
        let desc = String(describing: config)
        #expect(desc.contains("radius: 300.0m"))
        #expect(desc.contains("levels: 5"))
        #expect(desc.contains("spacing: logarithmic"))
        #expect(desc.contains("grid: 50"))
        #expect(desc.contains("smoother: none"))
    }
}
