//
//  HeatMapPoint.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//
import HeatMap
import CoreLocation

/// A weighted geographic point for heat map rendering.
public struct HeatMapPoint: HeatMapable {
    public let id: UUID
    /// The geographic coordinate of this point.
    public let coordinate: CLLocationCoordinate2D
    /// The weight of this point. Higher values produce greater density.
    /// Default is 1.0.
    public let weight: Double

    public init(
        coordinate: CLLocationCoordinate2D,
        weight: Double = 1.0,
        id: UUID = UUID()
    ) {
        self.coordinate = coordinate
        self.weight = weight
        self.id = id
    }
}

extension HeatMapPoint: Hashable {
    public static func == (lhs: HeatMapPoint, rhs: HeatMapPoint) -> Bool {
        lhs.id == rhs.id
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.weight == rhs.weight
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(weight)
    }
}
