// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PicsewApp",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PicsewApp",
            targets: ["PicsewApp"]
        ),
    ],
    dependencies: [
        .package(path: "../Packages/PicsewAppCore"),
        .package(path: "../Packages/PicsewAlgorithm"),
    ],
    targets: [
        .target(
            name: "PicsewApp",
            dependencies: [
                .product(name: "PicsewAppCore", package: "PicsewAppCore"),
                .product(name: "PicsewAlgorithm", package: "PicsewAlgorithm"),
            ],
            path: ".",
            exclude: [
                "Package.swift",
                "README.md",
                "Resources",
                "Support",
                "Tests",
            ],
            sources: [
                "App",
                "Core",
                "Features",
            ]
        ),
        .testTarget(
            name: "PicsewAppTests",
            dependencies: [
                "PicsewApp",
                .product(name: "PicsewAppCore", package: "PicsewAppCore"),
                .product(name: "PicsewAlgorithm", package: "PicsewAlgorithm"),
            ],
            path: "Tests/PicsewAppTests"
        ),
    ]
)
