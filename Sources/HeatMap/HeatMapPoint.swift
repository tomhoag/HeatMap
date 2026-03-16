//
//  HeatMapPoint.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation

public protocol HeatMapable: Sendable, Identifiable {

    var coordinate: CLLocationCoordinate2D {get}
    var weight: Double {get}


}


