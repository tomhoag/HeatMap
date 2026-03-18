# HeatMap

Add heat maps to SwiftUI's `Map` view with just a few lines of code:

```swift
Map {
    HeatMapLayer(contours: contours)
}
.task {
    let config = HeatMapConfiguration.adaptive(for: points)
    contours = try? await HeatMapContours.compute(from: points, configuration: config)
}
```

HeatMap is a native SwiftUI `MapContent` component — no image overlays, no UIKit bridging, no tile servers. It renders vector contour polygons directly inside `Map`, so you get smooth scaling, hit testing, and full integration with the MapKit camera, gestures, and annotations you already use.

<!-- Add a screenshot: ![HeatMap screenshot](Assets/hero.png) -->

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftomhoag%2FHeatMap%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/tomhoag/HeatMap)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftomhoag%2FHeatMap%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/tomhoag/HeatMap)

## Features

- **Drop-in `MapContent`** — `HeatMapLayer` works like any other `Map` content. No view representables, no coordinate conversions, no z-ordering hacks.
- **Works out of the box** — `HeatMapConfiguration.adaptive(for:)` inspects your data and picks a sensible radius and resolution automatically. Get a meaningful map before you've tuned anything.
- **Async and cancellation-aware** — compute contours off the main thread with `async`/`await`. Switching configurations or navigating away cancels stale work automatically.
- **Multiple render modes** — filled polygons, contour isolines, or both together. Four built-in color gradients plus a `HeatMapGradient(colors:)` API for your own.
- **Fully configurable** — kernel radius, contour levels, grid resolution, level spacing (auto, linear, logarithmic, quantile, or custom thresholds), fill opacity, and polygon smoothing are all adjustable.
- **Built-in legend** — `HeatMapLegend` renders the color scale with configurable orientation, label visibility, and custom endpoint text. Localization-ready out of the box.
- **Hit testing** — query which contour levels contain a given coordinate, for tap-to-inspect interactions.
- **Scales from city blocks to continents** — the same configuration API works whether your data spans a neighborhood or a country.

## Requirements

- iOS 17+ / macOS 14+ / visionOS 1+
- Swift 6.0+
- Xcode 16+

## Installation

Add HeatMap as a Swift Package Manager dependency:

### In Xcode

1. Open your project in Xcode.
2. Go to **File → Add Package Dependencies…**
3. Enter the repository URL: `https://github.com/tomhoag/HeatMap.git`
4. Choose your version rule and add the package.

### In `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/tomhoag/HeatMap.git", from: "1.0.0")
]
```

Then add `"HeatMap"` to the target's `dependencies`:

```swift
.target(
    name: "YourTarget",
    dependencies: ["HeatMap"]
)
```

## Usage

### 1. Conform Your Data to `HeatMapable`

Your data model must conform to `HeatMapable`, which requires `coordinate` and `weight` properties:

```swift
import CoreLocation
import HeatMap

struct SensorReading: HeatMapable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let weight: Double
}
```

`weight` must be non-negative. Higher values contribute more to the density field; a weight of `0` makes the point invisible.

### 2. Add a Heat Map Layer to a Map

Compute contours and pass them to `HeatMapLayer`. The async variant is recommended for large datasets to avoid blocking the UI; a synchronous overload is also available for smaller datasets or background contexts:

```swift
import HeatMap
import MapKit
import SwiftUI

struct MyMapView: View {
    let points: [SensorReading]
    @State private var contours: HeatMapContours?

    var body: some View {
        Map {
            if let contours {
                HeatMapLayer(contours: contours)
            }
        }
        .task {
            contours = try? await HeatMapContours.compute(from: points)
        }
    }
}
```

### 3. Customize with `HeatMapConfiguration`

Control the appearance and computation through `HeatMapConfiguration`:

```swift
let config = HeatMapConfiguration(
    radius: 1000,          // Gaussian kernel radius in meters
    contourLevels: 12,     // number of contour bands
    gridResolution: 120,   // grid cells along the longer axis
    gradient: .cool,       // color gradient (.thermal, .warm, .cool, or custom)
    smoother: .chaikin(iterations: 2)  // polygon smoothing (default)
)

