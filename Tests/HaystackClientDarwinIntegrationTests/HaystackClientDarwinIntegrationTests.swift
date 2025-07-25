import Foundation
import Haystack
import HaystackClientDarwin
import Testing

/// To use these tests, run a [Haxall](https://github.com/haxall/haxall) server and set the username and password
/// in the `HAYSTACK_USER` and `HAYSTACK_PASSWORD` environment variables
struct HaystackClientDarwinIntegration {
    var client: Client = try! Client(
        baseUrl: "http://localhost:8080/api/",
        username: ProcessInfo.processInfo.environment["HAYSTACK_USER"] ?? "su",
        password: ProcessInfo.processInfo.environment["HAYSTACK_PASSWORD"] ?? "su"
    )

    @Test func closeAndOpen() async throws {
        try print(await client.close())
        try print(await client.open())
    }

    @Test func about() async throws {
        try print(await client.about().toZinc())
    }

    @Test func defs() async throws {
        try print(await client.defs().toZinc())
        try print(await client.defs(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.defs(limit: Number(1)).toZinc())
        try print(await client.defs(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    @Test func libs() async throws {
        try print(await client.libs().toZinc())
        try print(await client.libs(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.libs(limit: Number(1)).toZinc())
        try print(await client.libs(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    @Test func ops() async throws {
        try print(await client.ops().toZinc())
        try print(await client.ops(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.ops(limit: Number(1)).toZinc())
        try print(await client.ops(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    @Test func filetypes() async throws {
        try print(await client.filetypes().toZinc())
        try print(await client.filetypes(filter: "lib==^lib:phIoT").toZinc())
        try print(await client.filetypes(limit: Number(1)).toZinc())
        try print(await client.filetypes(filter: "lib==^lib:phIoT", limit: Number(1)).toZinc())
    }

    @Test func read() async throws {
        try print(await client.read(ids: [Ref("28e7fb47-d67ab19a")]).toZinc())
    }

    @Test func readAll() async throws {
        try print(await client.read(filter: "site").toZinc())
    }

    @Test func hisRead() async throws {
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .today).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .yesterday).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .date(Date("2022-01-01"))).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .dateRange(from: Date("2022-01-01"), to: Date("2022-02-01"))).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .dateTimeRange(from: DateTime("2022-01-01T00:00:00Z"), to: DateTime("2022-02-01T00:00:00Z"))).toZinc())
        try print(await client.hisRead(id: Ref("28e7fb7d-e20316e0"), range: .after(DateTime("2022-01-01T00:00:00Z"))).toZinc())
    }

    @Test func hisWrite() async throws {
        try print(await client.hisWrite(
            id: Ref("28e7fb7d-e20316e0"),
            items: [
                HisItem(ts: DateTime("2022-01-01T00:00:00-07:00 Denver"), val: Number(14)),
            ]
        ).toZinc())
    }

    @Test func eval() async throws {
        try print(await client.eval(expression: "readAll(site)").toZinc())
    }

    @Test func watchUnsub() async throws {
        try print(await client.watchUnsubRemove(watchId: "id", ids: [Ref("28e7fb47-d67ab19a")]))
    }
}
