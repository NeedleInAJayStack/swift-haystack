import CryptoKit
import XCTest
@testable import HaystackClient

/// These tests originate from [RFC-5802's SCRAM Authentication Exchange section](https://www.rfc-editor.org/rfc/rfc5802#section-5)
final class SCRAMTests: XCTestCase {
    func testClient() async throws {
        let scram = ScramClient(
            hash: Insecure.SHA1.self,
            username: "user",
            password: "pencil",
            nonce: "fyko+d2lbbFgONRv9qkxdawL"
        )
        
        XCTAssertEqual(
            scram.clientFirstMessage(),
            "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL"
        )
        
        XCTAssertEqual(
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096"
            ),
            "c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts="
        )
        
        XCTAssertNoThrow(
            try scram.validate(
                serverFinalMessage: "v=rmF9pqV8S7suAoZWja4dJRkFsKQ="
            )
        )
    }
}
