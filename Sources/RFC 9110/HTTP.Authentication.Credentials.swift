// HTTP.Authentication.Credentials.swift
// swift-rfc-9110

import RFC_4648
import Standard_Library_Extensions

extension RFC_9110.Authentication {
    /// Authorization credentials (RFC 9110 Section 11.6.2)
    ///
    /// Credentials provided by the client to authenticate with the server.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Basic authentication
    /// let basic = HTTP.Authentication.Credentials(
    ///     scheme: .basic,
    ///     token: "dXNlcjpwYXNzd29yZA=="
    /// )
    /// // Authorization: Basic dXNlcjpwYXNzd29yZA==
    ///
    /// // Bearer token
    /// let bearer = HTTP.Authentication.Credentials(
    ///     scheme: .bearer,
    ///     token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    /// )
    /// // Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 11.6.2: Authorization](https://www.rfc-editor.org/rfc/rfc9110.html#section-11.6.2)
    public struct Credentials: Sendable, Equatable {
        /// The authentication scheme
        public let scheme: Scheme

        /// The credentials token
        public let token: String

        /// Creates authentication credentials
        ///
        /// - Parameters:
        ///   - scheme: The authentication scheme
        ///   - token: The credentials token
        public init(scheme: Scheme, token: String) {
            self.scheme = scheme
            self.token = token
        }

        /// The header value for the Authorization header
        ///
        /// ## Example
        ///
        /// ```swift
        /// let creds = HTTP.Authentication.Credentials.bearer("abc123")
        /// creds.headerValue // "Bearer abc123"
        /// ```
        public var headerValue: String {
            "\(scheme.name) \(token)"
        }

        /// Parses credentials from an Authorization header value
        ///
        /// - Parameter headerValue: The Authorization header value
        /// - Returns: Credentials if parsing succeeds, nil otherwise
        public static func parse(_ headerValue: String) -> Credentials? {
            let trimmed = String(headerValue.trimming(where: { $0.isWhitespace }))

            guard let spaceIndex = trimmed.firstIndex(of: " ") else {
                return nil
            }

            let schemeName = String(trimmed[..<spaceIndex])
            let scheme = Scheme(schemeName)

            let token = String(String(trimmed[trimmed.index(after: spaceIndex)...])
                .trimming(where: { $0.isWhitespace }))

            return Credentials(scheme: scheme, token: token)
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Authentication.Credentials: CustomStringConvertible {
    public var description: String {
        headerValue
    }
}

// MARK: - Codable

extension RFC_9110.Authentication.Credentials: Codable {}

// MARK: - Credentials Factory Methods

extension RFC_9110.Authentication.Credentials {
    /// Creates Basic authentication credentials
    ///
    /// - Parameters:
    ///   - username: The username
    ///   - password: The password
    /// - Returns: Basic authentication credentials
    ///
    /// ## Example
    ///
    /// ```swift
    /// let creds = HTTP.Authentication.Credentials.basic(
    ///     username: "user",
    ///     password: "pass"
    /// )
    /// // Authorization: Basic dXNlcjpwYXNz
    /// ```
    public static func basic(
        username: String,
        password: String
    ) -> RFC_9110.Authentication.Credentials {
        let combined = "\(username):\(password)"
        let bytes = Swift.Array(combined.utf8)
        let encoded = String.base64(bytes)
        return Self(scheme: .basic, token: encoded)
    }

    /// Creates Bearer token credentials
    ///
    /// - Parameter token: The bearer token
    /// - Returns: Bearer token credentials
    public static func bearer(_ token: String) -> RFC_9110.Authentication.Credentials {
        Self(scheme: .bearer, token: token)
    }
}
