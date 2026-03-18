//
//  LevelSpacing.swift
//  HeatMap
//
//  Created by Tom Hoag on 3/17/26.
//

import Foundation

/// Controls how contour thresholds are distributed across the density range.
///
/// By default, thresholds are evenly spaced between the minimum and maximum
/// density values (``linear``). Use ``logarithmic`` to concentrate more
/// contour levels in the lower-density region, or ``custom(_:)`` to specify
/// exact threshold values.
///
/// ```swift
/// // Default linear spacing
/// let config = HeatMapConfiguration(levelSpacing: .linear)
///
/// // Logarithmic spacing for skewed distributions
/// let config = HeatMapConfiguration(levelSpacing: .logarithmic)
///
/// // Explicit threshold values
/// let config = HeatMapConfiguration(levelSpacing: .custom([0.1, 0.5, 1.0, 5.0, 10.0]))
/// ```
///
/// ## Topics
///
/// ### Spacing Strategies
///
/// - ``linear``
/// - ``logarithmic``
/// - ``custom(_:)``
public enum LevelSpacing: Sendable, Hashable {
    /// Evenly spaced thresholds between the minimum and maximum density.
    ///
    /// This is the default. It distributes `contourLevels` thresholds at
    /// equal intervals across the density range.
    case linear

    /// Logarithmically spaced thresholds that concentrate more levels
    /// in lower-density regions.
    ///
    /// Useful for data with long-tail distributions where most variation
    /// occurs at lower density values. Uses the formula:
    /// `threshold = min + range × (pow(base, fraction) - 1) / (base - 1)`
    /// where `base = levels + 1` and `fraction = (level + 1) / (levels + 1)`.
    case logarithmic

    /// Quantile-based thresholds that distribute contour levels across
    /// equal portions of the non-zero density values.
    ///
    /// Instead of dividing the density *range* evenly, this strategy
    /// examines the actual distribution of grid cell values and places
    /// each threshold so that approximately the same number of non-zero
    /// cells fall between consecutive levels. This ensures contours
    /// appear even in sparse regions where density values are far below
    /// the global maximum.
    ///
    /// Useful for datasets with highly skewed density distributions,
    /// such as weather station networks where coastal clusters produce
    /// density values orders of magnitude higher than interior regions.
    case quantile

    /// User-specified threshold values.
    ///
    /// The provided values are absolute density values. At extraction time,
    /// values outside the computed density range are filtered out, and the
    /// remaining values are sorted and deduplicated.
    ///
    /// When using custom thresholds, ``HeatMapConfiguration/contourLevels``
    /// is derived from the threshold count and does not need to be set
    /// separately.
    ///
    /// - Parameter thresholds: The explicit density threshold values.
    case custom(_ thresholds: [Double])
}

extension LevelSpacing: CustomStringConvertible {
    public var description: String {
        switch self {
        case .linear:
            return "linear"
        case .logarithmic:
            return "logarithmic"
        case .quantile:
            return "quantile"
        case .custom(let thresholds):
            return "custom(\(thresholds.count) thresholds)"
        }
    }
}

extension LevelSpacing {
    /// Resolves the spacing strategy into concrete threshold values.
    ///
    /// - Parameters:
    ///   - levels: The number of contour levels (ignored for ``custom(_:)``).
    ///   - minDensity: The minimum density value in the grid.
    ///   - maxDensity: The maximum density value in the grid.
    /// - Returns: Sorted threshold values within the density range.
    func resolveThresholds(
        levels: Int,
        minDensity: Double,
        maxDensity: Double,
        densityValues: [Double] = []
    ) -> [Double] {
        let range = maxDensity - minDensity
        guard range > 0 else { return [] }

        switch self {
        case .linear:
            guard levels > 0 else { return [] }
            return (0..<levels).map { level in
                let fraction = Double(level + 1) / Double(levels + 1)
                return minDensity + range * fraction
            }

        case .logarithmic:
            guard levels > 0 else { return [] }
            let base = Double(levels + 1)
            let denom = base - 1.0
            guard denom > 0 else { return [] }
            return (0..<levels).map { level in
                let fraction = Double(level + 1) / Double(levels + 1)
                let logFraction = (pow(base, fraction) - 1.0) / denom
                return minDensity + range * logFraction
            }

        case .quantile:
            guard levels > 0 else { return [] }
            let epsilon = range * 1e-10
            let nonZero = densityValues.filter { $0 > minDensity + epsilon }.sorted()
            guard !nonZero.isEmpty else { return [] }
            return (0..<levels).compactMap { level in
                let fraction = Double(level + 1) / Double(levels + 1)
                let index = min(Int(fraction * Double(nonZero.count)), nonZero.count - 1)
                return nonZero[index]
            }
            .removingDuplicates()

        case .custom(let thresholds):
            return thresholds
                .filter { $0 > minDensity && $0 < maxDensity }
                .sorted()
                .removingDuplicates()
        }
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
