import AsyncHTTPClient
import Haystack
import HaystackClientNIO
import NIO
import XCTest

/// To use these tests, run a [Haxall](https://github.com/haxall/haxall) server and set the username and password
/// in the `HAYSTACK_USER` and `HAYSTACK_PASSWORD` environment variables
final class HaystackClientNIOIntegrationTests: XCTestCase {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var httpClient: HTTPClient!
    var client: Client!

    override func setUp() async throws {
        httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
        client = try Client(
            baseUrl: "http://localhost:8080/api/",
            username: ProcessInfo.processInfo.environment["HAYSTACK_USER"] ?? "su",
            password: ProcessInfo.processInfo.environment["HAYSTACK_PASSWORD"] ?? "su",
            httpClient: httpClient
        )
        try await client.open()
    }

    override func tearDown() async throws {
        try await client.close()
        try await httpClient.shutdown()
    }

    func testCloseAndOpen() async throws {
        try print(await client.close())
        try print(await client.open())
    }

    func testAbout() async throws {
        try print(await client.about().toZinc())
    }

    func testDefs() async throws {
        try print(await client.defs().toZinc())
        try print(await client.defs(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.defs(limit: Number(1)).toZinc())
        try print(await client.defs(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    func testLibs() async throws {
        try print(await client.libs().toZinc())
        try print(await client.libs(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.libs(limit: Number(1)).toZinc())
        try print(await client.libs(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    func testOps() async throws {
        try print(await client.ops().toZinc())
        try print(await client.ops(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.ops(limit: Number(1)).toZinc())
        try print(await client.ops(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    func testFiletypes() async throws {
        try print(await client.filetypes().toZinc())
        try print(await client.filetypes(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.filetypes(limit: Number(1)).toZinc())
        try print(await client.filetypes(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    func testRead() async throws {
        try print(await client.read(ids: [Ref("28e7fb47-d67ab19a")]).toZinc())
    }

    func testReadAll() async throws {
        try print(await client.read(filter: "site").toZinc())
    }

    func testHisRead() async throws {
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .today).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .yesterday).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .date(Date("2022-01-01"))).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .dateRange(from: Date("2022-01-01"), to: Date("2022-02-01"))).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .dateTimeRange(from: DateTime("2022-01-01T00:00:00Z"), to: DateTime("2022-02-01T00:00:00Z"))).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .after(DateTime("2022-01-01T00:00:00Z"))).toZinc())
    }

    func testHisWrite() async throws {
        try print(await client.hisWrite(
            id: Ref("28e7fb7d-e20316e0"),
            items: [
                HisItem(ts: DateTime("2022-01-01T00:00:00-07:00 Denver"), val: Number(14)),
            ]
        ).toZinc())
    }

    func testEval() async throws {
        try print(await client.eval(expression: "readAll(site)").toZinc())
    }

    func testWatchUnsub() async throws {
        try print(await client.watchUnsubRemove(watchId: "id", ids: [Ref("28e7fb47-d67ab19a")]))
    }
}
