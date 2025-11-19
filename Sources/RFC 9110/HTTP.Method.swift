// HTTP.Method.swift
// swift-rfc-9110
//
// RFC 9110 Section 9: Methods
// https://www.rfc-editor.org/rfc/rfc9110.html#section-9
//
// The method token indicates the request method to be performed on the
// target resource. The request method is case-sensitive.


extension RFC_9110 {
    /// HTTP Method (RFC 9110 Section 9)
    ///
    /// An HTTP method indicates the desired action to be performed on a resource.
    ///
    /// Properties (RFC 9110 Section 9.2):
    /// - `isSafe`: Safe methods are read-only (Section 9.2.1)
    /// - `isIdempotent`: Idempotent methods produce same result when called multiple times (Section 9.2.2)
    /// - `isCacheable`: Cacheable methods allow responses to be stored and reused (Section 9.2.3)
    ///
    /// Standard methods defined in RFC 9110 Section 9.3:
    /// - GET: Transfer current representation of target resource (Section 9.3.1)
    /// - HEAD: Same as GET but transfer only status line and header section (Section 9.3.2)
    /// - POST: Perform resource-specific processing on request content (Section 9.3.3)
    /// - PUT: Replace all current representations of target resource (Section 9.3.4)
    /// - DELETE: Remove all current representations of target resource (Section 9.3.5)
    /// - CONNECT: Establish tunnel to server identified by target resource (Section 9.3.6)
    /// - OPTIONS: Describe communication options for target resource (Section 9.3.7)
    /// - TRACE: Perform message loop-back test along path to target resource (Section 9.3.8)
    ///
    /// Additional standard method from RFC 5789:
    /// - PATCH: Apply partial modifications to a resource
    public struct Method: Hashable, Sendable, Codable, RawRepresentable {
        /// The method name (case-sensitive)
        public let rawValue: String

        /// Safe methods are essentially read-only (RFC 9110 Section 9.2.1)
        ///
        /// A request method is "safe" if it does not request any state change on the origin server.
        /// Safe methods: GET, HEAD, OPTIONS, TRACE
        public let isSafe: Bool

        /// Idempotent methods produce the same result when called multiple times (RFC 9110 Section 9.2.2)
        ///
        /// A request method is "idempotent" if the intended effect on the server of multiple
        /// identical requests with that method is the same as the effect for a single such request.
        /// Idempotent methods: GET, HEAD, PUT, DELETE, OPTIONS, TRACE
        public let isIdempotent: Bool

        /// Cacheable methods allow responses to be stored and reused (RFC 9110 Section 9.2.3)
        ///
        /// A request method is "cacheable" if responses to it can be stored for future reuse.
        /// Cacheable methods: GET, HEAD, POST (with explicit freshness info)
        public let isCacheable: Bool

        /// Creates a method with specified properties
        ///
        /// - Parameters:
        ///   - rawValue: The method name (case-sensitive)
        ///   - isSafe: Whether the method is safe (read-only)
        ///   - isIdempotent: Whether the method is idempotent
        ///   - isCacheable: Whether responses can be cached
        public init(
            _ rawValue: String,
            isSafe: Bool,
            isIdempotent: Bool,
            isCacheable: Bool
        ) {
            self.rawValue = rawValue
            self.isSafe = isSafe
            self.isIdempotent = isIdempotent
            self.isCacheable = isCacheable
        }

        /// Creates a method from a raw value
        ///
        /// If the rawValue matches a standard method, returns that method with
        /// its correct properties. Otherwise creates a custom method with
        /// default properties (not safe, not idempotent, not cacheable).
        ///
        /// - Parameter rawValue: The method name (case-sensitive)
        public init(rawValue: String) {
            switch rawValue {
            case "GET":
                self = .get
            case "HEAD":
                self = .head
            case "POST":
                self = .post
            case "PUT":
                self = .put
            case "DELETE":
                self = .delete
            case "CONNECT":
                self = .connect
            case "OPTIONS":
                self = .options
            case "TRACE":
                self = .trace
            case "PATCH":
                self = .patch
            default:
                // Custom method: defaults to unsafe, non-idempotent, non-cacheable
                self.init(rawValue, isSafe: false, isIdempotent: false, isCacheable: false)
            }
        }

        // MARK: - Equatable

        public static func == (lhs: Method, rhs: Method) -> Bool {
            lhs.rawValue == rhs.rawValue &&
            lhs.isSafe == rhs.isSafe &&
            lhs.isIdempotent == rhs.isIdempotent &&
            lhs.isCacheable == rhs.isCacheable
        }

