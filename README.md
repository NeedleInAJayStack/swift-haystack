# Swift Haystack

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNeedleInAJayStack%2Fswift-haystack%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NeedleInAJayStack/swift-haystack)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNeedleInAJayStack%2Fswift-haystack%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NeedleInAJayStack/swift-haystack)

An implementation of [Project Haystack](https://project-haystack.org/) in Swift.

## Getting Started

To use this package, add it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/NeedleInAJayStack/swift-haystack.git", from: "0.0.0"),
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "Haystack", package: "swift-haystack"),
        ]
    ),
]
```

You can then import and use the different libraries:

```swift
import Haystack

func testGrid() throws -> Grid {
    return try ZincReader(
        """
        ver:"3.0" foo:"bar"
        dis dis:"Equip Name", equip, siteRef, installed
        "RTU-1", M, @153c-699a HQ, 2005-06-01
        "RTU-2", M, @153c-699b Library, 1997-07-12
        """
    ).readGrid()
}
```

See below for available libraries and descriptions.

## Available Packages

### Haystack

This contains the
[Haystack type-system primitives](https://project-haystack.org/doc/docHaystack/Kinds)
and utilities to interact with them.

### HaystackClientDarwin

A Darwin-only client driver for the
[Haystack HTTP API](https://project-haystack.org/doc/docHaystack/HttpApi) that
requires minimal dependencies. Use this if you are only deploying to MacOS, iOS, etc and want
to reduce dependencies.

Here's an example of how to use it:

```swift
import HaystackClientDarwin

func client() throws -> Client {
    return try Client(
        baseUrl: "http://mydomain.com/api/",
        username: "username",
        password: "password"
    )
}
```

### HaystackClientNIO

A cross-platform client driver for the
[Haystack HTTP API](https://project-haystack.org/doc/docHaystack/HttpApi) that
has larger dependency requirements. Use this if you are only deploying to Linux or if you
are deploying to Darwin platforms and are willing to accept more dependencies.

Here's an example of how to use it:

```swift
import HaystackClientNIO

func client() throws -> Client {
    let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
    return try Client(
        baseUrl: "http://mydomain.com/api/",
        username: "username",
        password: "password",
        httpClient: httpClient
    )
}
```

### HaystackClient

This defines the main functionality of Haystack API clients. It should not be imported directly;
its assets are imported automatically by `HaystackClientDarwin` or `HaystackClientNIO`.

Once you create a client, you can use it to make requests:

```swift
func yesterdaysValues() async throws -> Grid {
    let client = ...

    // Open and authenticate. This must be called before requests can be made
    try await client.open()

    // Request the historical values for @28e7fb7d-e20316e0
    let grid = try await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .yesterday)

    // Close the client session and log out
    try await client.close()

    return grid
}
```

### HaystackServerVapor

A server for the [Haystack HTTP API](https://project-haystack.org/doc/docHaystack/HttpApi) that uses
[Vapor](https://github.com/vapor/vapor). It's separated from the `HaystackServer` package so that clients may use
alternative server technologies if they choose, including Hummingbird or NIO directly.

It exposes a `HaystackRouteCollection` that can be registered on a Vapor
application:

```swift
let app = Application()
try app.register(collection: HaystackRouteCollection(delegate: ...))
```

The delegate is a protocol that can be implemented however the user sees fit, although the standard Haystack
implementation is defined in `HaystackServer`.

### HaystackServer

This defines the standard functionality and data processing of Haystack API servers, based on generic backing data
stores. In most cases, Haystack servers should use the `HaystackServer` class and customize storage behavior by
implementing the `RecordStore`, `HistoryStore`, and `WatchStore` protocols.

```swift
struct InfluxHistoryStore: HistoryStore {
    // Define storage behavior here
    ...
}

let server = HaystackServer(
    historyStore: InfluxHistoryStore(),
    ...
)
```

## License

This package is licensed under the Academic Free License 3.0 for maximum compatibility with
Project Haystack itself.
