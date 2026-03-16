import SwiftUI
import Testing
@testable import HeatMap

struct HeatMapGradientTests {

    @Test func thermalPresetHasSevenColors() {
        #expect(HeatMapGradient.thermal.colors.count == 7)
    }

    @Test func warmPresetHasFiveColors() {
        #expect(HeatMapGradient.warm.colors.count == 5)
    }

    @Test func coolPresetHasFiveColors() {
        #expect(HeatMapGradient.cool.colors.count == 5)
    }

    @Test func monochromeHasSixColors() {
        #expect(HeatMapGradient.monochrome(.red).colors.count == 6)
    }

    @Test func customGradientPreservesColors() {
        let gradient = HeatMapGradient(colors: [.red, .blue])
        #expect(gradient != nil)
        #expect(gradient!.colors.count == 2)
    }

    @Test func hashableEquality() {
        #expect(HeatMapGradient.thermal == HeatMapGradient.thermal)
    }

    @Test func hashableInequality() {
        #expect(HeatMapGradient.thermal != HeatMapGradient.warm)
    }

    @Test func monochromeWithDifferentColorsNotEqual() {
        #expect(HeatMapGradient.monochrome(.red) != HeatMapGradient.monochrome(.blue))
    }

    // MARK: - color(for:) Interpolation

    @Test func colorForFractionZeroReturnsFirstColor() {
        let gradient = HeatMapGradient(colors: [.red, .blue])!
        let env = EnvironmentValues()
        let result = gradient.color(for: 0).resolve(in: env)
        let expected = Color.red.resolve(in: env)
        #expect(abs(result.red - expected.red) < 0.01)
        #expect(abs(result.green - expected.green) < 0.01)
        #expect(abs(result.blue - expected.blue) < 0.01)
        #expect(abs(result.opacity - expected.opacity) < 0.01)
    }

    @Test func colorForFractionOneReturnsLastColor() {
        let gradient = HeatMapGradient(colors: [.red, .blue])!
        let env = EnvironmentValues()
        let result = gradient.color(for: 1).resolve(in: env)
        let expected = Color.blue.resolve(in: env)
        #expect(abs(result.red - expected.red) < 0.01)
        #expect(abs(result.green - expected.green) < 0.01)
        #expect(abs(result.blue - expected.blue) < 0.01)
        #expect(abs(result.opacity - expected.opacity) < 0.01)
    }

    @Test func colorForFractionMidInterpolates() {
        let gradient = HeatMapGradient(colors: [.red, .blue])!
        let env = EnvironmentValues()
        let result = gradient.color(for: 0.5).resolve(in: env)
        let first = Color.red.resolve(in: env)
        let last = Color.blue.resolve(in: env)
        // Mid-point should differ from both endpoints
        let matchesFirst = abs(result.red - first.red) < 0.01
            && abs(result.blue - first.blue) < 0.01
        let matchesLast = abs(result.red - last.red) < 0.01
            && abs(result.blue - last.blue) < 0.01
        #expect(!matchesFirst)
        #expect(!matchesLast)
    }

    @Test func colorForFractionClampsBelowZero() {
        let gradient = HeatMapGradient(colors: [.red, .blue])!
        let env = EnvironmentValues()
        let atZero = gradient.color(for: 0).resolve(in: env)
        let belowZero = gradient.color(for: -0.5).resolve(in: env)
        #expect(abs(atZero.red - belowZero.red) < 0.01)
        #expect(abs(atZero.blue - belowZero.blue) < 0.01)
    }

    @Test func colorForFractionClampsAboveOne() {
        let gradient = HeatMapGradient(colors: [.red, .blue])!
        let env = EnvironmentValues()
        let atOne = gradient.color(for: 1).resolve(in: env)
        let aboveOne = gradient.color(for: 1.5).resolve(in: env)
        #expect(abs(atOne.red - aboveOne.red) < 0.01)
        #expect(abs(atOne.blue - aboveOne.blue) < 0.01)
    }

    @Test func initWithEmptyColorsReturnsNil() {
        #expect(HeatMapGradient(colors: []) == nil)
    }

    @Test func initWithSingleColorReturnsNil() {
        #expect(HeatMapGradient(colors: [.red]) == nil)
    }
}
