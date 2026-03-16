import CoreLocation
import Foundation
@testable import HeatMap

struct TestPoint: HeatMapable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let weight: Double

    init(
        latitude: Double,
        longitude: Double,
        weight: Double = 1.0,
        id: UUID = UUID()
    ) {
        self.id = id
        self.coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        self.weight = weight
    }
}

// MARK: - Factory Data

/// A single point in San Francisco.
let sanFrancisco = TestPoint(latitude: 37.7749, longitude: -122.4194)

/// A tight cluster of points for density testing.
let tightCluster: [TestPoint] = [
    TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 10),
    TestPoint(latitude: 37.7751, longitude: -122.4180, weight: 8),
    TestPoint(latitude: 37.7755, longitude: -122.4170, weight: 9),
    TestPoint(latitude: 37.7745, longitude: -122.4200, weight: 7),
]

/// Two widely separated point clusters.
let separatedClusters: [TestPoint] = [
    // Cluster A - San Francisco
    TestPoint(latitude: 37.7749, longitude: -122.4194, weight: 5),
    TestPoint(latitude: 37.7751, longitude: -122.4180, weight: 5),
    // Cluster B - Oakland
    TestPoint(latitude: 37.8044, longitude: -122.2712, weight: 5),
    TestPoint(latitude: 37.8050, longitude: -122.2720, weight: 5),
]
