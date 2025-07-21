@testable import HaystackClient
import Testing

struct UrlSafeBase64Tests {
    @Test func encodeStandard() throws {
        #expect("user".encodeBase64Standard() == "dXNlcg==")
    }

    @Test func encodeUrlSafe() throws {
        #expect("user".encodeBase64UrlSafe() == "dXNlcg")
    }

    @Test func decodeStandard() throws {
        #expect("dXNlcg==".decodeBase64Standard() == "user")
    }

    @Test func decodeUrlSafe() throws {
        #expect("dXNlcg".decodeBase64UrlSafe() == "user")
    }
}
