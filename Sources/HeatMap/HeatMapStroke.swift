//
//  HeatMapStroke.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import SwiftUI

/// Controls the stroke drawn around each contour polygon.
///
/// By default, MapKit draws a thin border around every `MapPolygon`.
/// Use this type to suppress that default stroke or to apply a custom
/// color and line width.
///
/// ```swift
/// // No visible stroke (smooth blending between contours)
/// let config = HeatMapConfiguration(stroke: .none)
///
/// // Custom stroke for debugging contour boundaries
/// let config = HeatMapConfiguration(stroke: .styled(color: .black, lineWidth: 1))
/// ```
///
/// ## Topics
///
/// ### Stroke Styles
///
/// - ``none``
/// - ``styled(color:lineWidth:)``
public enum HeatMapStroke: Sendable, Hashable {
    /// No visible stroke. Suppresses MapKit's default polygon border.
    ///
    /// This is the default. It produces smooth blending between adjacent
    /// contour levels without visible contour edges.
    case none

    /// A stroke with the given color and line width.
    ///
    /// Useful for debugging contour boundaries or as a stylistic choice.
    ///
    /// - Parameters:
    ///   - color: The stroke color.
    ///   - lineWidth: The stroke line width in points.
    case styled(color: Color, lineWidth: CGFloat)
}

extension HeatMapStroke: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .styled(_, let lineWidth):
            return "styled(\(lineWidth)pt)"
        }
    }
}
