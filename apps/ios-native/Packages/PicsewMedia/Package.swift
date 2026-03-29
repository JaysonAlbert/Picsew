// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PicsewMedia",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PicsewMedia",
            targets: ["PicsewMedia"]
        ),
    ],
    targets: [
        .target(
            name: "PicsewMedia"
        ),
        .testTarget(
            name: "PicsewMediaTests",
            dependencies: ["PicsewMedia"]
        ),
    ]
)
