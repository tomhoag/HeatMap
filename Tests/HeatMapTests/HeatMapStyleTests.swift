import SwiftUI
import Testing
@testable import HeatMap

struct HeatMapStyleTests {

    @Test func defaultValues() {
        let style = HeatMapStyle()
        #expect(style.gradient == .thermal)
        #expect(style.fillOpacity == 1.0)
        #expect(style.renderMode == .filled)
    }

    @Test func customInitialization() {
        let style = HeatMapStyle(
            gradient: .cool,
            fillOpacity: 0.7,
            renderMode: .isolines(lineWidth: 2)
        )
        #expect(style.gradient == .cool)
        #expect(style.fillOpacity == 0.7)
        #expect(style.renderMode == .isolines(lineWidth: 2))
    }

    @Test func fillOpacityClampsToMinimum() {
        let style = HeatMapStyle(fillOpacity: -0.5)
        #expect(style.fillOpacity == 0)
    }

    @Test func fillOpacityClampsToMaximum() {
        let style = HeatMapStyle(fillOpacity: 2.0)
        #expect(style.fillOpacity == 1.0)
    }

    @Test func hashableEquality() {
        let a = HeatMapStyle()
        let b = HeatMapStyle()
        #expect(a == b)
    }

    @Test func hashableInequality() {
        let a = HeatMapStyle(gradient: .thermal)
        let b = HeatMapStyle(gradient: .cool)
        #expect(a != b)
    }

    @Test func usableAsSetElement() {
        let a = HeatMapStyle()
        let b = HeatMapStyle()
        let c = HeatMapStyle(gradient: .cool)
        let set: Set<HeatMapStyle> = [a, b, c]
        #expect(set.count == 2)
    }

    @Test func usableAsDictionaryKey() {
        let style = HeatMapStyle(gradient: .warm)
        let dict: [HeatMapStyle: String] = [style: "test"]
        #expect(dict[HeatMapStyle(gradient: .warm)] == "test")
    }

    @Test func mutability() {
        var style = HeatMapStyle()
        style.gradient = .cool
        #expect(style.gradient == .cool)
    }

    // MARK: - RenderMode

    @Test func renderModeHashableEquality() {
        let a = HeatMapStyle(renderMode: .isolines(lineWidth: 1))
        let b = HeatMapStyle(renderMode: .isolines(lineWidth: 1))
        #expect(a == b)
    }

    @Test func renderModeHashableInequality() {
        let a = HeatMapStyle(renderMode: .filled)
        let b = HeatMapStyle(renderMode: .isolines())
        #expect(a != b)
    }

    @Test func renderModeIsolinesDifferentLineWidth() {
        let a = HeatMapStyle(renderMode: .isolines(lineWidth: 1))
        let b = HeatMapStyle(renderMode: .isolines(lineWidth: 3))
        #expect(a != b)
    }

    @Test func renderModeIsolinesWithColor() {
        let style = HeatMapStyle(renderMode: .isolines(color: .black))
        #expect(style.renderMode == .isolines(color: .black))
    }

    @Test func renderModeIsolinesColorInequality() {
        let a = HeatMapStyle(renderMode: .isolines(color: .black))
        let b = HeatMapStyle(renderMode: .isolines())
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test func descriptionContainsAllFields() {
        let style = HeatMapStyle()
        let desc = String(describing: style)
        #expect(desc.contains("gradient: HeatMapGradient.thermal"))
        #expect(desc.contains("fillOpacity: 1.0"))
        #expect(desc.contains("renderMode: filled"))
    }

    @Test func descriptionReflectsCustomValues() {
        let style = HeatMapStyle(
            gradient: .cool,
            fillOpacity: 0.5,
            renderMode: .isolines(lineWidth: 2)
        )
        let desc = String(describing: style)
        #expect(desc.contains("gradient: HeatMapGradient.cool"))
        #expect(desc.contains("fillOpacity: 0.5"))
        #expect(desc.contains("renderMode: isolines(2.0pt)"))
    }
}
