import CoreLocation
import Testing
@testable import HeatMap

struct HeatMapConfigurationAdaptiveTests {

    // MARK: - Edge Cases

    @Test func adaptiveFromEmptyPointsReturnsDefault() {
        let config = HeatMapConfiguration.adaptive(for: [TestPoint]())
        let defaults = HeatMapConfiguration()
        #expect(config.radius == defaults.radius)
        #expect(config.gridResolution == defaults.gridResolution)
        #expect(config.contourLevels == defaults.contourLevels)
        #expect(config.gradient == defaults.gradient)
    }

    @Test func adaptiveFromSinglePointReturnsDefault() {
        let config = HeatMapConfiguration.adaptive(for: [sanFrancisco])
        let defaults = HeatMapConfiguration()
        #expect(config.radius == defaults.radius)
        #expect(config.gridResolution == defaults.gridResolution)
    }

    // MARK: - Radius Scaling

    @Test func adaptiveFromTightCluster() {
        let config = HeatMapConfiguration.adaptive(for: tightCluster)
        // Tight cluster spans ~300m, so radius should be small
        #expect(config.radius < 500)
        #expect(config.radius >= 50)
    }

    @Test func adaptiveFromSeparatedClusters() {
        let config = HeatMapConfiguration.adaptive(for: separatedClusters)
        // SF to Oakland is ~15km, so radius should be larger
        #expect(config.radius > 500)
    }

    @Test func adaptiveRadiusScalesWithSpread() {
        let tight = HeatMapConfiguration.adaptive(for: tightCluster)
        let wide = HeatMapConfiguration.adaptive(for: separatedClusters)
        #expect(wide.radius > tight.radius)
    }

    // MARK: - Grid Resolution

    @Test func adaptiveGridResolutionScalesWithRadius() {
        let tight = HeatMapConfiguration.adaptive(for: tightCluster)
        let wide = HeatMapConfiguration.adaptive(for: separatedClusters)
        // Both should produce resolution within clamped bounds
        #expect(tight.gridResolution >= 20)
        #expect(tight.gridResolution <= 300)
        #expect(wide.gridResolution >= 20)
        #expect(wide.gridResolution <= 300)
    }

    // MARK: - Valid Configuration

    @Test func adaptiveReturnsValidConfiguration() {
        let config = HeatMapConfiguration.adaptive(for: separatedClusters)
        #expect(config.radius >= 1)
        #expect(config.contourLevels >= 1)
        #expect(config.gridResolution >= 2)
        #expect(config.paddingFactor >= 0)
        #expect(config.gradient == .thermal)
    }
}
