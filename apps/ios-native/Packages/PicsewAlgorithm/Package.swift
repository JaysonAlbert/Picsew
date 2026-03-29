// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PicsewAlgorithm",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PicsewAlgorithm",
            targets: ["PicsewAlgorithm"]
        ),
    ],
    targets: [
        .target(
            name: "PicsewAlgorithm"
        ),
        .testTarget(
            name: "PicsewAlgorithmTests",
            dependencies: ["PicsewAlgorithm"]
        ),
    ]
)