contours = try? await HeatMapContours.compute(from: points, configuration: config)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `radius` | `500` | Gaussian kernel radius in meters. Larger values produce smoother, more diffuse maps. |
| `contourLevels` | `10` | Number of contour bands. More levels produce a finer gradient. |
| `levelSpacing` | `.auto` | Threshold spacing strategy (`.auto`, `.linear`, `.logarithmic`, `.quantile`, or `.custom([Double])`). |
| `gridResolution` | `100` | Grid cells along the longer axis. Higher values increase detail and computation time. |
| `gradient` | `.thermal` | Color gradient for mapping density to color. |
| `paddingFactor` | `1.5` | Bounding box padding as a multiple of `radius`. |
| `fillOpacity` | `1.0` | Fill opacity for contour polygons (`0`–`1`). |
| `renderMode` | `.filled` | Contour rendering mode (`.filled`, `.isolines(lineWidth:color:)`, or `.filledWithIsolines(lineWidth:color:)`). |
| `smoother` | `.chaikin()` | Polygon smoother to reduce stair-step artifacts. |

### 4. Adaptive Configuration

If you don't know the geographic scale of your data in advance, let the library pick a reasonable `radius` and `gridResolution` for you:

```swift
let config = HeatMapConfiguration.adaptive(for: points)
contours = try? await HeatMapContours.compute(from: points, configuration: config)
```

You can still override individual properties afterward:

```swift
var config = HeatMapConfiguration.adaptive(for: points)
config.gradient = .cool
```

**Note:** The adaptive configuration is a snapshot of the current point set. If points change dynamically, you must call `adaptive(for:)` again, which may shift the radius or resolution and cause a visual discontinuity. For stable visuals with dynamic data, prefer setting configuration values explicitly.

### 5. Contour Level Spacing

The `levelSpacing` parameter controls how density thresholds are distributed between the grid's minimum and maximum values. Choosing the right strategy depends on your data distribution:

#### Auto (default)

Inspects the computed density grid and automatically selects linear or quantile spacing based on how skewed the distribution is. When the mean-to-median ratio of non-zero density values exceeds 2 (indicating high-density peaks pulling the average well above typical values), quantile spacing is used. Otherwise, linear spacing is used.

```swift
let config = HeatMapConfiguration(levelSpacing: .auto)
```

**Use when:** you don't know the characteristics of your data in advance, or you want reasonable results across a variety of datasets without manual tuning. This is the default.

#### Linear

Thresholds are evenly spaced across the density range. Best for data where points are distributed relatively uniformly and you want each contour band to represent the same density difference:

```swift
let config = HeatMapConfiguration(levelSpacing: .linear)
```

**Use when:** point density is fairly uniform, or you want a perceptually linear mapping between color and density (e.g. a tight sensor grid, evenly distributed samples).

#### Logarithmic

Concentrates more contour levels in the lower-density region while still covering the full range. Best for data with long-tail distributions where most of the variation occurs at lower values:

```swift
let config = HeatMapConfiguration(levelSpacing: .logarithmic)
```

**Use when:** your data has a wide dynamic range but most detail is in the lower densities (e.g. population density near a city center, precipitation data, seismic activity).

#### Quantile

Places thresholds at equal-area percentiles of the actual density distribution rather than dividing the range arithmetically. This guarantees contours appear even in sparse regions where density values are far below the global maximum:

```swift
let config = HeatMapConfiguration(levelSpacing: .quantile)
```

**Use when:** your data has highly uneven spatial density — dense clusters in some areas and sparse coverage in others (e.g. weather station networks where coastal cities have many stations but rural interiors have few, cell tower maps with urban/rural contrast, species observation data with sampling bias).

**Trade-off:** because thresholds adapt to the data distribution, the density difference between adjacent contour bands is not constant. A band in a dense area may span a much larger density range than a band in a sparse area. The map will look more "filled in" but the visual uniformity can overstate the similarity between regions of very different density.

#### Custom

Provide explicit threshold values for full control. Values outside the computed density range are automatically filtered out:

```swift
let config = HeatMapConfiguration(levelSpacing: .custom([0.1, 0.5, 1.0, 5.0, 10.0]))
```

**Use when:** you know the density values that matter for your domain and want exact control over where contour boundaries fall.

### 6. Render Modes

By default contours are rendered as filled polygons. You can switch to contour lines (isolines), or combine both:

```swift
// Contour lines only, colored by gradient
let config = HeatMapConfiguration(renderMode: .isolines(lineWidth: 2))

// Uniform black isolines
let config = HeatMapConfiguration(renderMode: .isolines(lineWidth: 1, color: .black))

// Filled polygons with white isoline overlay
let config = HeatMapConfiguration(renderMode: .filledWithIsolines(color: .white))
```

