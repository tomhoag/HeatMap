# HeatMap

A Swift package for rendering geographic heat maps as filled contour polygons inside SwiftUI `Map` views. It uses Gaussian kernel density estimation and the marching squares algorithm to turn weighted coordinate data into smooth, color-graded contour layers.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftomhoag%2FHeatMap%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/tomhoag/HeatMap)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftomhoag%2FHeatMap%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/tomhoag/HeatMap)

## Features

- **Gaussian kernel density estimation** with configurable radius and grid resolution
- **Marching squares contour extraction** with Chaikin polygon smoothing
- **Cooperative Task cancellation** — the async `compute` method checks for cancellation between pipeline stages (after the density grid, between contour levels, and between polygon smoothing passes), so cancelled Tasks exit early instead of running to completion
- **Multiple render modes** — filled polygons, contour lines (isolines), or both
- **Configurable fill opacity and polygon stroke** for fine-tuned rendering control
- **Built-in color gradients** (thermal, warm, cool, monochrome) plus custom gradient support
- **Adaptive configuration** that auto-derives radius and resolution from your data
- **Gradient legend view** with configurable axis and label visibility
- **Localized strings** — user-facing legend labels use `String(localized:)` so consuming apps can provide translations via their string catalogs

## Requirements

- iOS 17+ / macOS 14+ / visionOS 1+
- Swift 6.2+
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
| `levelSpacing` | `.linear` | Threshold spacing strategy (`.linear`, `.logarithmic`, or `.custom([Double])`). |
| `gridResolution` | `100` | Grid cells along the longer axis. Higher values increase detail and computation time. |
| `gradient` | `.thermal` | Color gradient for mapping density to color. |
| `paddingFactor` | `1.5` | Bounding box padding as a multiple of `radius`. |
| `fillOpacity` | `1.0` | Fill opacity for contour polygons (`0`–`1`). |
| `stroke` | `.none` | Polygon stroke style (`.none` or `.styled(color:lineWidth:)`). |
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

By default thresholds are evenly spaced across the density range. For data with long-tail distributions (population density, precipitation, seismic activity), logarithmic spacing concentrates more contour levels in the lower-density region:

```swift
let config = HeatMapConfiguration(levelSpacing: .logarithmic)
```

You can also provide explicit threshold values. Values outside the computed density range are automatically filtered out:

```swift
let config = HeatMapConfiguration(levelSpacing: .custom([0.1, 0.5, 1.0, 5.0, 10.0]))
```

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

## Example App

The repository includes **HeatMapExample**, an iOS app that demonstrates the library with GSOD (Global Summary of the Day) weather station data plotted on a map.

### Running the Example

1. Open `HeatMapExample/HeatMap.xcodeproj` in Xcode.
2. The project already references the local `HeatMap` package.
3. Select an iOS simulator or device and run.

The example app loads weather station coordinates from a bundled JSON file and renders them as a heat map. A control panel (tap the **Controls** button) lets you adjust the radius, contour levels, color gradient, fill opacity, polygon stroke, render mode, and smoothing in real time.

## Documentation

Full API documentation is available at [Swift Package Index](https://swiftpackageindex.com/tomhoag/HeatMap).

## License

See [LICENSE](LICENSE) for details.
