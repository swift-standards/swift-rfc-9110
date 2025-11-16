// HTTP.Method.swift
// swift-rfc-9110
//
// RFC 9110 Section 9: Methods
// https://www.rfc-editor.org/rfc/rfc9110.html#section-9
//
// The method token indicates the request method to be performed on the
// target resource. The request method is case-sensitive.

import Foundation

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

        /// Creates a method from a raw value with default properties
        ///
        /// For custom methods, assumes not safe, not idempotent, not cacheable
        /// unless explicitly specified otherwise.
        ///
        /// - Parameter rawValue: The method name (case-sensitive)
        public init(rawValue: String) {
            self.init(rawValue, isSafe: false, isIdempotent: false, isCacheable: false)
        }

        // MARK: - Standard Methods (RFC 9110 Section 9.3)

        /// GET: Transfer current representation of target resource (Section 9.3.1)
        ///
        /// Safe, idempotent, cacheable
        public static let get = Method("GET", isSafe: true, isIdempotent: true, isCacheable: true)

        /// HEAD: Same as GET but transfer only status line and header section (Section 9.3.2)
        ///
        /// Safe, idempotent, cacheable
        public static let head = Method("HEAD", isSafe: true, isIdempotent: true, isCacheable: true)

        /// POST: Perform resource-specific processing on request content (Section 9.3.3)
        ///
        /// Not safe, not idempotent, cacheable with explicit freshness info
        public static let post = Method("POST", isSafe: false, isIdempotent: false, isCacheable: true)

        /// PUT: Replace all current representations of target resource (Section 9.3.4)
        ///
        /// Not safe, idempotent, not cacheable
        public static let put = Method("PUT", isSafe: false, isIdempotent: true, isCacheable: false)

        /// DELETE: Remove all current representations of target resource (Section 9.3.5)
        ///
        /// Not safe, idempotent, not cacheable
        public static let delete = Method("DELETE", isSafe: false, isIdempotent: true, isCacheable: false)

        /// CONNECT: Establish tunnel to server identified by target resource (Section 9.3.6)
        ///
        /// Not safe, not idempotent, not cacheable
        public static let connect = Method("CONNECT", isSafe: false, isIdempotent: false, isCacheable: false)

        /// OPTIONS: Describe communication options for target resource (Section 9.3.7)
        ///
        /// Safe, idempotent, not cacheable
        public static let options = Method("OPTIONS", isSafe: true, isIdempotent: true, isCacheable: false)

        /// TRACE: Perform message loop-back test along path to target resource (Section 9.3.8)
        ///
        /// Safe, idempotent, not cacheable
        public static let trace = Method("TRACE", isSafe: true, isIdempotent: true, isCacheable: false)

        // MARK: - Additional Standard Methods

        /// PATCH: Apply partial modifications to a resource (RFC 5789)
        ///
        /// Not safe, not idempotent (by default), not cacheable
        public static let patch = Method("PATCH", isSafe: false, isIdempotent: false, isCacheable: false)

        // MARK: - Equatable

        public static func == (lhs: Method, rhs: Method) -> Bool {
            lhs.rawValue == rhs.rawValue
        }

        // MARK: - Hashable

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
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

// MARK: - CustomStringConvertible

extension RFC_9110.Method: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_9110.Method: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
