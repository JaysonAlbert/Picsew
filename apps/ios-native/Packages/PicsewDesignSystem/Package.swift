// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PicsewDesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PicsewDesignSystem",
            targets: ["PicsewDesignSystem"]
        ),
    ],
    targets: [
        .target(
            name: "PicsewDesignSystem"
        ),
        .testTarget(
            name: "PicsewDesignSystemTests",
            dependencies: ["PicsewDesignSystem"]
        ),
    ]
)
