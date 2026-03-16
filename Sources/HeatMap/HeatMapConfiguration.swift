//
//  HeatMapConfiguration.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/16/26.
//

import Foundation

/// Configuration parameters for heat map computation and rendering.
public struct HeatMapConfiguration: Sendable, Hashable {
    /// The Gaussian kernel radius in meters. Controls how far each point's
    /// influence spreads. Default: 500 meters.
    public var radius: Double

    /// The number of contour levels to extract. More levels produce a smoother
    /// visual gradient but generate more polygons. Default: 10.
    public var contourLevels: Int

    /// The resolution of the density grid. This is the number of cells along
    /// the longer axis of the bounding box. Higher values produce finer detail
    /// but increase computation time. Default: 100.
    public var gridResolution: Int

    /// The color gradient to use. Default: `.thermal`.
    public var gradient: HeatMapGradient

    /// Padding factor applied to the bounding box, as a multiple of `radius`.
    /// The bounding box extends by `radius * paddingFactor` beyond the
    /// outermost points. Default: 1.5.
    public var paddingFactor: Double

    /// The polygon smoother applied to extracted contours. Default: `.chaikin()`.
    public var smoother: AnyPolygonSmoother

    public init(
        radius: Double = 500,
        contourLevels: Int = 10,
        gridResolution: Int = 100,
        gradient: HeatMapGradient = .thermal,
        paddingFactor: Double = 1.5,
        smoother: AnyPolygonSmoother = .chaikin()
    ) {
        self.radius = radius
        self.contourLevels = contourLevels
        self.gridResolution = gridResolution
        self.gradient = gradient
        self.paddingFactor = paddingFactor
        self.smoother = smoother
    }
}
