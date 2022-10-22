// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Haystack",
    products: [
        .library(
            name: "Haystack",
            targets: ["Haystack"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Haystack",
            dependencies: []
        ),
        .testTarget(
            name: "HaystackTests",
            dependencies: ["Haystack"]
        ),
    ]
)
