//
//  OptionTypes.swift
//  HeatMapExample
//
//  Created by Tom Hoag on 3/16/26.
//

import HeatMap
import SwiftUI

enum GradientOption: String, CaseIterable, Identifiable {
    case thermal = "Thermal"
    case warm = "Warm"
    case cool = "Cool"

    var id: String { rawValue }

    var gradient: HeatMapGradient {
        switch self {
        case .thermal: .thermal
        case .warm: .warm
        case .cool: .cool
        }
    }
}

enum SmootherOption: String, CaseIterable, Identifiable {
    case none = "None"
    case chaikin1 = "Chaikin 1"
    case chaikin2 = "Chaikin 2"
    case chaikin3 = "Chaikin 3"

    var id: String { rawValue }

    var smoother: PolygonSmoother {
        switch self {
        case .none: .none
        case .chaikin1: .chaikin(iterations: 1)
        case .chaikin2: .chaikin(iterations: 2)
        case .chaikin3: .chaikin(iterations: 3)
        }
    }
}

enum StrokeOption: String, CaseIterable, Identifiable {
    case none = "None"
    case thin = "Thin"
    case medium = "Medium"
    case thick = "Thick"

    var id: String { rawValue }

    var stroke: HeatMapStroke {
        switch self {
        case .none: .none
        case .thin: .styled(color: .black, lineWidth: 0.5)
        case .medium: .styled(color: .black, lineWidth: 1)
        case .thick: .styled(color: .black, lineWidth: 2)
        }
    }
}

enum RenderModeOption: String, CaseIterable, Identifiable {
    case filled = "Filled"
    case isolines = "Isolines"
    case both = "Both"

    var id: String { rawValue }

    func renderMode(color: Color?) -> HeatMapRenderMode {
        switch self {
        case .filled: .filled
        case .isolines: .isolines(color: color)
        case .both: .filledWithIsolines(color: color)
        }
    }
}

enum IsolineColorOption: String, CaseIterable, Identifiable {
    case gradient = "Gradient"
    case black = "Black"
    case white = "White"

    var id: String { rawValue }

    var color: Color? {
        switch self {
        case .gradient: nil
        case .black: .black
        case .white: .white
        }
    }
}

enum SpacingOption: String, CaseIterable, Identifiable {
    case linear = "Linear"
    case logarithmic = "Logarithmic"

    var id: String { rawValue }

    var spacing: LevelSpacing {
        switch self {
        case .linear: .linear
        case .logarithmic: .logarithmic
        }
    }
}

enum LabelVisibilityOption: String, CaseIterable, Identifiable {
    case thresholds = "Thresholds"
    case lowHigh = "Low/High"
    case hidden = "Hidden"

    var id: String { rawValue }

    var visibility: HeatMapLegend.LabelVisibility {
        switch self {
        case .thresholds: .thresholds
        case .lowHigh: .lowHigh
        case .hidden: .hidden
        }
    }
}
