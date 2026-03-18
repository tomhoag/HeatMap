//
//  HeatMapLegend.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import SwiftUI

/// A gradient legend that displays the color scale used by a ``HeatMapLayer``.
///
/// Place the legend alongside your map to help users interpret the heat map
/// colors. There are two ways to create a legend:
///
/// **From a gradient and level count** — shows "Low" and "High" labels:
///
/// ```swift
/// Map {
///     if let contours {
///         HeatMapLayer(contours: contours)
///     }
/// }
/// .overlay(alignment: .bottomLeading) {
///     HeatMapLegend(gradient: config.gradient, levelCount: config.contourLevels)
///         .padding()
/// }
/// ```
///
/// **From pre-computed contours** — shows density threshold labels by default:
///
/// ```swift
/// HeatMapLegend(contours: computedContours)
/// ```
///
/// Customize the axis and label visibility with modifiers:
///
/// ```swift
/// HeatMapLegend(gradient: .thermal, levelCount: 10)
///     .axis(.horizontal)
///     .labels(.hidden)
///
/// HeatMapLegend(gradient: .thermal, levelCount: 10)
///     .labels(.customLowHigh(low: "Cold", high: "Hot"))
///
/// HeatMapLegend(gradient: .thermal, levelCount: 10)
///     .labelColor(.white)
/// ```
///
/// ### Legend Visibility with Isoline Render Modes
///
/// When the render mode is ``HeatMapRenderMode/isolines(lineWidth:color:)``
/// with a uniform `color` (e.g. `.black` or `.white`), every contour line
/// looks the same regardless of its level. In that case the gradient legend
/// provides no useful information and should be hidden. When `color` is
/// `nil` (the default), each isoline is colored by the gradient so the
/// legend remains meaningful.
///
/// For ``HeatMapRenderMode/filled`` and
/// ``HeatMapRenderMode/filledWithIsolines(lineWidth:color:)`` modes the
/// legend is always appropriate because the filled polygons carry gradient
/// color information.
///
/// ## Topics
///
/// ### Creating a Legend
///
/// - ``init(gradient:levelCount:)``
/// - ``init(contours:)``
///
/// ### Configuring Appearance
///
/// - ``axis(_:)``
/// - ``labels(_:)``
/// - ``labelColor(_:)``
/// - ``LabelVisibility``
public struct HeatMapLegend: View {
    private let gradient: HeatMapGradient
    private let levelCount: Int
    private let thresholds: [Double]?

    private var axis: Axis = .vertical
    private var labelVisibility: LabelVisibility = .thresholds
    private var labelColor: Color = .primary

    /// Controls which labels are shown alongside the gradient bar.
    public enum LabelVisibility: Sendable, Hashable {
        /// Always shows "Low" at the minimum end and "High" at the maximum end.
        case lowHigh
        /// Shows custom text at the minimum and maximum ends of the legend.
        ///
        /// Use this to display domain-specific labels instead of "Low" and
        /// "High":
        ///
        /// ```swift
        /// HeatMapLegend(gradient: .thermal, levelCount: 10)
        ///     .labels(.customLowHigh(low: "Cold", high: "Hot"))
        /// ```
        case customLowHigh(low: String, high: String)
        /// Shows density threshold values. Falls back to ``lowHigh`` if
        /// thresholds are not available.
        case thresholds
        /// Hides all labels.
        case hidden
    }

    /// Creates a legend from a gradient and level count.
    ///
    /// This displays the gradient as discrete color swatches with "Low"
    /// and "High" labels. The colors match those used by ``HeatMapLayer``
    /// for the same gradient and level count.
    ///
    /// - Parameters:
    ///   - gradient: The color gradient to display.
    ///   - levelCount: The number of contour levels. Must be at least 1.
    public init(gradient: HeatMapGradient, levelCount: Int) {
        self.gradient = gradient
        self.levelCount = max(levelCount, 1)
        self.thresholds = nil
    }

    /// Creates a legend from pre-computed contours.
    ///
    /// The gradient and level count are extracted from the contours. Density
    /// threshold values are shown by default (``LabelVisibility/thresholds``).
    ///
    /// - Parameter contours: Pre-computed contour data from
    ///   ``HeatMapContours/compute(from:configuration:)-swift.type.method``.
    public init(contours: HeatMapContours) {
        self.gradient = contours.gradient
        self.levelCount = contours.levelCount
        // Extract unique thresholds sorted by level
        let polygons: [HeatMapPolygon] = contours.contours
        let grouped = Dictionary(grouping: polygons, by: { $0.level })
        let uniqueThresholds = grouped
            .sorted { $0.key < $1.key }
            .compactMap { $0.value.first?.threshold }
        self.thresholds = uniqueThresholds.isEmpty ? nil : uniqueThresholds
    }

