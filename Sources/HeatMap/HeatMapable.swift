//
//  HeatMapable.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import CoreLocation

/// A geographic point with a density weight for use in heat map visualization.
///
/// Conform your data model to this protocol so it can be passed directly
/// to ``HeatMapLayer`` or ``HeatMapContours``:
///
/// ```swift
/// struct SensorReading: HeatMapable {
///     let id = UUID()
///     let coordinate: CLLocationCoordinate2D
///     let weight: Double
/// }
/// ```
///
/// ## Topics
///
/// ### Requirements
///
/// - ``coordinate``
/// - ``weight``
///
/// ### Rendering
///
/// - ``HeatMapLayer``
/// - ``HeatMapContours``
public protocol HeatMapable: Sendable, Identifiable {

    /// The geographic location of the data point.
    var coordinate: CLLocationCoordinate2D { get }

    /// The density weight of the data point.
    ///
    /// Must be non-negative. Higher values contribute more to the density
    /// field. A weight of `0` effectively makes the point invisible in the
    /// heat map. Passing a negative weight is a programmer error.
    var weight: Double { get }
}
