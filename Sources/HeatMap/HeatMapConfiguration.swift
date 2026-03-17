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
/// let contours = await HeatMapContours.compute(from: myPoints)
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
/// let contours = await HeatMapContours.compute(from: myPoints, configuration: config)
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

    /// The polygon smoother applied to extracted contour polygons.
    ///
    /// Smoothing reduces the stair-step artifacts produced by the marching
    /// squares algorithm. The default is ``AnyPolygonSmoother/chaikin(iterations:)``
    /// with two iterations.
    public var smoother: AnyPolygonSmoother

    /// Creates a heat map configuration.
    ///
    /// Invalid values are clamped to their minimum: `radius` to `1`,
    /// `contourLevels` to `1`, `gridResolution` to `2`, and
    /// `paddingFactor` to `0`.
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
    ///   - smoother: The polygon smoother. Default:
    ///     ``AnyPolygonSmoother/chaikin(iterations:)`` with 2 iterations.
    public init(
        radius: Double = 500,
        contourLevels: Int = 10,
        gridResolution: Int = 100,
        gradient: HeatMapGradient = .thermal,
        paddingFactor: Double = 1.5,
        smoother: AnyPolygonSmoother = .chaikin()
    ) {
        self.radius = max(radius, 1)
        self.contourLevels = max(contourLevels, 1)
        self.gridResolution = max(gridResolution, 2)
        self.gradient = gradient
        self.paddingFactor = max(paddingFactor, 0)
        self.smoother = smoother
    }
}

extension HeatMapConfiguration: CustomStringConvertible {
    public var description: String {
        "HeatMapConfiguration(radius: \(radius)m, levels: \(contourLevels), grid: \(gridResolution), gradient: \(gradient), padding: \(paddingFactor)×, smoother: \(smoother))"
    }
}
