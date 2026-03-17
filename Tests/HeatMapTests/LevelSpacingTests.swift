import Testing
@testable import HeatMap

struct LevelSpacingTests {

    // MARK: - Linear

    @Test func linearProducesEvenlySpacedThresholds() {
        let thresholds = LevelSpacing.linear.resolveThresholds(
            levels: 4, minDensity: 0, maxDensity: 10
        )
        #expect(thresholds.count == 4)
        let expected = [2.0, 4.0, 6.0, 8.0]
        for (i, exp) in expected.enumerated() {
            #expect(abs(thresholds[i] - exp) < 1e-10)
        }
    }

    @Test func linearMatchesOldBehavior() {
        let thresholds = LevelSpacing.linear.resolveThresholds(
            levels: 5, minDensity: 1, maxDensity: 11
        )
        #expect(thresholds.count == 5)
        let expected = (0..<5).map { level in
            1.0 + 10.0 * Double(level + 1) / 6.0
        }
        for (i, exp) in expected.enumerated() {
            #expect(abs(thresholds[i] - exp) < 1e-10)
        }
    }

    // MARK: - Logarithmic

    @Test func logarithmicProducesNonLinearThresholds() {
        let thresholds = LevelSpacing.logarithmic.resolveThresholds(
            levels: 4, minDensity: 0, maxDensity: 100
        )
        #expect(thresholds.count == 4)
        // Gaps between consecutive thresholds should increase
        let gaps = zip(thresholds, thresholds.dropFirst()).map { $1 - $0 }
        #expect(gaps.last! > gaps.first!)
    }

    @Test func logarithmicThresholdsAreWithinRange() {
        let thresholds = LevelSpacing.logarithmic.resolveThresholds(
            levels: 10, minDensity: 5, maxDensity: 100
        )
        for t in thresholds {
            #expect(t > 5)
            #expect(t < 100)
        }
    }

    @Test func logarithmicThresholdsAreSorted() {
        let thresholds = LevelSpacing.logarithmic.resolveThresholds(
            levels: 10, minDensity: 0, maxDensity: 100
        )
        for i in 1..<thresholds.count {
            #expect(thresholds[i] > thresholds[i - 1])
        }
    }

    // MARK: - Custom

    @Test func customFiltersOutOfRangeThresholds() {
        let thresholds = LevelSpacing.custom([0.5, 2.0, 5.0, 15.0, 20.0])
            .resolveThresholds(levels: 0, minDensity: 1.0, maxDensity: 10.0)
        #expect(thresholds == [2.0, 5.0])
    }

    @Test func customSortsThresholds() {
        let thresholds = LevelSpacing.custom([5.0, 1.0, 3.0])
            .resolveThresholds(levels: 0, minDensity: 0, maxDensity: 10)
        #expect(thresholds == [1.0, 3.0, 5.0])
    }

    @Test func customDeduplicatesThresholds() {
        let thresholds = LevelSpacing.custom([2.0, 2.0, 5.0, 5.0])
            .resolveThresholds(levels: 0, minDensity: 0, maxDensity: 10)
        #expect(thresholds == [2.0, 5.0])
    }

    @Test func customEmptyReturnsEmpty() {
        let thresholds = LevelSpacing.custom([])
            .resolveThresholds(levels: 0, minDensity: 0, maxDensity: 10)
        #expect(thresholds.isEmpty)
    }

    @Test func customAllOutOfRangeReturnsEmpty() {
        let thresholds = LevelSpacing.custom([0.0, 10.0, 20.0])
            .resolveThresholds(levels: 0, minDensity: 0, maxDensity: 10)
        #expect(thresholds.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func zeroRangeReturnsEmpty() {
        let thresholds = LevelSpacing.linear.resolveThresholds(
            levels: 5, minDensity: 5, maxDensity: 5
        )
        #expect(thresholds.isEmpty)
    }

    @Test func zeroLevelsReturnsEmpty() {
        let thresholds = LevelSpacing.linear.resolveThresholds(
            levels: 0, minDensity: 0, maxDensity: 10
        )
        #expect(thresholds.isEmpty)
    }

    @Test func singleLevelLinear() {
        let thresholds = LevelSpacing.linear.resolveThresholds(
            levels: 1, minDensity: 0, maxDensity: 10
        )
        #expect(thresholds.count == 1)
        #expect(abs(thresholds[0] - 5.0) < 1e-10)
    }

    @Test func singleLevelLogarithmic() {
        let thresholds = LevelSpacing.logarithmic.resolveThresholds(
            levels: 1, minDensity: 0, maxDensity: 10
        )
        #expect(thresholds.count == 1)
        // With base=2, fraction=0.5: (2^0.5 - 1) / 1 ≈ 0.414
        #expect(thresholds[0] > 0)
        #expect(thresholds[0] < 10)
    }

    // MARK: - CustomStringConvertible

    @Test func linearDescription() {
        #expect(String(describing: LevelSpacing.linear) == "linear")
    }

    @Test func logarithmicDescription() {
        #expect(String(describing: LevelSpacing.logarithmic) == "logarithmic")
    }

    @Test func customDescription() {
        let spacing = LevelSpacing.custom([1.0, 2.0, 3.0])
        #expect(String(describing: spacing) == "custom(3 thresholds)")
    }

    // MARK: - Hashable

    @Test func linearEqualsLinear() {
        #expect(LevelSpacing.linear == .linear)
    }

    @Test func logarithmicEqualsLogarithmic() {
        #expect(LevelSpacing.logarithmic == .logarithmic)
    }

    @Test func customEqualsCustomWithSameValues() {
        #expect(LevelSpacing.custom([1.0, 2.0]) == .custom([1.0, 2.0]))
    }

    @Test func linearNotEqualsLogarithmic() {
        #expect(LevelSpacing.linear != .logarithmic)
    }

    @Test func customNotEqualsCustomWithDifferentValues() {
        #expect(LevelSpacing.custom([1.0]) != .custom([2.0]))
    }
}
