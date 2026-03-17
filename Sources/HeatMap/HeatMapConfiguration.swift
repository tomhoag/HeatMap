//
//  HeatMapConfiguration.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import Foundation

/// Configuration parameters for heat map computation and rendering.
///
/// All properties have sensible defaults, so you can create a configuration
/// with no arguments for a quick start:
///
/// ```swift
/// let contours = try await HeatMapContours.compute(from: myPoints)
/// ```
///
/// Customize individual parameters as needed:
///
/// ```swift
/// let config = HeatMapConfiguration(
///     radius: 1000,
///     contourLevels: 15,
///     gradient: .cool,
///     smoother: .chaikin(iterations: 3)
/// )
/// let contours = try await HeatMapContours.compute(from: myPoints, configuration: config)
/// ```
///
/// ## Topics
///
/// ### Density Kernel
///
/// - ``radius``
/// - ``paddingFactor``
///
/// ### Contours
///
/// - ``contourLevels``
/// - ``gridResolution``
/// - ``smoother``
///
/// ### Appearance
///
/// - ``gradient``
/// - ``fillOpacity``
/// - ``stroke``
///
/// ### Adaptive Configuration
///
/// - ``adaptive(for:)``
public struct HeatMapConfiguration: Sendable, Hashable {
    /// The Gaussian kernel radius in meters.
    ///
    /// Controls how far each point's influence spreads across the density
    /// grid. Larger values produce smoother, more diffuse heat maps; smaller
    /// values reveal finer detail.
    ///
    /// The default is `500` meters.
    public var radius: Double

    /// The number of contour levels to extract.
    ///
    /// More levels produce a smoother visual gradient but generate more
    /// polygons, which may affect rendering performance. The default is `10`.
    public var contourLevels: Int

    /// The resolution of the density grid along its longer axis.
    ///
    /// Higher values produce finer spatial detail but increase computation
    /// time quadratically. The shorter axis is scaled proportionally to
    /// maintain a square cell aspect ratio. The default is `100`.
    public var gridResolution: Int

    /// The color gradient used to render contour levels.
    ///
    /// The default is ``HeatMapGradient/thermal``.
    public var gradient: HeatMapGradient

    /// Padding factor applied to the bounding box, as a multiple of ``radius``.
    ///
    /// The bounding box extends by `radius × paddingFactor` beyond the
    /// outermost data points to ensure the Gaussian kernel tails are fully
    /// captured. The default is `1.5`.
    public var paddingFactor: Double

    /// The fill opacity applied to all contour polygons.
    ///
    /// Controls how transparent the heat map polygons are when rendered on
    /// the map. A value of `1.0` is fully opaque, `0.0` is fully transparent.
    /// This affects only polygon fills, not strokes. The default is `1.0`.
    public var fillOpacity: Double

    /// The stroke style applied to contour polygon borders.
    ///
    /// Controls whether MapKit's default polygon border is visible and,
    /// if so, what color and width it uses. The default is
    /// ``HeatMapStroke/none``, which suppresses the default border for
    /// smooth blending between contour levels.
    public var stroke: HeatMapStroke

    /// The polygon smoother applied to extracted contour polygons.
    ///
    /// Smoothing reduces the stair-step artifacts produced by the marching
    /// squares algorithm. The default is ``PolygonSmoother/chaikin(iterations:)``
    /// with two iterations.
    public var smoother: PolygonSmoother

    /// Creates a heat map configuration.
    ///
    /// Invalid values are clamped to their minimum: `radius` to `1`,
    /// `contourLevels` to `1`, `gridResolution` to `2`,
    /// `paddingFactor` to `0`, and `fillOpacity` to `0...1`.
    ///
    /// - Parameters:
    ///   - radius: The Gaussian kernel radius in meters. Minimum: `1`.
    ///     Default: `500`.
    ///   - contourLevels: The number of contour levels. Minimum: `1`.
    ///     Default: `10`.
    ///   - gridResolution: Grid cells along the longer axis. Minimum: `2`.
    ///     Default: `100`.
    ///   - gradient: The color gradient. Default: ``HeatMapGradient/thermal``.
    ///   - paddingFactor: Bounding box padding as a radius multiple.
    ///     Minimum: `0`. Default: `1.5`.
    ///   - fillOpacity: The fill opacity for contour polygons. Clamped to
    ///     `0...1`. Default: `1.0`.
    ///   - stroke: The polygon stroke style. Default: ``HeatMapStroke/none``.
    ///   - smoother: The polygon smoother. Default:
    ///     ``PolygonSmoother/chaikin(iterations:)`` with 2 iterations.
    public init(
        radius: Double = 500,
        contourLevels: Int = 10,
        gridResolution: Int = 100,
        gradient: HeatMapGradient = .thermal,
        paddingFactor: Double = 1.5,
        fillOpacity: Double = 1.0,
        stroke: HeatMapStroke = .none,
        smoother: PolygonSmoother = .chaikin()
    ) {
        self.radius = max(radius, 1)
        self.contourLevels = max(contourLevels, 1)
        self.gridResolution = max(gridResolution, 2)
        self.gradient = gradient
        self.paddingFactor = max(paddingFactor, 0)
        self.fillOpacity = min(max(fillOpacity, 0), 1)
        self.stroke = stroke
        self.smoother = smoother
    }
}

extension HeatMapConfiguration: CustomStringConvertible {
    public var description: String {
        "HeatMapConfiguration(radius: \(radius)m, levels: \(contourLevels), grid: \(gridResolution), gradient: \(gradient), padding: \(paddingFactor)×, fillOpacity: \(fillOpacity), stroke: \(stroke), smoother: \(smoother))"
    }
}
