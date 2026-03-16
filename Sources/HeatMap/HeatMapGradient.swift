//
//  HeatMapGradient.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import SwiftUI

/// A color gradient mapping for heat map density levels.
///
/// Each gradient contains an array of colors ordered from lowest density
/// (index 0) to highest density. The first color is typically transparent
/// so areas with no data are see-through.
public struct HeatMapGradient: Sendable, Hashable {
    /// The color stops from lowest density to highest density.
    public let colors: [Color]

    /// Creates a gradient from the given array of colors.
    ///
    /// - Parameter colors: At least two colors, ordered from lowest
    ///   to highest density.
    public init(colors: [Color]) {
        precondition(colors.count >= 2, "HeatMapGradient requires at least two colors.")
        self.colors = colors
    }
}

extension HeatMapGradient {
    /// Returns the interpolated color for the given fraction.
    ///
    /// - Parameter fraction: A value from 0 (lowest density) to 1
    ///   (highest density). Values outside this range are clamped.
    /// - Returns: A color linearly interpolated between the gradient's
    ///   color stops in the sRGB color space.
    public func color(for fraction: Double) -> Color {
        let clamped = min(max(fraction, 0), 1)
        guard colors.count >= 2 else {
            return colors.first ?? .clear
        }

        let scaledIndex = clamped * Double(colors.count - 1)
        let lower = Int(scaledIndex)
        let upper = min(lower + 1, colors.count - 1)
        let t = Float(scaledIndex - Double(lower))

        let env = EnvironmentValues()
        let c0 = colors[lower].resolve(in: env)
        let c1 = colors[upper].resolve(in: env)

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

    /// A monochrome gradient using a single hue from transparent to opaque.
    ///
    /// - Parameter color: The color to use for the gradient.
    /// - Returns: A gradient that fades from transparent to the given color.
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
