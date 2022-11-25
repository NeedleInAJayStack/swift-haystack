import CryptoKit
import XCTest
@testable import HaystackClient

final class SCRAMTests: XCTestCase {
    let scram = ScramClient(
        hash: Insecure.SHA1.self,
        username: "user",
        password: "pencil",
        nonce: "fyko+d2lbbFgONRv9qkxdawL"
    )
    
    /// Tests example from [RFC-5802's SCRAM Authentication Exchange section](https://www.rfc-editor.org/rfc/rfc5802#section-5)
    func testClientExample() async throws {
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
            try scram.validate(serverFinalMessage: "v=rmF9pqV8S7suAoZWja4dJRkFsKQ=")
        )
    }
    
    func testServerFirstMessageResponseErrors() async throws {
        XCTAssertEqual(
            scram.clientFirstMessage(),
            "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL"
        )
        
        // Server first message has no nonce attribute
        XCTAssertThrowsError(
            try scram.clientFinalMessage(
                serverFirstMessage: "s=QSXCR+Q6sek8bf92,i=4096"
            )
        )
        
        // Server first message has no salt attribute
        XCTAssertThrowsError(
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,i=4096"
            )
        )
        
        // Server first message has no iteration attribute
        XCTAssertThrowsError(
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92"
            )
        )
        
        // Server first message iteration is not integer
        XCTAssertThrowsError(
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=BAD"
            )
        )
        
        // Server nonce isn't prefixed with client nonce
        XCTAssertThrowsError(
            try scram.clientFinalMessage(
                serverFirstMessage: "r=BAD_fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096"
            )
        )
        
    }
    
    func testServerFinalMessageValidateErrors() async throws {
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
        
        // Throws if server final message is unexpected
        XCTAssertThrowsError(
            try scram.validate(serverFinalMessage: "v=BAD_rmF9pqV8S7suAoZWja4dJRkFsKQ=")
        )
        
        // Throws if server final message has error attribute
        XCTAssertThrowsError(
            try scram.validate(serverFinalMessage: "e=No way Jose,v=rmF9pqV8S7suAoZWja4dJRkFsKQ=")
        )
        
        // Throws if server final message has no server key attribute
        XCTAssertThrowsError(
            try scram.validate(serverFinalMessage: "n=user")
        )
    }
}
