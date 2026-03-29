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
    dependencies: [
        .package(path: "../PicsewMedia"),
    ],
    targets: [
        .target(
            name: "PicsewAlgorithm",
            dependencies: [
                .product(name: "PicsewMedia", package: "PicsewMedia"),
            ]
        ),
        .testTarget(
            name: "PicsewAlgorithmTests",
            dependencies: [
                "PicsewAlgorithm",
                .product(name: "PicsewMedia", package: "PicsewMedia"),
            ]
        ),
    ]
)
