import Crypto
@testable import HaystackClient
import Testing

struct SCRAMTests {
    let scram = ScramClient(
        hash: Insecure.SHA1.self,
        username: "user",
        password: "pencil",
        nonce: "fyko+d2lbbFgONRv9qkxdawL"
    )

    /// Tests example from [RFC-5802's SCRAM Authentication Exchange section](https://www.rfc-editor.org/rfc/rfc5802#section-5)
    @Test func clientExample() async throws {
        #expect(scram.clientFirstMessage() == "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL")

        #expect(
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096"
            ) == "c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts="
        )

        #expect(throws: Never.self) {
            try scram.validate(serverFinalMessage: "v=rmF9pqV8S7suAoZWja4dJRkFsKQ=")
        }
    }

    @Test func serverFirstMessageResponseErrors() async throws {
        #expect(scram.clientFirstMessage() == "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL")

        // Server first message has no nonce attribute
        #expect(throws: (any Error).self) {
            try scram.clientFinalMessage(
                serverFirstMessage: "s=QSXCR+Q6sek8bf92,i=4096"
            )
        }

        // Server first message has no salt attribute
        #expect(throws: (any Error).self) {
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,i=4096"
            )
        }

        // Server first message has no iteration attribute
        #expect(throws: (any Error).self) {
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92"
            )
        }

        // Server first message iteration is not integer
        #expect(throws: (any Error).self) {
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=BAD"
            )
        }

        // Server nonce isn't prefixed with client nonce
        #expect(throws: (any Error).self) {
            try scram.clientFinalMessage(
                serverFirstMessage: "r=BAD_fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096"
            )
        }
    }

    @Test func serverFinalMessageValidateErrors() async throws {
        #expect(scram.clientFirstMessage() == "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL")

        #expect(
            try scram.clientFinalMessage(
                serverFirstMessage: "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096"
            ) == "c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts="
        )

        // Throws if server final message is unexpected
        #expect(throws: (any Error).self) {
            try scram.validate(serverFinalMessage: "v=BAD_rmF9pqV8S7suAoZWja4dJRkFsKQ=")
        }

        // Throws if server final message has error attribute
        #expect(throws: (any Error).self) {
            try scram.validate(serverFinalMessage: "e=No way Jose,v=rmF9pqV8S7suAoZWja4dJRkFsKQ=")
        }

        // Throws if server final message has no server key attribute
        #expect(throws: (any Error).self) {
            try scram.validate(serverFinalMessage: "n=user")
        }
    }
}
