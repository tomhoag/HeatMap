import SwiftUI
import Testing
@testable import HeatMap

struct HeatMapConfigurationTests {

    @Test func defaultValues() {
        let config = HeatMapConfiguration()
        #expect(config.radius == 500)
        #expect(config.contourLevels == 10)
        #expect(config.levelSpacing == .linear)
        #expect(config.gridResolution == 100)
        #expect(config.gradient == .thermal)
        #expect(config.paddingFactor == 1.5)
        #expect(config.fillOpacity == 1.0)
        #expect(config.renderMode == .filled)
    }

    @Test func customInitialization() {
        let config = HeatMapConfiguration(
            radius: 300,
            contourLevels: 5,
            levelSpacing: .logarithmic,
            gridResolution: 50,
            gradient: .warm,
            paddingFactor: 2.0,
            fillOpacity: 0.7,
            renderMode: .isolines(lineWidth: 2)
        )
        #expect(config.radius == 300)
        #expect(config.contourLevels == 5)
        #expect(config.levelSpacing == .logarithmic)
        #expect(config.gridResolution == 50)
        #expect(config.gradient == .warm)
        #expect(config.paddingFactor == 2.0)
        #expect(config.fillOpacity == 0.7)
        #expect(config.renderMode == .isolines(lineWidth: 2))
    }

    @Test func partialCustomInitialization() {
        let config = HeatMapConfiguration(radius: 200)
        #expect(config.radius == 200)
        #expect(config.contourLevels == 10)
        #expect(config.gridResolution == 100)
        #expect(config.gradient == .thermal)
        #expect(config.paddingFactor == 1.5)
        #expect(config.fillOpacity == 1.0)
        #expect(config.renderMode == .filled)
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

    // MARK: - RenderMode

    @Test func renderModeHashableEquality() {
        let a = HeatMapConfiguration(renderMode: .isolines(lineWidth: 1))
        let b = HeatMapConfiguration(renderMode: .isolines(lineWidth: 1))
        #expect(a == b)
    }

    @Test func renderModeHashableInequality() {
        let a = HeatMapConfiguration(renderMode: .filled)
        let b = HeatMapConfiguration(renderMode: .isolines())
        #expect(a != b)
    }

    @Test func renderModeIsolinesDifferentLineWidth() {
        let a = HeatMapConfiguration(renderMode: .isolines(lineWidth: 1))
        let b = HeatMapConfiguration(renderMode: .isolines(lineWidth: 3))
        #expect(a != b)
    }

    @Test func renderModeIsolinesWithColor() {
        let config = HeatMapConfiguration(renderMode: .isolines(color: .black))
        #expect(config.renderMode == .isolines(color: .black))
    }

    @Test func renderModeIsolinesColorInequality() {
        let a = HeatMapConfiguration(renderMode: .isolines(color: .black))
        let b = HeatMapConfiguration(renderMode: .isolines())
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test func descriptionContainsAllFields() {
        let config = HeatMapConfiguration()
        let desc = String(describing: config)
        #expect(desc.contains("radius: 500.0m"))
        #expect(desc.contains("levels: 10"))
        #expect(desc.contains("spacing: linear"))
        #expect(desc.contains("grid: 100"))
        #expect(desc.contains("gradient: HeatMapGradient.thermal"))
        #expect(desc.contains("padding: 1.5"))
        #expect(desc.contains("fillOpacity: 1.0"))
        #expect(desc.contains("renderMode: filled"))
        #expect(desc.contains("smoother: chaikin(2)"))
    }

    @Test func descriptionReflectsCustomValues() {
        let config = HeatMapConfiguration(
            radius: 300,
            contourLevels: 5,
            levelSpacing: .logarithmic,
            gridResolution: 50,
            gradient: .cool,
            fillOpacity: 0.5,
            renderMode: .isolines(lineWidth: 2),
            smoother: .none
        )
        let desc = String(describing: config)
        #expect(desc.contains("radius: 300.0m"))
        #expect(desc.contains("levels: 5"))
        #expect(desc.contains("spacing: logarithmic"))
        #expect(desc.contains("grid: 50"))
        #expect(desc.contains("gradient: HeatMapGradient.cool"))
        #expect(desc.contains("fillOpacity: 0.5"))
        #expect(desc.contains("renderMode: isolines(2.0pt)"))
        #expect(desc.contains("smoother: none"))
    }
}
