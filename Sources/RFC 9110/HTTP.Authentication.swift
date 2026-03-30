// HTTP.Authentication.swift
// swift-rfc-9110
//
// RFC 9110 Section 11: HTTP Authentication
// https://www.rfc-editor.org/rfc/rfc9110.html#section-11
//
// HTTP authentication framework

import ASCII_Primitives
import Parser_Primitives
import RFC_4648
import Standard_Library_Extensions

extension RFC_9110 {
    /// HTTP Authentication (RFC 9110 Section 11)
    ///
    /// HTTP provides a framework for access control and authentication through
    /// challenge-response mechanisms.
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 11: HTTP Authentication](https://www.rfc-editor.org/rfc/rfc9110.html#section-11)
    public enum Authentication {}
}

// MARK: - Authentication Scheme

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

// MARK: - Challenge

extension RFC_9110.Authentication {
    /// WWW-Authenticate challenge (RFC 9110 Section 11.6.1)
    ///
    /// A challenge from the server requesting authentication credentials.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Basic authentication
    /// let challenge = HTTP.Authentication.Challenge(
    ///     scheme: .basic,
    ///     realm: "API Access"
    /// )
    /// // WWW-Authenticate: Basic realm="API Access"
    ///
    /// // Bearer with additional parameters
    /// let bearer = HTTP.Authentication.Challenge(
    ///     scheme: .bearer,
    ///     parameters: ["realm": "example", "scope": "read write"]
    /// )
    /// // WWW-Authenticate: Bearer realm="example", scope="read write"
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 11.6.1: WWW-Authenticate](https://www.rfc-editor.org/rfc/rfc9110.html#section-11.6.1)
    public struct Challenge: Sendable, Equatable {
        /// The authentication scheme
        public let scheme: Scheme

        /// Challenge parameters (e.g., realm, scope)
        public var parameters: [String: String]

        /// Creates an authentication challenge
        ///
        /// - Parameters:
        ///   - scheme: The authentication scheme
        ///   - parameters: Optional challenge parameters
        public init(scheme: Scheme, parameters: [String: String] = [:]) {
            self.scheme = scheme
            self.parameters = parameters
        }

        /// Creates a challenge with a realm
        ///
        /// - Parameters:
        ///   - scheme: The authentication scheme
        ///   - realm: The protection realm
        public init(scheme: Scheme, realm: String) {
            self.scheme = scheme
            self.parameters = ["realm": realm]
        }

        /// The realm parameter, if present
        public var realm: String? {
            parameters["realm"]
        }

        /// Formats the challenge as a header value
        ///
        /// - Returns: The formatted challenge string
        ///
        /// ## Example
        ///
        /// ```swift
        /// let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API")
        /// challenge.headerValue // "Basic realm=\"API\""
        /// ```
        public var headerValue: String {
            var result = scheme.name

            if !parameters.isEmpty {
                let params =
                    parameters
                    .sorted { $0.key < $1.key }
                    .map { key, value in
                        // Quote value if it contains special characters
                        if value.contains(" ") || value.contains(",") || value.contains("=") {
                            return "\(key)=\"\(value)\""
                        } else {
                            return "\(key)=\(value)"
                        }
                    }
                    .joined(separator: ", ")
                result += " \(params)"
            }

            return result
        }

        /// Parses a challenge from a header value
        ///
        /// - Parameter headerValue: The WWW-Authenticate header value
        /// - Returns: A Challenge if parsing succeeds, nil otherwise
        public static func parse(_ headerValue: String) -> Challenge? {
            var input = Parser_Primitives.Parser.ByteInput(utf8: headerValue)

            // Skip leading OWS
            HTTP.Parse.OWS<Parser_Primitives.Parser.ByteInput>().parse(&input)

            // Parse scheme (token)
            guard let schemeSlice = try? HTTP.Parse.Token<Parser_Primitives.Parser.ByteInput>().parse(&input) else {
                return nil
            }
            let scheme = Scheme(String(decoding: schemeSlice, as: UTF8.self))

            // If no more content, scheme-only challenge
            HTTP.Parse.OWS<Parser_Primitives.Parser.ByteInput>().parse(&input)
            guard input.startIndex < input.endIndex else {
                return Challenge(scheme: scheme)
            }

            // Parse comma-separated parameters using Parameter parser
            var parameters: [String: String] = [:]
            while true {
                let saved = input
                guard let param = try? HTTP.Parse.Parameter<Parser_Primitives.Parser.ByteInput>().parse(&input) else {
                    input = saved
                    break
                }
                parameters[String(decoding: param.name, as: UTF8.self)] = String(decoding: param.value, as: UTF8.self)

                // Try to consume OWS "," OWS for next parameter
                HTTP.Parse.OWS<Parser_Primitives.Parser.ByteInput>().parse(&input)
                guard input.startIndex < input.endIndex, input[input.startIndex] == 0x2C else { break }
                input = input[input.index(after: input.startIndex)...]
                HTTP.Parse.OWS<Parser_Primitives.Parser.ByteInput>().parse(&input)
            }

            return Challenge(scheme: scheme, parameters: parameters)
        }
    }
}

// MARK: - Credentials

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

extension RFC_9110.Authentication.Scheme: CustomStringConvertible {
    public var description: String {
        name
    }
}

extension RFC_9110.Authentication.Challenge: CustomStringConvertible {
    public var description: String {
        headerValue
    }
}

extension RFC_9110.Authentication.Credentials: CustomStringConvertible {
    public var description: String {
        headerValue
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

extension RFC_9110.Authentication.Challenge: Codable {}

extension RFC_9110.Authentication.Credentials: Codable {}

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
