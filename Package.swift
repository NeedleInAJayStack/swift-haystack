// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Haystack",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "Haystack",
            targets: ["Haystack"]
        ),
        .library(
            name: "HaystackClientDarwin",
            targets: [
                "HaystackClient",
                "HaystackClientDarwin"
            ]
        ),
        .library(
            name: "HaystackClientNIO",
            targets: [
                "HaystackClient",
                "HaystackClientNIO"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0")
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
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .target(
            name: "HaystackClientDarwin",
            dependencies: [
                "Haystack",
                "HaystackClient",
            ]
        ),
        .target(
            name: "HaystackClientNIO",
            dependencies: [
                "Haystack",
                "HaystackClient",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        
        // Tests
        .testTarget(
            name: "HaystackTests",
            dependencies: ["Haystack"]
        ),
        .testTarget(
            name: "HaystackClientTests",
            dependencies: ["HaystackClient"]
        ),
        .testTarget(
            name: "HaystackClientNIOIntegrationTests",
            dependencies: ["HaystackClientNIO"]
        ),
        .testTarget(
            name: "HaystackClientDarwinIntegrationTests",
            dependencies: ["HaystackClientDarwin"]
        ),
    ]
)
