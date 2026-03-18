// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HeatMap",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2),
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
