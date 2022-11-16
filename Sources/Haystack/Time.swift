import Foundation

/// Time is an ISO 8601 time of day. It is encoded as `hh:mm:ss.sss`.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#time)
public struct Time: Val {
    public static var valType: ValType { .Time }
    
    public let hour: Int
    public let minute: Int
    public let second: Int
    public let millisecond: Int
    
    public init(hour: Int, minute: Int, second: Int, millisecond: Int = 0) throws {
        guard
            0 <= hour, hour < 24,
            0 <= minute, minute < 60,
            0 <= second, second < 60,
            0 <= millisecond, millisecond < 1000
        else {
            throw ValError.invalidTimeDefinition
        }
        
        self.hour = hour
        self.minute = minute
        self.second = second
        self.millisecond = millisecond
    }
    
    public init(_ isoString: String) throws {
        let colonSplit = isoString.split(separator: ":")
        guard colonSplit.count == 3 else {
            throw ValError.invalidTimeFormat(isoString)
        }
        let hourStr = colonSplit[0]
        let minuteStr = colonSplit[1]
        let secondAndMilliStr = colonSplit[2]
        let secondAndMilliSplit = secondAndMilliStr.split(separator: ".")
        let secondStr = secondAndMilliSplit[0]
        
        guard
            let hour = Int(hourStr),
            let minute = Int(minuteStr),
            let second = Int(secondStr)
        else {
            throw ValError.invalidTimeFormat(isoString)
        }
        
        self.hour = hour
        self.minute = minute
        self.second = second
        
        if secondAndMilliStr.contains(".") {
            var millisecondStr = secondAndMilliSplit[1]
            guard millisecondStr.count <= 3 else {
                throw ValError.invalidTimeFormat(isoString)
            }
            // Append 0's until it's 3 digits long
            while millisecondStr.count < 3 {
                millisecondStr.append("0")
            }
            guard let millisecond = Int(millisecondStr) else {
                throw ValError.invalidTimeFormat(isoString)
            }
            self.millisecond = millisecond
        } else {
            self.millisecond = 0
        }
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return isoString
    }
    
    var isoString: String {
        let hourStr = String(format: "%02d", arguments: [hour])
        let minuteStr = String(format: "%02d", arguments: [minute])
        let secondStr = String(format: "%02d", arguments: [second])
        var isoString = "\(hourStr):\(minuteStr):\(secondStr)"
        
        if millisecond != 0 {
            let millisecondStr = String(format: "%03d", arguments: [millisecond])
            isoString += ".\(millisecondStr)"
        }
        return isoString
    }
}

extension Time {
    static let kindValue = "time"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
    }
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#date)
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Self.CodingKeys) {
            guard try container.decode(String.self, forKey: ._kind) == Self.kindValue else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys._kind],
                        debugDescription: "Expected `_kind` to have value `\"\(Self.kindValue)\"`"
                    )
                )
            }
            
            let isoString = try container.decode(String.self, forKey: .val)
            do {
                try self.init(isoString)
            } catch {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys.val],
                        debugDescription: "Time `val` did not match expected format."
                    )
                )
            }
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Date representation must be an object"
                )
            )
        }
    }
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#time)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(isoString, forKey: .val)
    }
}
