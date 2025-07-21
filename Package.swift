// swift-tools-version: 6.1

import PackageDescription

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
            name: "HaystackClient",
            targets: [
                "HaystackClient",
            ]
        ),
        .library(
            name: "HaystackServer",
            targets: [
                "HaystackServer",
            ]
        ),
    ],
    traits: [
        "ServerVapor",
        "ClientNIO",
        "ClientDarwin",
        .default(enabledTraits: []),
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
                .product(name: "AsyncHTTPClient", package: "async-http-client", condition: .when(traits: ["ClientNIO"])),
            ]
        ),
        .target(
            name: "HaystackServer",
            dependencies: [
                "Haystack",
                .product(name: "Vapor", package: "vapor", condition: .when(traits: ["ServerVapor"])),
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
            name: "HaystackServerTests",
            dependencies: [
                "HaystackServer",
                .product(name: "VaporTesting", package: "vapor", condition: .when(traits: ["ServerVapor"])),
            ]
        ),
    ]
)