        // MARK: - Hashable

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
            hasher.combine(isSafe)
            hasher.combine(isIdempotent)
            hasher.combine(isCacheable)
        }

        // MARK: - Codable

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            // Try to find a standard method first
            let standardMethods: [Method] = [
                .get, .head, .post, .put, .delete,
                .connect, .options, .trace, .patch
            ]

            if let standard = standardMethods.first(where: { $0.rawValue == rawValue }) {
                self = standard
            } else {
                // Custom method with default properties
                self.init(rawValue: rawValue)
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
}

// MARK: - Standard Methods

extension RFC_9110.Method {
    /// GET: Transfer current representation of target resource (Section 9.3.1)
    ///
    /// Safe, idempotent, cacheable
    public static let get = Self("GET", isSafe: true, isIdempotent: true, isCacheable: true)

    /// HEAD: Same as GET but transfer only status line and header section (Section 9.3.2)
    ///
    /// Safe, idempotent, cacheable
    public static let head = Self("HEAD", isSafe: true, isIdempotent: true, isCacheable: true)

    /// POST: Perform resource-specific processing on request content (Section 9.3.3)
    ///
    /// Not safe, not idempotent, cacheable with explicit freshness info
    public static let post = Self("POST", isSafe: false, isIdempotent: false, isCacheable: true)

    /// PUT: Replace all current representations of target resource (Section 9.3.4)
    ///
    /// Not safe, idempotent, not cacheable
    public static let put = Self("PUT", isSafe: false, isIdempotent: true, isCacheable: false)

    /// DELETE: Remove all current representations of target resource (Section 9.3.5)
    ///
    /// Not safe, idempotent, not cacheable
    public static let delete = Self("DELETE", isSafe: false, isIdempotent: true, isCacheable: false)

    /// CONNECT: Establish tunnel to server identified by target resource (Section 9.3.6)
    ///
    /// Not safe, not idempotent, not cacheable
    public static let connect = Self("CONNECT", isSafe: false, isIdempotent: false, isCacheable: false)

    /// OPTIONS: Describe communication options for target resource (Section 9.3.7)
    ///
    /// Safe, idempotent, not cacheable
    public static let options = Self("OPTIONS", isSafe: true, isIdempotent: true, isCacheable: false)

    /// TRACE: Perform message loop-back test along path to target resource (Section 9.3.8)
    ///
    /// Safe, idempotent, not cacheable
    public static let trace = Self("TRACE", isSafe: true, isIdempotent: true, isCacheable: false)

    /// PATCH: Apply partial modifications to a resource (RFC 5789)
    ///
    /// Not safe, not idempotent (by default), not cacheable
    public static let patch = Self("PATCH", isSafe: false, isIdempotent: false, isCacheable: false)
}

// MARK: - CustomStringConvertible

extension RFC_9110.Method: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - LosslessStringConvertible

extension RFC_9110.Method: LosslessStringConvertible {
    /// Creates a method from a string description
    ///
    /// - Parameter description: The method name (e.g., "GET", "POST")
    /// - Returns: A method instance, or nil if the string is invalid
    ///
    /// # Example
    ///
    /// ```swift
    /// let method = HTTP.Method("GET")  // Returns .get with correct properties
    /// let str = String(method)         // "GET" - perfect round-trip
    /// ```
    public init?(_ description: String) {
        self.init(rawValue: description)
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_9110.Method: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CaseIterable

extension RFC_9110.Method: CaseIterable {
    /// All standard HTTP methods defined in RFC 9110 and RFC 5789
    ///
    /// Returns the 9 standard methods:
    /// - RFC 9110 Section 9.3: GET, HEAD, POST, PUT, DELETE, CONNECT, OPTIONS, TRACE
    /// - RFC 5789: PATCH
    ///
    /// ## Important Note
    ///
    /// This collection contains only the **standard methods** defined by RFCs.
    /// Custom methods created via `Method("CUSTOM")` will not appear in this collection.
    /// Use this for:
    /// - UI pickers showing standard methods
    /// - Validation: `Method.allCases.contains(method)`
    /// - Documentation and tooling
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Enumerate standard methods
    /// for method in HTTP.Method.allCases {
    ///     print(method.rawValue)  // GET, HEAD, POST, PUT, DELETE, CONNECT, OPTIONS, TRACE, PATCH
    /// }
    ///
    /// // Check if method is standard
    /// let isStandard = HTTP.Method.allCases.contains(requestMethod)
    /// ```
    public static var allCases: [RFC_9110.Method] {
        [.get, .head, .post, .put, .delete, .connect, .options, .trace, .patch]
    }
}