    /// Sets the axis along which the gradient bar is drawn.
    ///
    /// - Parameter axis: `.vertical` (default) draws the bar from bottom
    ///   (low) to top (high). `.horizontal` draws from left (low) to right
    ///   (high).
    /// - Returns: A legend configured with the given axis.
    public func axis(_ axis: Axis) -> HeatMapLegend {
        var copy = self
        copy.axis = axis
        return copy
    }

    /// Sets the label visibility for the legend.
    ///
    /// - Parameter visibility: The label visibility mode.
    /// - Returns: A legend configured with the given label visibility.
    public func labels(_ visibility: LabelVisibility) -> HeatMapLegend {
        var copy = self
        copy.labelVisibility = visibility
        return copy
    }

    /// Sets the color used for legend labels.
    ///
    /// - Parameter color: The color to apply to "Low"/"High", threshold,
    ///   and custom labels. Default: `.primary`.
    /// - Returns: A legend configured with the given label color.
    public func labelColor(_ color: Color) -> HeatMapLegend {
        var copy = self
        copy.labelColor = color
        return copy
    }

    public var body: some View {
        if axis == .vertical {
            verticalLayout
        } else {
            horizontalLayout
        }
    }

    // MARK: - Vertical Layout

    private var verticalLayout: some View {
        HStack(alignment: .center, spacing: 4) {
            gradientBar
                .frame(width: 20, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if resolvedLabelMode != .hidden {
                verticalLabels
            }
        }
    }

    private var verticalLabels: some View {
        VStack {
            Text(highLabel)
                .font(.caption2)
                .foregroundStyle(labelColor)

            Spacer()

            Text(lowLabel)
                .font(.caption2)
                .foregroundStyle(labelColor)
        }
        .frame(height: 150)
    }

    // MARK: - Horizontal Layout

    private var horizontalLayout: some View {
        VStack(alignment: .center, spacing: 4) {
            gradientBar
                .frame(width: 150, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if resolvedLabelMode != .hidden {
                horizontalLabels
            }
        }
    }

    private var horizontalLabels: some View {
        HStack {
            Text(lowLabel)
                .font(.caption2)
                .foregroundStyle(labelColor)

            Spacer()

            Text(highLabel)
                .font(.caption2)
                .foregroundStyle(labelColor)
        }
        .frame(width: 150)
    }

    // MARK: - Gradient Bar

    private var gradientBar: some View {
        GeometryReader { geometry in
            let isVertical = axis == .vertical
            let count = max(levelCount, 1)
            let size = isVertical ? geometry.size.height : geometry.size.width

            Canvas { context, canvasSize in
                for level in 0..<count {
                    let color = Self.colorForLevel(level, of: count, in: gradient)
                    // For vertical: draw from bottom (level 0) to top (level max)
                    // For horizontal: draw from left (level 0) to right (level max)
                    let segmentSize = size / CGFloat(count)

                    let rect: CGRect
                    if isVertical {
                        let y = canvasSize.height - CGFloat(level + 1) * segmentSize
                        rect = CGRect(
                            x: 0,
                            y: y,
                            width: canvasSize.width,
                            height: segmentSize + 1 // +1 to avoid gaps
                        )
                    } else {
                        let x = CGFloat(level) * segmentSize
                        rect = CGRect(
                            x: x,
                            y: 0,
                            width: segmentSize + 1,
                            height: canvasSize.height
                        )
                    }

                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }

    // MARK: - Color Mapping

    /// Maps a level index to a color, matching the formula in ``HeatMapLayer``.
    nonisolated static func colorForLevel(
        _ level: Int,
        of levelCount: Int,
        in gradient: HeatMapGradient
    ) -> Color {
        guard levelCount > 1 else {
            return gradient.colors.first ?? .clear
        }
        let fraction = Double(level) / Double(levelCount - 1)
        return gradient.color(for: fraction)
    }

    // MARK: - Label Helpers

    private var resolvedLabelMode: LabelVisibility {
        switch labelVisibility {
        case .thresholds where thresholds == nil:
            return .lowHigh
        default:
            return labelVisibility
        }
    }

    private var lowLabel: String {
        switch resolvedLabelMode {
        case .thresholds:
            if let thresholds, let first = thresholds.first {
                return formatThreshold(first)
            }
            return String(localized: "Low", comment: "Heat map legend label for the low/minimum end of the scale")
        case .customLowHigh(let low, _):
            return low
        default:
            return String(localized: "Low", comment: "Heat map legend label for the low/minimum end of the scale")
        }
    }

    private var highLabel: String {
        switch resolvedLabelMode {
        case .thresholds:
            if let thresholds, let last = thresholds.last {
                return formatThreshold(last)
            }
            return String(localized: "High", comment: "Heat map legend label for the high/maximum end of the scale")
        case .customLowHigh(_, let high):
            return high
        default:
            return String(localized: "High", comment: "Heat map legend label for the high/maximum end of the scale")
        }
    }

    private func formatThreshold(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0f", value)
        } else if value >= 1 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.3f", value)
        }
    }
}
