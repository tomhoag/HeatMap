// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HeatMap",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
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
