//
//  HeatMapLayer.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import MapKit
import SwiftUI

/// A heat map layer rendered as contour polygons, isolines, or both
/// inside a SwiftUI `Map`.
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
    private let contours: [ContourPolygon]

    /// The gradient used to color each contour level.
    private let gradient: HeatMapGradient

    /// The total number of contour levels, used for color mapping.
    private let totalLevels: Int

    /// The fill opacity applied to each polygon.
    private let fillOpacity: Double

    /// The stroke style applied to each polygon.
    private let stroke: HeatMapStroke

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
        self.gradient = contours._gradient
        self.totalLevels = contours.levels
        self.fillOpacity = contours._fillOpacity
        self.stroke = contours._stroke
        self.renderMode = contours._renderMode
    }

    @MainActor
    public var body: some MapContent {
        if case .isolines(let lineWidth, let color) = renderMode {
            ForEach(contours) { polygon in
                MapPolyline(coordinates: closedCoordinates(polygon.coordinates))
                    .stroke(isolineColor(for: polygon.level, overrideColor: color), lineWidth: lineWidth)
            }
        } else {
            ForEach(contours) { polygon in
                MapPolygon(coordinates: polygon.coordinates)
                    .foregroundStyle(fillColor(for: polygon.level))
                    .stroke(strokeColor, lineWidth: strokeLineWidth)
            }
            if case .filledWithIsolines(let lineWidth, let color) = renderMode {
                ForEach(contours) { polygon in
                    MapPolyline(coordinates: closedCoordinates(polygon.coordinates))
                        .stroke(isolineColor(for: polygon.level, overrideColor: color), lineWidth: lineWidth)
                }
            }
        }
    }

    // MARK: - Color Helpers

    /// Maps a contour level index to a fill color from the gradient, with
    /// the configured fill opacity applied.
    ///
    /// - Parameter level: The zero-based contour level index.
    /// - Returns: The interpolated color for the given level.
    private func fillColor(for level: Int) -> Color {
        gradientColor(for: level).opacity(fillOpacity)
    }

    /// Maps a contour level index to a color from the gradient.
    ///
    /// Used as the base color for both fill and isoline rendering.
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

    /// Returns the color for an isoline at the given level, with
    /// ``fillOpacity`` applied.
    ///
    /// When `overrideColor` is non-nil it is used directly; otherwise the
    /// gradient color for the level is used. In both cases the configured
    /// fill opacity is applied so isolines fade together with filled
    /// polygons.
    ///
    /// - Parameters:
    ///   - level: The zero-based contour level index.
    ///   - overrideColor: A uniform color for all isolines, or `nil` to
    ///     derive the color from the gradient.
    /// - Returns: The resolved isoline color with opacity applied.
    private func isolineColor(for level: Int, overrideColor: Color?) -> Color {
        (overrideColor ?? gradientColor(for: level)).opacity(fillOpacity)
    }

    // MARK: - Coordinate Helpers

    /// Returns the coordinates with the first point appended to close the ring.
    ///
    /// `MapPolyline` renders open paths, so the first vertex is duplicated
    /// at the end to produce a visually closed contour line.
    private func closedCoordinates(
        _ coordinates: [CLLocationCoordinate2D]
    ) -> [CLLocationCoordinate2D] {
        guard let first = coordinates.first else { return coordinates }
        return coordinates + [first]
    }

    // MARK: - Stroke Helpers

    /// The resolved stroke color from the configured stroke style.
    private var strokeColor: Color {
        switch stroke {
        case .none:
            return .clear
        case .styled(let color, _):
            return color
        }
    }

    /// The resolved stroke line width from the configured stroke style.
    private var strokeLineWidth: CGFloat {
        switch stroke {
        case .none:
            return 0
        case .styled(_, let lineWidth):
            return lineWidth
        }
    }
}
