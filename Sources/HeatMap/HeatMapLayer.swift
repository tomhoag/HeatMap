//
//  HeatMapLayer.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import MapKit
import SwiftUI

/// A heat map layer rendered as contour polygons inside a SwiftUI `Map`.
///
/// Pre-compute contours using
/// ``HeatMapContours/compute(from:configuration:)-swift.type.method``
/// and pass the result to ``init(contours:)``:
///
/// ```swift
/// @State private var contours: HeatMapContours?
///
/// Map {
///     if let contours {
///         HeatMapLayer(contours: contours)
///     }
/// }
/// .task {
///     contours = try? await HeatMapContours.compute(
///         from: myPoints,
///         configuration: HeatMapConfiguration(
///             radius: 300,
///             contourLevels: 12,
///             gradient: .thermal
///         )
///     )
/// }
/// ```
///
/// ## Topics
///
/// ### Creating a Layer
///
/// - ``init(contours:)``
///
/// ### Pre-computing Contours
///
/// - ``HeatMapContours``
public struct HeatMapLayer: MapContent {
    /// The contour polygons to render.
    private let contours: [HeatMapPolygon]

    /// The gradient used to color each contour level.
    private let gradient: HeatMapGradient

    /// The total number of contour levels, used for color mapping.
    private let totalLevels: Int

    /// The fill opacity applied to each polygon.
    private let fillOpacity: Double

    /// The render mode controlling how contours are visualized.
    private let renderMode: HeatMapRenderMode

    /// Creates a heat map layer from pre-computed contours.
    ///
    /// Use ``HeatMapContours/compute(from:configuration:)-swift.type.method``
    /// to compute contours asynchronously, then pass the result here.
    ///
    /// - Parameter contours: Pre-computed contour data.
    public init(contours: HeatMapContours) {
        self.contours = contours.polygons
        self.gradient = contours.gradient
        self.totalLevels = contours.levels
        self.fillOpacity = contours.fillOpacity
        self.renderMode = contours.renderMode
    }

    @MainActor
    public var body: some MapContent {
        ForEach(contours) { polygon in
            MapPolygon(coordinates: polygon.coordinates)
                .foregroundStyle(polygonFillColor(for: polygon.level))
                .stroke(polygonStrokeColor(for: polygon.level), lineWidth: polygonStrokeLineWidth)
        }
    }

    // MARK: - Color Helpers

    /// Maps a contour level index to a color from the gradient.
    ///
    /// - Parameter level: The zero-based contour level index.
    /// - Returns: The interpolated gradient color for the given level.
    private func gradientColor(for level: Int) -> Color {
        if totalLevels > 1 {
            let fraction = Double(level) / Double(totalLevels - 1)
            return gradient.color(for: fraction)
        } else {
            return gradient.colors.first ?? .clear
        }
    }

    /// Returns the polygon fill color for the given level based on
    /// the current render mode.
    ///
    /// For `.isolines` mode the fill is transparent so only the stroke
    /// is visible. For `.filled` and `.filledWithIsolines` modes the
    /// gradient color with ``fillOpacity`` is used.
    ///
    /// - Parameter level: The zero-based contour level index.
    /// - Returns: The fill color for the polygon.
    private func polygonFillColor(for level: Int) -> Color {
        switch renderMode {
        case .isolines:
            return .clear
        case .filled, .filledWithIsolines:
            return gradientColor(for: level).opacity(fillOpacity)
        }
    }

    /// Returns the polygon stroke color for the given level based on
    /// the current render mode.
    ///
    /// For `.filled` mode the stroke is cleared to suppress MapKit's
    /// default polygon border. For `.isolines` and `.filledWithIsolines`
    /// modes the stroke uses either the override color or the gradient
    /// color, with ``fillOpacity`` applied.
    ///
    /// - Parameter level: The zero-based contour level index.
    /// - Returns: The stroke color for the polygon.
    private func polygonStrokeColor(for level: Int) -> Color {
        switch renderMode {
        case .filled:
            return .clear
        case .isolines(_, let color), .filledWithIsolines(_, let color):
            return (color ?? gradientColor(for: level)).opacity(fillOpacity)
        }
    }

    /// The stroke line width derived from the current render mode.
    ///
    /// Returns `0` for `.filled` mode (no visible stroke) and the
    /// configured line width for `.isolines` and `.filledWithIsolines`.
    private var polygonStrokeLineWidth: CGFloat {
        switch renderMode {
        case .filled:
            return 0
        case .isolines(let lineWidth, _), .filledWithIsolines(let lineWidth, _):
            return lineWidth
        }
    }
}
