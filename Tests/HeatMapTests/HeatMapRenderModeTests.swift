import SwiftUI
import Testing
@testable import HeatMap

struct HeatMapRenderModeTests {

    // MARK: - Equality

    @Test func filledEquality() {
        #expect(HeatMapRenderMode.filled == .filled)
    }

    @Test func isolinesEquality() {
        #expect(HeatMapRenderMode.isolines(lineWidth: 2) == .isolines(lineWidth: 2))
    }

    @Test func filledWithIsolinesEquality() {
        #expect(HeatMapRenderMode.filledWithIsolines(lineWidth: 3) == .filledWithIsolines(lineWidth: 3))
    }

    @Test func isolinesInequality() {
        #expect(HeatMapRenderMode.isolines(lineWidth: 1) != .isolines(lineWidth: 2))
    }

    @Test func filledWithIsolinesInequality() {
        #expect(HeatMapRenderMode.filledWithIsolines(lineWidth: 1) != .filledWithIsolines(lineWidth: 2))
    }

    @Test func differentCasesNotEqual() {
        #expect(HeatMapRenderMode.filled != .isolines())
        #expect(HeatMapRenderMode.filled != .filledWithIsolines())
        #expect(HeatMapRenderMode.isolines() != .filledWithIsolines())
    }

    // MARK: - Defaults

    @Test func isolinesDefaultLineWidthIsOne() {
        if case .isolines(let lw, _) = HeatMapRenderMode.isolines() {
            #expect(lw == 1)
        } else {
            Issue.record("Expected .isolines case")
        }
    }

    @Test func filledWithIsolinesDefaultLineWidthIsOne() {
        if case .filledWithIsolines(let lw, _) = HeatMapRenderMode.filledWithIsolines() {
            #expect(lw == 1)
        } else {
            Issue.record("Expected .filledWithIsolines case")
        }
    }

    @Test func isolinesDefaultColorIsNil() {
        if case .isolines(_, let color) = HeatMapRenderMode.isolines() {
            #expect(color == nil)
        } else {
            Issue.record("Expected .isolines case")
        }
    }

    @Test func filledWithIsolinesDefaultColorIsNil() {
        if case .filledWithIsolines(_, let color) = HeatMapRenderMode.filledWithIsolines() {
            #expect(color == nil)
        } else {
            Issue.record("Expected .filledWithIsolines case")
        }
    }

    // MARK: - Color

    @Test func isolinesWithColorEquality() {
        #expect(
            HeatMapRenderMode.isolines(color: .black)
                == .isolines(color: .black)
        )
    }

    @Test func isolinesWithDifferentColorsNotEqual() {
        #expect(
            HeatMapRenderMode.isolines(color: .black)
                != .isolines(color: .white)
        )
    }

    @Test func isolinesWithColorNotEqualToWithoutColor() {
        #expect(
            HeatMapRenderMode.isolines(color: .black)
                != .isolines()
        )
    }

    @Test func filledWithIsolinesWithColorEquality() {
        #expect(
            HeatMapRenderMode.filledWithIsolines(color: .red)
                == .filledWithIsolines(color: .red)
        )
    }

    // MARK: - CustomStringConvertible

    @Test func filledDescription() {
        #expect(String(describing: HeatMapRenderMode.filled) == "filled")
    }

    @Test func isolinesDescription() {
        let desc = String(describing: HeatMapRenderMode.isolines(lineWidth: 2))
        #expect(desc.contains("isolines"))
        #expect(desc.contains("2.0"))
    }

    @Test func isolinesWithColorDescription() {
        let desc = String(describing: HeatMapRenderMode.isolines(color: .black))
        #expect(desc.contains("isolines"))
    }

    @Test func filledWithIsolinesDescription() {
        let desc = String(describing: HeatMapRenderMode.filledWithIsolines(lineWidth: 3))
        #expect(desc.contains("filledWithIsolines"))
        #expect(desc.contains("3.0"))
    }

    // MARK: - Hashable

    @Test func usableAsSetElement() {
        let set: Set<HeatMapRenderMode> = [.filled, .isolines(), .filledWithIsolines()]
        #expect(set.count == 3)
    }

    @Test func usableAsDictionaryKey() {
        let dict: [HeatMapRenderMode: String] = [.filled: "a", .isolines(): "b"]
        #expect(dict[.filled] == "a")
        #expect(dict[.isolines()] == "b")
    }

    @Test func coloredIsolinesDistinctInSet() {
        let set: Set<HeatMapRenderMode> = [.isolines(), .isolines(color: .black)]
        #expect(set.count == 2)
    }
}
