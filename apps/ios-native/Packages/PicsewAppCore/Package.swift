// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PicsewAppCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PicsewAppCore",
            targets: ["PicsewAppCore"]
        ),
    ],
    dependencies: [
        .package(path: "../PicsewAlgorithm"),
        .package(path: "../PicsewMedia"),
    ],
    targets: [
        .target(
            name: "PicsewAppCore",
            dependencies: [
                .product(name: "PicsewAlgorithm", package: "PicsewAlgorithm"),
                .product(name: "PicsewMedia", package: "PicsewMedia"),
            ]
        ),
        .testTarget(
            name: "PicsewAppCoreTests",
            dependencies: ["PicsewAppCore"]
        ),
    ]
)
