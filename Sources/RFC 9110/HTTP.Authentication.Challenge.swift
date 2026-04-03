// HTTP.Authentication.Challenge.swift
// swift-rfc-9110

import Parser_Primitives

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
            var input = Parser_Primitives.Parser.Input.Bytes(utf8: headerValue)

            // Skip leading OWS
            HTTP.Parse.OWS<Parser_Primitives.Parser.Input.Bytes>().parse(&input)

            // Parse scheme (token)
            guard let schemeSlice = try? HTTP.Parse.Token<Parser_Primitives.Parser.Input.Bytes>().parse(&input) else {
                return nil
            }
            let scheme = Scheme(String(decoding: schemeSlice, as: UTF8.self))

            // If no more content, scheme-only challenge
            HTTP.Parse.OWS<Parser_Primitives.Parser.Input.Bytes>().parse(&input)
            guard input.startIndex < input.endIndex else {
                return Challenge(scheme: scheme)
            }

            // Parse comma-separated parameters using Parameter parser
            var parameters: [String: String] = [:]
            while true {
                let saved = input
                guard let param = try? HTTP.Parse.Parameter<Parser_Primitives.Parser.Input.Bytes>().parse(&input) else {
                    input = saved
                    break
                }
                parameters[String(decoding: param.name, as: UTF8.self)] = String(decoding: param.value, as: UTF8.self)

                // Try to consume OWS "," OWS for next parameter
                HTTP.Parse.OWS<Parser_Primitives.Parser.Input.Bytes>().parse(&input)
                guard input.startIndex < input.endIndex, input[input.startIndex] == 0x2C else { break }
                input = input[input.index(after: input.startIndex)...]
                HTTP.Parse.OWS<Parser_Primitives.Parser.Input.Bytes>().parse(&input)
            }

            return Challenge(scheme: scheme, parameters: parameters)
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Authentication.Challenge: CustomStringConvertible {
    public var description: String {
        headerValue
    }
}

// MARK: - Codable

extension RFC_9110.Authentication.Challenge: Codable {}
