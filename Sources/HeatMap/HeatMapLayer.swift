//
//  HeatMapLayer.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import MapKit
import SwiftUI

/// A heat map layer rendered as filled contour polygons inside a SwiftUI `Map`.
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
    }

    @MainActor
    public var body: some MapContent {
        ForEach(contours) { polygon in
            MapPolygon(coordinates: polygon.coordinates)
                .foregroundStyle(colorForLevel(polygon.level))
                .stroke(strokeColor, lineWidth: strokeLineWidth)
        }
    }

    /// Maps a contour level index to a color from the gradient, with
    /// the configured fill opacity applied.
    ///
    /// - Parameter level: The zero-based contour level index.
    /// - Returns: The interpolated color for the given level.
    private func colorForLevel(_ level: Int) -> Color {
        let color: Color
        if totalLevels > 1 {
            let fraction = Double(level) / Double(totalLevels - 1)
            color = gradient.color(for: fraction)
        } else {
            color = gradient.colors.first ?? .clear
        }
        return color.opacity(fillOpacity)
    }

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
