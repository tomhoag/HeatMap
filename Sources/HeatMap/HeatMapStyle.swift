//
//  HeatMapStyle.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/19/26.
//

import SwiftUI

/// Visual styling properties for heat map rendering.
///
/// These properties control how pre-computed contours are displayed
/// without affecting the underlying density computation. Changing
/// a style property triggers a re-render but not a recompute.
///
/// Pair this with ``HeatMapConfiguration`` to separate the expensive
/// computation from lightweight appearance changes:
///
/// ```swift
/// @State private var config = HeatMapConfiguration()
/// @State private var style = HeatMapStyle()
/// @State private var contours: HeatMapContours?
///
/// Map {
///     if let contours {
///         HeatMapLayer(contours: contours, style: style)
///     }
/// }
/// .task(id: config) {
///     contours = try? await HeatMapContours.compute(from: points, configuration: config)
/// }
/// ```
///
/// Adjusting ``gradient``, ``fillOpacity``, or ``renderMode`` re-evaluates
/// the view body instantly. Adjusting computation properties on
/// ``HeatMapConfiguration`` triggers a new `.task`.
///
/// ## Topics
///
/// ### Appearance
///
/// - ``gradient``
/// - ``fillOpacity``
/// - ``renderMode``
public struct HeatMapStyle: Sendable, Hashable {
    /// The color gradient used to render contour levels.
    ///
    /// The default is ``HeatMapGradient/thermal``.
    public var gradient: HeatMapGradient

    /// The opacity applied to contour fills and isolines.
    ///
    /// Controls how transparent the heat map is when rendered on the map.
    /// A value of `1.0` is fully opaque, `0.0` is fully transparent.
    /// The default is `1.0`.
    public var fillOpacity: Double

    /// The rendering mode for contour visualization.
    ///
    /// Controls whether contours are drawn as filled polygons, contour
    /// lines (isolines), or both. The default is
    /// ``HeatMapRenderMode/filled``.
    public var renderMode: HeatMapRenderMode

    /// Creates a heat map style.
    ///
    /// - Parameters:
    ///   - gradient: The color gradient. Default: ``HeatMapGradient/thermal``.
    ///   - fillOpacity: The fill opacity for contour polygons. Clamped to
    ///     `0...1`. Default: `1.0`.
    ///   - renderMode: The contour rendering mode. Default:
    ///     ``HeatMapRenderMode/filled``.
    public init(
        gradient: HeatMapGradient = .thermal,
        fillOpacity: Double = 1.0,
        renderMode: HeatMapRenderMode = .filled
    ) {
        self.gradient = gradient
        self.fillOpacity = min(max(fillOpacity, 0), 1)
        self.renderMode = renderMode
    }
}

extension HeatMapStyle: CustomStringConvertible {
    public var description: String {
        "HeatMapStyle(gradient: \(gradient), fillOpacity: \(fillOpacity), renderMode: \(renderMode))"
    }
}
