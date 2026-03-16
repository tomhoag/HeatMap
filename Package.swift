// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HeatMap",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "HeatMap",
            targets: ["HeatMap"]
        ),
    ],
    targets: [
        .target(
            name: "HeatMap",
            path: "Sources/HeatMap"
        ),
        .testTarget(
            name: "HeatMapTests",
            dependencies: ["HeatMap"],
            path: "Tests/HeatMapTests"
        ),
    ]
)
