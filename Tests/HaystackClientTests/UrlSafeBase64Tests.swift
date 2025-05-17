@testable import HaystackClient
import XCTest

final class UrlSafeBase64Tests: XCTestCase {
    func testEncodeStandard() throws {
        XCTAssertEqual(
            "user".encodeBase64Standard(),
            "dXNlcg=="
        )
    }

    func testEncodeUrlSafe() throws {
        XCTAssertEqual(
            "user".encodeBase64UrlSafe(),
            "dXNlcg"
        )
    }

    func testDecodeStandard() throws {
        XCTAssertEqual(
            "dXNlcg==".decodeBase64Standard(),
            "user"
        )
    }

    func testDecodeUrlSafe() throws {
        XCTAssertEqual(
            "dXNlcg".decodeBase64UrlSafe(),
            "user"
        )
    }
}
