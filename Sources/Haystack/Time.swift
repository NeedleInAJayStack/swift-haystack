import Foundation

public struct Time: Equatable {
    let hour: UInt8
    let minute: UInt8
    let second: UInt8
    let millisecond: UInt16
}

/// See https://project-haystack.org/doc/docHaystack/Json#date
extension Time: Codable {
    static let kindValue = "time"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
    }
    
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
            
            let hourStr = isoString.split(separator: ":")[0]
            let minuteStr = isoString.split(separator: ":")[1]
            let secondAndMilliStr = isoString.split(separator: ":")[2]
            let secondStr = secondAndMilliStr.split(separator: ".")[0]
            
            guard
                let hour = UInt8(hourStr),
                let minute = UInt8(minuteStr),
                let second = UInt8(secondStr)
            else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys.val],
                        debugDescription: "Time `val` did not match expected format."
                    )
                )
            }
            
            self.hour = hour
            self.minute = minute
            self.second = second
            
            if secondAndMilliStr.contains(".") {
                let millisecondStr = secondAndMilliStr.split(separator: ".")[1]
                guard
                    let millisecond = UInt16(millisecondStr)
                else {
                    throw DecodingError.typeMismatch(
                        Self.self,
                        .init(
                            codingPath: [Self.CodingKeys.val],
                            debugDescription: "Time `val` did not match expected format."
                        )
                    )
                }
                self.millisecond = millisecond
            } else {
                self.millisecond = 0
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        
        let hourStr = String(format: "%02d", arguments: [hour])
        let minuteStr = String(format: "%02d", arguments: [minute])
        let secondStr = String(format: "%02d", arguments: [second])
        var isoString = "\(hourStr):\(minuteStr):\(secondStr)"
        
        if millisecond != 0 {
            let millisecondStr = String(format: "%03d", arguments: [millisecond])
            isoString += ".\(millisecondStr)"
        }
        
        try container.encode(isoString, forKey: .val)
    }
}
