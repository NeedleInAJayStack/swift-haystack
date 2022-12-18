// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Haystack",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
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
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
    ],
    targets: [
        .target(
            name: "Haystack",
            dependencies: []
        ),
        .target(
            name: "HaystackClient",
            dependencies: [
                "Haystack",
                .product(name: "Crypto", package: "swift-crypto")
            ]
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
