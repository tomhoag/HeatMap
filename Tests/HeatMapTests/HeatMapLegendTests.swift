import SwiftUI
import Testing
@testable import HeatMap

struct HeatMapLegendTests {

    // MARK: - Color Mapping

    @Test func colorForLevelMatchesLayerFormula() {
        let gradient = HeatMapGradient.thermal
        let levelCount = 10

        for level in 0..<levelCount {
            let legendColor = HeatMapLegend.colorForLevel(level, of: levelCount, in: gradient)
            let fraction = Double(level) / Double(levelCount - 1)
            let expectedColor = gradient.color(for: fraction)
            #expect(legendColor == expectedColor)
        }
    }

    @Test func colorForSingleLevelReturnsFirstColor() {
        let color = HeatMapLegend.colorForLevel(0, of: 1, in: .thermal)
        let expected = HeatMapGradient.thermal.colors.first ?? .clear
        #expect(color == expected)
    }

    @Test func colorForLevelWorksWithAllBuiltInGradients() {
        let gradients: [HeatMapGradient] = [.thermal, .warm, .cool, .monochrome(.red)]
        for gradient in gradients {
            let low = HeatMapLegend.colorForLevel(0, of: 5, in: gradient)
            let high = HeatMapLegend.colorForLevel(4, of: 5, in: gradient)
            #expect(low != high)
        }
    }

    @Test func colorForLevelProducesDistinctColors() {
        let gradient = HeatMapGradient.thermal
        let levelCount = 10
        var colors: [Color] = []
        for level in 0..<levelCount {
            colors.append(HeatMapLegend.colorForLevel(level, of: levelCount, in: gradient))
        }
        // At minimum, first and last should differ
        #expect(colors.first != colors.last)
    }

    @Test func colorForLevelEndpointsMatchGradient() {
        let gradient = HeatMapGradient.thermal
        let levelCount = 8
        let first = HeatMapLegend.colorForLevel(0, of: levelCount, in: gradient)
        let last = HeatMapLegend.colorForLevel(levelCount - 1, of: levelCount, in: gradient)
        #expect(first == gradient.color(for: 0))
        #expect(last == gradient.color(for: 1))
    }

    // MARK: - View Initialization

    @MainActor
    @Test func legendFromGradientCreatesView() {
        let legend = HeatMapLegend(gradient: .thermal, levelCount: 12)
        _ = legend.body
    }

    @MainActor
    @Test func legendFromGradientClampsLevelCountToMinimumOne() {
        let legend = HeatMapLegend(gradient: .thermal, levelCount: 0)
        _ = legend.body
    }

    @MainActor
    @Test func legendFromContoursCreatesView() {
        let contours = HeatMapContours.compute(
            from: tightCluster,
            configuration: HeatMapConfiguration(
                contourLevels: 8,
                gradient: .cool
            )
        )
        let legend = HeatMapLegend(contours: contours)
        _ = legend.body
    }

    @MainActor
    @Test func axisModifierDoesNotCrash() {
        let legend = HeatMapLegend(gradient: .thermal, levelCount: 10)
            .axis(.horizontal)
        _ = legend.body
    }

    @MainActor
    @Test func labelsModifierDoesNotCrash() {
        let legend = HeatMapLegend(gradient: .thermal, levelCount: 10)
            .labels(.hidden)
        _ = legend.body
    }
}
