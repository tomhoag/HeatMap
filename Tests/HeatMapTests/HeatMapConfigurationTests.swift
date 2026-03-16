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
    }

    @Test func customInitialization() {
        let config = HeatMapConfiguration(
            radius: 300,
            contourLevels: 5,
            gridResolution: 50,
            gradient: .warm,
            paddingFactor: 2.0
        )
        #expect(config.radius == 300)
        #expect(config.contourLevels == 5)
        #expect(config.gridResolution == 50)
        #expect(config.gradient == .warm)
        #expect(config.paddingFactor == 2.0)
    }

    @Test func partialCustomInitialization() {
        let config = HeatMapConfiguration(radius: 200)
        #expect(config.radius == 200)
        #expect(config.contourLevels == 10)
        #expect(config.gridResolution == 100)
        #expect(config.gradient == .thermal)
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
}
