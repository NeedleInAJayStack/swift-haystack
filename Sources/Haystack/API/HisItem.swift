/// A timestamp/value pair.
public struct HisItem {
    public let ts: DateTime
    public let val: any Val
    
    public init(ts: DateTime, val: any Val) {
        self.ts = ts
        self.val = val
    }
    
    public func toDict() -> Dict {
        return ["ts": ts, "val": val]
    }
}
