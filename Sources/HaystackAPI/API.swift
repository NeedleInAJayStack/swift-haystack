import Haystack

public protocol API {
    
    /// Queries basic information about the server
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#about
    func about() async throws -> Dict
    
    /// Closes the current authentication session.
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#close
    func close() async throws
    
    /// Queries def dicts from the current namespace
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#defs
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of defs to return in response
    /// - Returns: A grid with the dict representation of each def
    func defs(filter: String?, limit: Number?) async throws -> Grid
    
    /// Queries lib defs from current namspace
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#libs
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of defs to return in response
    /// - Returns: A grid with the dict representation of each def
    func libs(filter: String?, limit: Number?) async throws -> Grid
    
    /// Queries op defs from current namspace
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#ops
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of defs to return in response
    /// - Returns: A grid with the dict representation of each def
    func ops(filter: String?, limit: Number?) async throws -> Grid
    
    /// Read a set of entity records by their unique identifier
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#read
    ///
    /// - Parameter ids: Ref identifiers
    /// - Returns: A grid with a row for each entity read
    func read(ids: [Ref]) async throws -> Grid
    
    /// Read a set of entity records using a filter
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#read
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of entities to return in response
    /// - Returns: A grid with a row for each entity read
    func read(filter: String, limit: Number?) async throws -> Grid
    
    /// Navigate a project for learning and discovery
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#nav
    ///
    /// - Parameter navId: The ID of the entity to navigate from. If null, the navigation root is used.
    /// - Returns: A grid of navigation children for the navId specified by the request
    func nav(navId: Ref?) async throws -> Grid
    
    /// Used to create new watches.
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchSub
    ///
    /// - Parameters:
    ///   - watchDis: Debug/display string
    ///   - lease: Number with duration unit for desired lease period
    ///   - ids: The identifiers of the entities to subscribe to
    /// - Returns: A grid where rows correspond to the current entity state of the requested identifiers.  Grid metadata contains
    /// `watchId` and `lease`.
    func watchSubCreate(watchDis: String, lease: Number?, ids: [Ref]) async throws -> Grid
    
    /// Used to add entities to an existing watch.
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchSub
    ///
    /// - Parameters:
    ///   - watchId: Debug/display string
    ///   - lease: Number with duration unit for desired lease period
    ///   - ids: The identifiers of the entities to subscribe to
    /// - Returns: A grid where rows correspond to the current entity state of the requested identifiers.  Grid metadata contains
    /// `watchId` and `lease`.
    func watchSubAdd(watchId: String, lease: Number?, ids: [Ref]) async throws -> Grid
    
    /// Used to close a watch entirely or remove entities from a watch
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchUnsub
    ///
    /// - Parameters:
    ///   - watchId: Watch identifier
    ///   - ids: Ref values for each entity to unsubscribe. If empty the entire watch is closed.
    func watchUnsub(watchId: String, ids: [Ref]) async throws
    
    /// Used to poll a watch for changes to the subscribed entity records
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchPoll
    ///
    /// - Parameters:
    ///   - watchId: Watch identifier
    ///   - refresh: Whether a full refresh should occur
    /// - Returns: A grid where each row correspondes to a watched entity
    func watchPoll(watchId: String, refresh: Bool) async throws -> Grid
    
    /// Write to a given level of a writable point's priority array
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#pointWrite
    ///
    /// - Parameters:
    ///   - id: Identifier of writable point
    ///   - level: Number from 1-17 for level to write
    ///   - val: Value to write or null to auto the level
    ///   - who: Username/application name performing the write, otherwise authenticated user display name is used
    ///   - duration: Number with duration unit if setting level 8
    func pointWrite(id: Ref, level: Number, val: any Val, who: String?, duration: Number?) async throws
    
    /// Read the current status of a writable point's priority array
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#pointWrite
    ///
    /// - Parameter id: Identifier of writable point
    /// - Returns: A grid with current priority array state
    func pointWriteStatus(id: Ref) async throws -> Grid
    
    /// Reads time-series data from historized point
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
    ///
    /// - Parameters:
    ///   - id: Identifier of historized point
    ///   - range: A date-time range
    /// - Returns: A grid whose rows represent timetamp/value pairs with a DateTime ts column and a val column for each scalar value
    func hisRead(id: Ref, range: HisReadRange) async throws -> Grid
    
    /// Posts new time-series data to a historized point
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#hisWrite
    ///
    /// - Parameters:
    ///   - id: The identifier of the point to write to
    ///   - items: New timestamp/value samples to write
    func hisWrite(id: Ref, items: [HisItem]) async throws
    
    /// https://project-haystack.org/doc/docHaystack/Ops#invokeAction
    /// - Parameters:
    ///   - id: Identifier of target rec
    ///   - action: The name of the action func
    ///   - args: The arguments to the action
    /// - Returns: A grid of undefined shape
    func invokeAction(id: Ref, action: String, args: Dict) async throws -> Grid
}
