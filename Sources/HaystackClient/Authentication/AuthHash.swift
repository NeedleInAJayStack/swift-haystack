import CryptoKit

@available(macOS 10.15, *)
enum AuthHash: String {
    case SHA512 = "SHA-512"
    case SHA256 = "SHA-256"
    
    var hash: any HashFunction.Type {
        switch self {
        case .SHA256:
            return CryptoKit.SHA256.self
        case .SHA512:
            return CryptoKit.SHA512.self
        }
    }
}
