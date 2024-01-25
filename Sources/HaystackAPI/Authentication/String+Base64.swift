import Foundation

public extension String {
    func encodeBase64Standard() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    func decodeBase64Standard() -> String {
        let data = Data(base64Encoded: self)!
        let string = String(data: data, encoding: .utf8)!
        return string
    }
    
    func encodeBase64UrlSafe() -> String {
        self.encodeBase64Standard()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
    
    func decodeBase64UrlSafe() -> String {
        var base64 = self.replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")
        // Add necessary `=` padding
        let trailingCharCount = base64.count % 4
        if trailingCharCount != 0 {
            base64.append(String(repeating: "=", count: 4 - trailingCharCount))
        }
        return base64.decodeBase64Standard()
    }
}
