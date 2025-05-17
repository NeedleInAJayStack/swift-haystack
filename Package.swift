// swift-tools-version: 5.7

import PackageDescription

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    let package = Package(
        name: "Haystack",
        platforms: [
            .macOS(.v12),
            .iOS(.v15),
            .tvOS(.v15),
            .watchOS(.v8),
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
                    "HaystackClientDarwin",
                ]
            ),
            .library(
                name: "HaystackClientNIO",
                targets: [
                    "HaystackClient",
                    "HaystackClientNIO",
                ]
            ),
            .library(
                name: "HaystackServer",
                targets: [
                    "HaystackServer",
                ]
            ),
            .library(
                name: "HaystackServerVapor",
                targets: [
                    "HaystackServerVapor",
                ]
            ),
        ],
        dependencies: [
            .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
            .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
            .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
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
            .target(
                name: "HaystackServer",
                dependencies: [
                    "Haystack",
                ]
            ),
            .target(
                name: "HaystackServerVapor",
                dependencies: [
                    "Haystack",
                    "HaystackServer",
                    .product(name: "Vapor", package: "vapor"),
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
            .testTarget(
                name: "HaystackServerTests",
                dependencies: ["HaystackServer"]
            ),
            .testTarget(
                name: "HaystackServerVaporTests",
                dependencies: ["HaystackServerVapor", .product(name: "XCTVapor", package: "vapor")]
            ),
        ]
    )
#else
    let package = Package(
        name: "Haystack",
        products: [
            .library(
                name: "Haystack",
                targets: ["Haystack"]
            ),
            .library(
                name: "HaystackClientNIO",
                targets: [
                    "HaystackClient",
                    "HaystackClientNIO",
                ]
            ),
            .library(
                name: "HaystackServer",
                targets: [
                    "HaystackServer",
                ]
            ),
            .library(
                name: "HaystackServerVapor",
                targets: [
                    "HaystackServerVapor",
                ]
            ),
        ],
        dependencies: [
            .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
            .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
            .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
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
                name: "HaystackClientNIO",
                dependencies: [
                    "Haystack",
                    "HaystackClient",
                    .product(name: "AsyncHTTPClient", package: "async-http-client"),
                ]
            ),
            .target(
                name: "HaystackServer",
                dependencies: [
                    "Haystack",
                ]
            ),
            .target(
                name: "HaystackServerVapor",
                dependencies: [
                    "Haystack",
                    "HaystackServer",
                    .product(name: "Vapor", package: "vapor"),
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
                name: "HaystackServerTests",
                dependencies: ["HaystackServer"]
            ),
            .testTarget(
                name: "HaystackServerVaporTests",
                dependencies: ["HaystackServerVapor", .product(name: "XCTVapor", package: "vapor")]
            ),
        ]
    )
#endif
