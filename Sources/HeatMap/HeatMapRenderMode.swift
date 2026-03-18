//
//  HeatMapRenderMode.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import SwiftUI

/// Controls how the heat map contours are rendered on the map.
///
/// Use this type with ``HeatMapConfiguration/renderMode`` to switch
/// between filled polygons, contour lines (isolines), or both:
///
/// ```swift
/// // Contour lines only, 2pt wide, colored by gradient
/// let config = HeatMapConfiguration(renderMode: .isolines(lineWidth: 2))
///
/// // Uniform black isolines
/// let config = HeatMapConfiguration(renderMode: .isolines(lineWidth: 1, color: .black))
///
/// // Filled polygons with white isoline overlay
/// let config = HeatMapConfiguration(renderMode: .filledWithIsolines(color: .white))
/// ```
///
/// When `color` is `nil` (the default), each isoline is colored by
/// the configured ``HeatMapGradient`` at its contour level.
///
/// ## Topics
///
/// ### Render Modes
///
/// - ``filled``
/// - ``isolines(lineWidth:color:)``
/// - ``filledWithIsolines(lineWidth:color:)``
public enum HeatMapRenderMode: Sendable, Hashable {
    /// Filled contour polygons (default).
    ///
    /// This is the standard heat map visualization where each contour
    /// level is rendered as a filled polygon colored by the gradient.
    case filled

    /// Contour lines (isolines) only, with no polygon fills.
    ///
    /// - Parameters:
    ///   - lineWidth: The stroke width for isolines in points.
    ///     Default: `1`.
    ///   - color: The uniform color for all isolines, or `nil` to
    ///     color each isoline by its gradient level. Default: `nil`.
    case isolines(lineWidth: CGFloat = 1, color: Color? = nil)

    /// Filled polygons with isoline overlays drawn on top.
    ///
    /// Renders filled contour polygons (respecting
    /// ``HeatMapConfiguration/fillOpacity`` and
    /// ``HeatMapConfiguration/stroke``) and draws isolines on top of
    /// each contour boundary.
    ///
    /// - Parameters:
    ///   - lineWidth: The stroke width for the isoline overlay
    ///     in points. Default: `1`.
    ///   - color: The uniform color for all isolines, or `nil` to
    ///     color each isoline by its gradient level. Default: `nil`.
    case filledWithIsolines(lineWidth: CGFloat = 1, color: Color? = nil)
}

extension HeatMapRenderMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .filled:
            return "filled"
        case .isolines(let lineWidth, let color):
            if let color {
                return "isolines(\(lineWidth)pt, \(color))"
            }
            return "isolines(\(lineWidth)pt)"
        case .filledWithIsolines(let lineWidth, let color):
            if let color {
                return "filledWithIsolines(\(lineWidth)pt, \(color))"
            }
            return "filledWithIsolines(\(lineWidth)pt)"
        }
    }
}
