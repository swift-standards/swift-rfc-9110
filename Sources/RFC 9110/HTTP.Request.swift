// HTTP.Request.swift
// swift-rfc-9110
//
// RFC 9110 Section 9: Methods
// RFC 9110 Section 7: Request Semantics
// https://www.rfc-editor.org/rfc/rfc9110.html#section-7
//
// HTTP request message semantics

import Foundation
import RFC_3986

extension RFC_9110.Request {
    /// HTTP request message per RFC 9110 Section 9
    ///
    /// An HTTP request message consists of a request line (method + target),
    /// header fields, and an optional message body.
    ///
    /// ## Example
    /// ```swift
    /// // Simple GET request
    /// let request = try HTTP.Request(
    ///     method: .get,
    ///     target: .origin(
    ///         path: .init("/api/users"),
    ///         query: .init("page=1")
    ///     ),
    ///     headers: [
    ///         .init(name: "Accept", value: "application/json")
    ///     ]
    /// )
    ///
    /// // POST request with body
    /// let post = try HTTP.Request(
    ///     method: .post,
    ///     target: .origin(path: .init("/api/users"), query: nil),
    ///     headers: [
    ///         .init(name: "Content-Type", value: "application/json")
    ///     ],
    ///     body: jsonData
    /// )
    /// ```
    ///
    /// ## RFC 9110 Reference
    ///
    /// From RFC 9110 Section 3.4:
    /// ```
    /// HTTP-message   = start-line CRLF
    ///                  *( field-line CRLF )
    ///                  CRLF
    ///                  [ message-body ]
    ///
    /// start-line     = request-line / status-line
    /// request-line   = method SP request-target SP HTTP-version
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 3: Message Format](https://www.rfc-editor.org/rfc/rfc9110.html#section-3)
    /// - [RFC 9110 Section 7: Request Semantics](https://www.rfc-editor.org/rfc/rfc9110.html#section-7)
    /// - [RFC 9110 Section 9: Methods](https://www.rfc-editor.org/rfc/rfc9110.html#section-9)
    public struct Message: Sendable, Equatable, Hashable {
        // MARK: - Request Line Components

        /// HTTP method (required per RFC 9110 Section 9)
        ///
        /// The method token indicates the request method to be performed on the target resource.
        public var method: RFC_9110.Method

        /// Request-target (required per RFC 9110 Section 7.1)
        ///
        /// The request-target identifies the resource upon which to apply the request.
        /// See `Target` for the four forms defined by RFC 9110.
        public var target: Target

        // MARK: - Message Components

        /// Header fields (case-insensitive per RFC 9110 Section 5.1)
        ///
        /// Each header field consists of a case-insensitive field name followed by a
        /// colon (":"), optional whitespace, the field value, and optional trailing whitespace.
        ///
        /// Use subscript for convenient access: `request.headers["content-type"]?.first`
        public var headers: RFC_9110.Headers

        /// Message body (optional per RFC 9110 Section 6.4)
        ///
        /// The message body (if any) carries the content of the request.
        public var body: Data?

        // MARK: - Initialization

        /// Creates an HTTP request message
        ///
        /// - Parameters:
        ///   - method: The HTTP method (required)
        ///   - target: The request-target (required)
        ///   - headers: The header fields (defaults to empty)
        ///   - body: The message body (optional)
        public init(
            method: RFC_9110.Method,
            target: Target,
            headers: RFC_9110.Headers = [],
            body: Data? = nil
        ) {
            self.method = method
            self.target = target
            self.headers = headers
            self.body = body
        }

        /// Convenience initializer that constructs target from individual URI components
        ///
        /// This initializer provides a more ergonomic API for constructing requests by
        /// accepting individual typed URI components and building the correct request-target.
        ///
        /// - Parameters:
        ///   - method: The HTTP method (defaults to GET)
        ///   - scheme: The URI scheme. If provided with host, creates absolute-form target
        ///   - userinfo: The userinfo component
        ///   - host: The host. If provided with scheme, creates absolute-form target
        ///   - port: The port number
        ///   - path: The path component. Defaults to root path "/"
        ///   - query: The query component
        ///   - headers: The header fields (defaults to empty)
        ///   - body: The message body (optional)
        public init(
            method: RFC_9110.Method = .get,
            scheme: RFC_3986.URI.Scheme? = nil,
            userinfo: RFC_3986.URI.Userinfo? = nil,
            host: RFC_3986.URI.Host? = nil,
            port: RFC_3986.URI.Port? = nil,
            path: RFC_3986.URI.Path = "/",
            query: RFC_3986.URI.Query? = nil,
            headers: RFC_9110.Headers = [],
            body: Data? = nil
        ) {
            // Determine request target form based on components
            let target: Target

            if let scheme = scheme, let host = host {
                // Absolute-form: construct URI from components
                let authority = RFC_3986.URI.Authority(
                    userinfo: userinfo,
                    host: host,
                    port: port
                )

                let uri = RFC_3986.URI(
                    scheme: scheme,
                    authority: authority,
                    path: path,
                    query: query,
                    fragment: nil
                )

                target = .absolute(uri)
            } else {
                // Origin-form: just path and query
                target = .origin(path: path, query: query)
            }

            self.init(
                method: method,
                target: target,
                headers: headers,
                body: body
            )
        }

        // MARK: - Convenience Accessors

        /// Gets the value(s) of a header field by name
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: An array of values for that header field
        ///
        /// Header field names are case-insensitive per RFC 9110 Section 5.1.
        public func header(_ name: RFC_9110.Header.Field.Name) -> [RFC_9110.Header.Field.Value] {
            headers[name.rawValue] ?? []
        }

        /// Gets the first value of a header field by name
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: The first value for that header field, or nil if not present
        public func firstHeader(_ name: RFC_9110.Header.Field.Name) -> RFC_9110.Header.Field.Value? {
            headers[name.rawValue]?.first
        }

        /// Adds a header field
        ///
        /// - Parameter field: The header field to add
        /// - Returns: A new request with the header field added
        public func addingHeader(_ field: RFC_9110.Header.Field) -> Message {
            var copy = self
            copy.headers.append(field)
            return copy
        }

        /// Removes all header fields with the given name
        ///
        /// - Parameter name: The header field name to remove (case-insensitive)
        /// - Returns: A new request with the header fields removed
        public func removingHeaders(_ name: RFC_9110.Header.Field.Name) -> Message {
            var copy = self
            copy.headers.removeAll(named: name.rawValue)
            return copy
        }

        // MARK: - Convenience Accessors for Request Target Components

        /// Path component from the request target, if applicable
        ///
        /// Returns the path for origin-form and absolute-form request targets.
        /// Returns nil for authority-form and asterisk-form.
        public var path: RFC_3986.URI.Path? {
            target.path
        }

        /// Query component from the request target, if applicable
        ///
        /// Returns the query for origin-form and absolute-form request targets.
        /// Returns nil for authority-form, asterisk-form, or when no query is present.
        public var query: RFC_3986.URI.Query? {
            target.query
        }

        /// Scheme component from the request target, if applicable
        ///
        /// Returns the scheme for absolute-form request targets.
        /// Returns nil for other forms (scheme comes from connection context).
        public var scheme: RFC_3986.URI.Scheme? {
            guard case .absolute(let uri) = target,
                  let schemeString = uri.scheme else {
                return nil
            }
            return try? RFC_3986.URI.Scheme(schemeString)
        }

        /// Authority component from the request target, if applicable
        ///
        /// Returns the authority for absolute-form and authority-form request targets.
        /// Returns nil for origin-form and asterisk-form.
        public var authority: RFC_3986.URI.Authority? {
            switch target {
            case .absolute(let uri):
                // Try to construct authority from URI components
                guard let host = uri.host,
                      let hostEnum = try? RFC_3986.URI.Host(host) else {
                    return nil
                }
                let port = uri.port.flatMap { UInt16(exactly: $0) }.map { RFC_3986.URI.Port($0) }
                return RFC_3986.URI.Authority(
                    userinfo: uri.userinfo,
                    host: hostEnum,
                    port: port
                )
            case .authority(let authority):
                return authority
            case .origin, .asterisk:
                return nil
            }
        }

        /// Host component from the request target, if applicable
        ///
        /// Returns the host for absolute-form and authority-form request targets.
        /// Returns nil for origin-form and asterisk-form.
        public var host: RFC_3986.URI.Host? {
            authority?.host
        }

        // MARK: - Validation

        /// Validates that the request is well-formed according to RFC 9110
        ///
        /// - Throws: `ValidationError` if the request is invalid
        ///
        /// ## Validation Rules
        ///
        /// - authority-form can only be used with CONNECT (RFC 9110 Section 7.1)
        /// - CONNECT can only be used with authority-form (RFC 9110 Section 7.1)
        /// - asterisk-form can only be used with OPTIONS (RFC 9110 Section 7.1)
        /// - OPTIONS with asterisk-form is for server-wide queries (RFC 9110 Section 7.1)
        public func validate() throws {
            // Validate method compatibility with request-target form
            switch target {
            case .authority:
                // authority-form is only used with CONNECT
                guard method == .connect else {
                    throw ValidationError.invalidMethodForTarget(
                        method: method,
                        target: target,
                        reason: "authority-form can only be used with CONNECT method (RFC 9110 §7.1)"
                    )
                }

            case .asterisk:
                // asterisk-form is only used with OPTIONS
                guard method == .options else {
                    throw ValidationError.invalidMethodForTarget(
                        method: method,
                        target: target,
                        reason: "asterisk-form can only be used with OPTIONS method (RFC 9110 §7.1)"
                    )
                }

            case .origin, .absolute:
                // CONNECT can only be used with authority-form
                if method == .connect {
                    throw ValidationError.invalidMethodForTarget(
                        method: method,
                        target: target,
                        reason: "CONNECT method can only be used with authority-form (RFC 9110 §7.1)"
                    )
                }
            }

            // Additional request-specific validation
            // (header validation is already done in Header.Field.Value initialization)
        }

        // MARK: - Validation Error

        /// Errors that occur during request validation
        public enum ValidationError: Error, Sendable, LocalizedError {
            /// Invalid method for the request-target form
            case invalidMethodForTarget(
                method: RFC_9110.Method,
                target: Target,
                reason: String
            )

            public var errorDescription: String? {
                switch self {
                case .invalidMethodForTarget(let method, let target, let reason):
                    return "Invalid method '\(method.rawValue)' for request-target '\(target)': \(reason)"
                }
            }
        }
    }
}

// MARK: - Codable

extension RFC_9110.Request.Message: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(RFC_9110.Method.self, forKey: .method)
        let target = try container.decode(RFC_9110.Request.Target.self, forKey: .target)
        let headers = try container.decodeIfPresent(RFC_9110.Headers.self, forKey: .headers) ?? []
        let body = try container.decodeIfPresent(Data.self, forKey: .body)

        self.init(
            method: method,
            target: target,
            headers: headers,
            body: body
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(method, forKey: .method)
        try container.encode(target, forKey: .target)
        if !headers.isEmpty {
            try container.encode(Array(headers), forKey: .headers)
        }
        if let body = body {
            try container.encode(body, forKey: .body)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case method
        case target
        case headers
        case body
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Request.Message: CustomStringConvertible {
    /// Returns a string representation of the request
    ///
    /// Format: "METHOD /path HTTP/1.1\nHeader: Value\n..."
    public var description: String {
        var result = "\(method.rawValue) \(target.rawValue)"
        for header in headers {
            result += "\n\(header.description)"
        }
        if let body = body {
            result += "\n\n[Body: \(body.count) bytes]"
        }
        return result
    }
}
