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
        #expect(gradient.colors.count == 2)
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
}
