import Foundation
import Testing
@testable import HeatMap

struct HeatMapContoursTests {

    let defaultConfig = HeatMapConfiguration()

    @Test func computeFromEmptyPoints() {
        let contours = HeatMapContours.compute(
            from: [TestPoint](),
            configuration: defaultConfig
        )
        #expect(contours.polygons.isEmpty)
    }

    @Test func computeFromCluster() {
        let contours = HeatMapContours.compute(
            from: tightCluster,
            configuration: defaultConfig
        )
        #expect(!contours.polygons.isEmpty)
    }

    @Test func computePreservesLevels() {
        let config = HeatMapConfiguration(contourLevels: 7)
        let contours = HeatMapContours.compute(from: tightCluster, configuration: config)
        #expect(contours.levels == 7)
    }

    @Test func computePreservesGradient() {
        let config = HeatMapConfiguration(gradient: .cool)
        let contours = HeatMapContours.compute(from: tightCluster, configuration: config)
        #expect(contours.gradient == .cool)
    }

    @Test func defaultConfiguration() {
        let contours = HeatMapContours.compute(from: tightCluster)
        #expect(contours.levels == 10)
        #expect(contours.gradient == .thermal)
    }

    // MARK: - Async Compute

    @Test func asyncComputePreservesConfiguration() async throws {
        let config = HeatMapConfiguration(contourLevels: 5, gradient: .warm)
        let contours = try await HeatMapContours.compute(from: tightCluster, configuration: config)
        #expect(contours.levels == 5)
        #expect(contours.gradient == .warm)
        #expect(!contours.polygons.isEmpty)
    }

    @Test func asyncComputeFromEmptyPoints() async throws {
        let contours = try await HeatMapContours.compute(from: [TestPoint]())
        #expect(contours.polygons.isEmpty)
    }

    @Test func asyncComputeThrowsWhenCancelled() async {
        let task = Task {
            try await HeatMapContours.compute(
                from: tightCluster,
                configuration: HeatMapConfiguration(contourLevels: 100, gridResolution: 300)
            )
        }
        task.cancel()
        do {
            _ = try await task.value
            // If the computation finished before cancellation, that's acceptable
        } catch is CancellationError {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Equatable

    @Test func contoursEqualToSelf() {
        let contours = HeatMapContours.compute(from: tightCluster)
        #expect(contours == contours)
    }

    @Test func contoursNotEqualWhenRecomputed() {
        let a = HeatMapContours.compute(from: tightCluster)
        let b = HeatMapContours.compute(from: tightCluster)
        // Each computation generates fresh UUIDs, so they differ
        #expect(a != b)
    }

    @Test func contoursNotEqualWhenDifferentLevels() {
        let a = HeatMapContours.compute(
            from: tightCluster,
            configuration: HeatMapConfiguration(contourLevels: 5)
        )
        let b = HeatMapContours.compute(
            from: tightCluster,
            configuration: HeatMapConfiguration(contourLevels: 10)
        )
        #expect(a != b)
    }

    @Test func contoursNotEqualWhenDifferentGradient() {
        let a = HeatMapContours.compute(
            from: tightCluster,
            configuration: HeatMapConfiguration(gradient: .thermal)
        )
        let b = HeatMapContours.compute(
            from: tightCluster,
            configuration: HeatMapConfiguration(gradient: .cool)
        )
        #expect(a != b)
    }

    @Test func contourEqualByID() {
        let contours = HeatMapContours.compute(from: tightCluster)
        guard let first = contours.contours.first else {
            Issue.record("Expected at least one contour")
            return
        }
        let copy = HeatMapPolygon(
            id: first.id,
            level: first.level,
            threshold: first.threshold,
            coordinates: first.coordinates
        )
        #expect(first == copy)
    }

    @Test func contourNotEqualWithDifferentID() {
        let contours = HeatMapContours.compute(from: tightCluster)
        guard let first = contours.contours.first else {
            Issue.record("Expected at least one contour")
            return
        }
        let different = HeatMapPolygon(
            id: UUID(),
            level: first.level,
            threshold: first.threshold,
            coordinates: first.coordinates
        )
        #expect(first != different)
    }
}
