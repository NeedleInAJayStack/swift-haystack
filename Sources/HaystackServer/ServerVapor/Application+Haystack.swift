#if ServerVapor
import Haystack
import Vapor

extension Application {
    struct HaystackServerKey: StorageKey {
        typealias Value = API & Sendable
    }

    public var haystack: (API & Sendable)? {
        get {
            storage[HaystackServerKey.self]
        }
        set {
            storage[HaystackServerKey.self] = newValue
        }
    }
}

extension Request {
    func haystack() throws -> any API {
        guard let haystack = application.haystack else {
            fatalError("HaystackServer is not configured in the Vapor application.")
        }
        return haystack
    }
}
#endif
