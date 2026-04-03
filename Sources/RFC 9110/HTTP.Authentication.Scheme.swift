// HTTP.Authentication.Scheme.swift
// swift-rfc-9110

extension RFC_9110.Authentication {
    /// HTTP authentication scheme (RFC 9110 Section 11.1)
    ///
    /// An authentication scheme is a method of authenticating a user agent to a server.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let basic = HTTP.Authentication.Scheme.basic
    /// let bearer = HTTP.Authentication.Scheme.bearer
    /// let custom = HTTP.Authentication.Scheme("Digest")
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 11.1: Authentication Scheme](https://www.rfc-editor.org/rfc/rfc9110.html#section-11.1)
    public struct Scheme: Sendable, Equatable, Hashable {
        /// The authentication scheme name (case-insensitive)
        public let name: String

        /// Creates an authentication scheme
        ///
        /// - Parameter name: The scheme name
        public init(_ name: String) {
            self.name = name
        }

        // MARK: - Equatable

        public static func == (lhs: Scheme, rhs: Scheme) -> Bool {
            lhs.name.lowercased() == rhs.name.lowercased()
        }

        // MARK: - Hashable

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name.lowercased())
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Authentication.Scheme: CustomStringConvertible {
    public var description: String {
        name
    }
}

// MARK: - Codable

extension RFC_9110.Authentication.Scheme: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        self.init(name)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_9110.Authentication.Scheme: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - Standard Authentication Schemes

extension RFC_9110.Authentication.Scheme {
    /// Basic authentication (RFC 7617)
    ///
    /// Uses base64-encoded username:password credentials
    public static let basic = Self("Basic")

    /// Bearer token authentication (RFC 6750)
    ///
    /// Used for OAuth 2.0 access tokens
    public static let bearer = Self("Bearer")

    /// Digest authentication (RFC 7616)
    ///
    /// Challenge-response authentication with hashing
    public static let digest = Self("Digest")

    /// Negotiate authentication (RFC 4559)
    ///
    /// SPNEGO-based authentication
    public static let negotiate = Self("Negotiate")

    /// OAuth authentication (RFC 5849)
    public static let oauth = Self("OAuth")
}
