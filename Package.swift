// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Haystack",
    products: [
        .library(
            name: "Haystack",
            targets: ["Haystack"]
        ),
        .library(
            name: "HaystackClient",
            targets: ["HaystackClient"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Haystack",
            dependencies: []
        ),
        .target(
            name: "HaystackClient",
            dependencies: ["Haystack"]
        ),
        .testTarget(
            name: "HaystackTests",
            dependencies: ["Haystack"]
        ),
        .testTarget(
            name: "HaystackClientTests",
            dependencies: ["HaystackClient"]
        ),
        .testTarget(
            name: "HaystackClientIntegrationTests",
            dependencies: ["HaystackClient"]
        ),
    ]
)