When `color` is `nil` (the default), each isoline is colored by the configured gradient at its contour level.

### 7. Recompute When Configuration Changes

Use `.task(id:)` to recompute contours whenever the configuration changes:

```swift
@State private var contours: HeatMapContours?
@State private var config = HeatMapConfiguration()

var body: some View {
    Map {
        if let contours { 
            HeatMapLayer(contours: contours)
        }
    }
    .task(id: config) {
        contours = try? await HeatMapContours.compute(from: points, configuration: config)
    }
}
```

### 8. Access Contour Geometry

The computed contours expose their underlying polygon data for export or custom visualizations:

```swift
let result = try await HeatMapContours.compute(from: points)
for contour in result.contours {
    print("Level \(contour.level), threshold \(contour.threshold): \(contour.coordinates.count) vertices")
}
```

You can also hit-test a coordinate against the contours to find which levels contain it:

```swift
let hits = result.contours(containing: coordinate)
```

### 9. Add a Gradient Legend

Display a legend showing the color scale alongside the map:

```swift
Map {
    if let contours {
        HeatMapLayer(contours: contours)
    }
}
.overlay(alignment: .bottomLeading) {
    HeatMapLegend(gradient: config.gradient, levelCount: config.contourLevels)
        .padding()
}
```

For threshold labels derived from computed contours:

```swift
HeatMapLegend(contours: computedContours)
```

Configure the axis and label visibility with modifiers:

```swift
HeatMapLegend(gradient: .thermal, levelCount: 10)
    .axis(.horizontal)
    .labels(.hidden)
```

Force "Low" and "High" labels even when threshold data is available:

```swift
HeatMapLegend(contours: computedContours)
    .labels(.lowHigh)
```

Use custom endpoint labels:

```swift
HeatMapLegend(gradient: .thermal, levelCount: 10)
    .labels(.customLowHigh(low: "Cold", high: "Hot"))
```

Override the label color for better contrast against dark or light map backgrounds:

```swift
HeatMapLegend(gradient: .thermal, levelCount: 10)
    .labelColor(.white)
```

#### Legend Visibility with Isoline Render Modes

When using `.isolines` with a uniform `color` (e.g. `.black` or `.white`), every contour line looks identical regardless of its level, so the gradient legend provides no useful information and should be hidden. When `color` is `nil` (the default), each isoline is colored by the gradient and the legend remains meaningful.

For `.filled` and `.filledWithIsolines` modes the legend is always appropriate because the filled polygons carry gradient color information.

```swift
// Hide the legend when isolines use a uniform color
var showLegend: Bool {
    switch config.renderMode {
    case .isolines(_, let color):
        return color == nil   // gradient-colored → show; uniform color → hide
    case .filled, .filledWithIsolines:
        return true
    }
}
```

### Built-in Gradients

| Gradient | Colors |
|----------|--------|
| `.thermal` | transparent → blue → cyan → green → yellow → orange → red |
| `.warm` | transparent → yellow → orange → red |
| `.cool` | transparent → cyan → blue → purple |
| `.monochrome(color)` | transparent → color in six opacity steps |

Create a custom gradient with `HeatMapGradient(colors:)` (requires at least two colors):

```swift
let custom = HeatMapGradient(colors: [
    .clear,
    .blue.opacity(0.3),
    .green.opacity(0.6),
    .red
])
```

## Example Apps

The repository includes two example apps in `HeatMapExample/HeatMap.xcodeproj`. Both targets reference the local `HeatMap` package — open the project in Xcode, choose a scheme, and run.

### SimpleHeatMapExample

A minimal integration showing the least code needed to get a heat map on screen — no control panels, no file loading. Start here.

### HeatMapExample

A full-featured demo that ships with four CONUS weather event datasets (2021 Texas Freeze, 2021 PNW Heat Dome, 2024 Polar Vortex, 2024 Spring Front). A control panel (tap the **Controls** button) lets you switch datasets and adjust the radius, contour levels, color gradient, fill opacity, render mode, isoline color, and smoothing in real time.

## Documentation

Full API documentation is available at [Swift Package Index](https://swiftpackageindex.com/tomhoag/HeatMap).

## License

See [LICENSE](LICENSE) for details.
