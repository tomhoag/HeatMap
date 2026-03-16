//
//  HeatMapGradient.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import SwiftUI

/// A color gradient that maps density fractions to interpolated colors.
///
/// Each gradient contains an ordered array of color stops from lowest
/// density (index 0) to highest density. The first color is typically
/// transparent so areas with no data are see-through on the map.
///
/// Use one of the built-in gradients or create your own:
///
/// ```swift
/// // Built-in
/// let config = HeatMapConfiguration(gradient: .thermal)
///
/// // Custom
/// let custom = HeatMapGradient(colors: [
///     .clear,
///     .blue.opacity(0.3),
///     .green.opacity(0.6),
///     .red
/// ])
/// ```
///
/// ## Topics
///
/// ### Built-in Gradients
///
/// - ``thermal``
/// - ``warm``
/// - ``cool``
/// - ``monochrome(_:)``
///
/// ### Sampling Colors
///
/// - ``color(for:)``
public struct HeatMapGradient: Sendable, Hashable {
    /// The color stops from lowest density to highest density.
    public let colors: [Color]

    /// Pre-resolved RGBA components for each color stop, computed once at init.
    private let resolvedStops: [Color.Resolved]

    /// Creates a gradient from the given array of colors.
    ///
    /// Colors should be ordered from lowest density (transparent/cool) to
    /// highest density (opaque/hot).
    ///
    /// - Parameter colors: At least two colors, ordered from lowest
    ///   to highest density.
    /// - Precondition: `colors` must contain at least two elements.
    public init(colors: [Color]) {
        precondition(colors.count >= 2, "HeatMapGradient requires at least two colors.")
        self.colors = colors
        let env = EnvironmentValues()
        self.resolvedStops = colors.map { $0.resolve(in: env) }
    }

    // Hashable conformance based only on colors (resolvedStops are derived).
    public static func == (lhs: HeatMapGradient, rhs: HeatMapGradient) -> Bool {
        lhs.colors == rhs.colors
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(colors)
    }
}

extension HeatMapGradient {
    /// Returns the interpolated color for a given density fraction.
    ///
    /// The fraction is linearly mapped across the gradient's color stops
    /// and interpolated in the sRGB color space.
    ///
    /// - Parameter fraction: A value from `0` (lowest density) to `1`
    ///   (highest density). Values outside this range are clamped.
    /// - Returns: A color linearly interpolated between the gradient's
    ///   color stops.
    public func color(for fraction: Double) -> Color {
        let clamped = min(max(fraction, 0), 1)
        guard resolvedStops.count >= 2 else {
            return colors.first ?? .clear
        }

        let scaledIndex = clamped * Double(resolvedStops.count - 1)
        let lower = Int(scaledIndex)
        let upper = min(lower + 1, resolvedStops.count - 1)
        let t = Float(scaledIndex - Double(lower))

        let c0 = resolvedStops[lower]
        let c1 = resolvedStops[upper]

        let resolved = Color.Resolved(
            red: c0.red + t * (c1.red - c0.red),
            green: c0.green + t * (c1.green - c0.green),
            blue: c0.blue + t * (c1.blue - c0.blue),
            opacity: c0.opacity + t * (c1.opacity - c0.opacity)
        )
        return Color(resolved)
    }
}

extension HeatMapGradient {
    /// A thermal gradient: transparent → blue → cyan → green → yellow → orange → red.
    ///
    /// This is the default gradient used by ``HeatMapConfiguration``.
    public static let thermal = HeatMapGradient(colors: [
        Color.blue.opacity(0.0),
        Color.blue.opacity(0.4),
        Color.cyan.opacity(0.5),
        Color.green.opacity(0.6),
        Color.yellow.opacity(0.7),
        Color.orange.opacity(0.8),
        Color.red.opacity(0.9)
    ])

    /// A warm gradient: transparent → yellow → orange → red.
    public static let warm = HeatMapGradient(colors: [
        Color.yellow.opacity(0.0),
        Color.yellow.opacity(0.4),
        Color.orange.opacity(0.6),
        Color.red.opacity(0.8),
        Color.red
    ])

    /// A cool gradient: transparent → cyan → blue → purple.
    public static let cool = HeatMapGradient(colors: [
        Color.cyan.opacity(0.0),
        Color.cyan.opacity(0.4),
        Color.blue.opacity(0.6),
        Color.purple.opacity(0.8),
        Color.purple
    ])

    /// Creates a monochrome gradient that fades from transparent to the given color.
    ///
    /// Useful for single-hue visualizations where only intensity varies.
    ///
    /// - Parameter color: The color to use for the gradient.
    /// - Returns: A gradient that fades from transparent to the given color
    ///   in six evenly-spaced opacity steps.
    public static func monochrome(_ color: Color) -> HeatMapGradient {
        HeatMapGradient(colors: [
            color.opacity(0.0),
            color.opacity(0.2),
            color.opacity(0.4),
            color.opacity(0.6),
            color.opacity(0.8),
            color
        ])
    }
}
