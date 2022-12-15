/// Haystack data serialization formats. For more information, see
/// https://project-haystack.org/doc/docHaystack/HttpApi#contentNegotiation
public enum DataFormat: String {
    case json
    case zinc
    
    // See Content Negotiation: https://haxall.io/doc/docHaystack/HttpApi.html#contentNegotiation
    var acceptHeaderValue: String {
        switch self {
        case .json: return "application/json"
        case .zinc: return "text/zinc"
        }
    }
    
    var contentTypeHeaderValue: String {
        switch self {
        case .json: return "application/json"
        case .zinc: return "text/zinc; charset=utf-8"
        }
    }
}
