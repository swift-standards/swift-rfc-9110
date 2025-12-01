// HTTP.Request.swift
// swift-rfc-9110
//
// RFC 9110 Section 9: Methods
// RFC 9110 Section 7: Request Semantics
// https://www.rfc-editor.org/rfc/rfc9110.html#section-7
//
// HTTP request message semantics

public import RFC_3986

extension RFC_9110 {
    /// HTTP request message per RFC 9110 Section 9
    ///
    /// An HTTP request message consists of a request line (method + target),
    /// header fields, and an optional message body.
    ///
    /// ## Example
    /// ```swift
    /// // Simple GET request
    /// let request = HTTP.Request(
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
    /// let post = HTTP.Request(
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
    public struct Request: Sendable, Equatable, Hashable, Codable {
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
        public var body: [UInt8]?

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
            body: [UInt8]? = nil
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
            path: RFC_3986.URI.Path? = nil,
            query: RFC_3986.URI.Query? = nil,
            headers: RFC_9110.Headers = [],
            body: [UInt8]? = nil
        ) {
            // Determine request target form based on components
            let target: Target

            // Default path to "/" if not provided
            let effectivePath = path ?? (try! RFC_3986.URI.Path("/"))

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
                    path: effectivePath,
                    query: query,
                    fragment: nil
                )

                target = .absolute(uri)
            } else {
                // Origin-form: just path and query
                target = .origin(path: effectivePath, query: query)
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
        public func addingHeader(_ field: RFC_9110.Header.Field) -> Request {
            var copy = self
            copy.headers.append(field)
            return copy
        }

        /// Removes all header fields with the given name
        ///
        /// - Parameter name: The header field name to remove (case-insensitive)
        /// - Returns: A new request with the header fields removed
        public func removingHeaders(_ name: RFC_9110.Header.Field.Name) -> Request {
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
            guard case .absolute(let uri) = target else {
                return nil
            }
            return uri.scheme
        }

        /// Authority component from the request target, if applicable
        ///
        /// Returns the authority for absolute-form and authority-form request targets.
        /// Returns nil for origin-form and asterisk-form.
        public var authority: RFC_3986.URI.Authority? {
            switch target {
            case .absolute(let uri):
                // Try to construct authority from URI components
                guard let host = uri.host else {
                    return nil
                }
                return RFC_3986.URI.Authority(
                    userinfo: uri.userinfo,
                    host: host,
                    port: uri.port
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
                    throw Error.invalidMethodForTarget(
                        method: method,
                        target: target,
                        reason: "authority-form can only be used with CONNECT method (RFC 9110 §7.1)"
                    )
                }

            case .asterisk:
                // asterisk-form is only used with OPTIONS
                guard method == .options else {
                    throw Error.invalidMethodForTarget(
                        method: method,
                        target: target,
                        reason: "asterisk-form can only be used with OPTIONS method (RFC 9110 §7.1)"
                    )
                }

            case .origin, .absolute:
                // CONNECT can only be used with authority-form
                if method == .connect {
                    throw Error.invalidMethodForTarget(
                        method: method,
                        target: target,
                        reason: "CONNECT method can only be used with authority-form (RFC 9110 §7.1)"
                    )
                }
            }

            // Additional request-specific validation
            // (header validation is already done in Header.Field.Value initialization)
        }
    }
}

// MARK: - Request Target

extension RFC_9110.Request {
    /// Request-target per RFC 9110 Section 7.1
    ///
    /// The request-target identifies the resource upon which to apply the request.
    /// RFC 9110 defines four distinct forms, each serving different purposes.
    ///
    /// ## Example
    /// ```swift
    /// // origin-form (most common, used for requests to origin servers)
    /// let origin = HTTP.Request.Target.origin(
    ///     path: .init("/users/123"),
    ///     query: .init("page=1")
    /// )
    ///
    /// // absolute-form (used in requests to proxies)
    /// let absolute = HTTP.Request.Target.absolute(
    ///     .init("http://www.example.org/pub/WWW/TheProject.html")
    /// )
    ///
    /// // authority-form (used only with CONNECT)
    /// let authority = HTTP.Request.Target.authority(
    ///     .init(host: .name("www.example.com"), port: .init(80))
    /// )
    ///
    /// // asterisk-form (used only with OPTIONS)
    /// let asterisk = HTTP.Request.Target.asterisk
    /// ```
    ///
    /// ## RFC 9110 Reference
    ///
    /// From RFC 9110 Section 7.1:
    /// ```
    /// request-target = origin-form
    ///                / absolute-form
    ///                / authority-form
    ///                / asterisk-form
    ///
    /// origin-form    = absolute-path [ "?" query ]
    /// absolute-form  = absolute-URI
    /// authority-form = uri-host ":" port
    /// asterisk-form  = "*"
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 7.1: Request Target](https://www.rfc-editor.org/rfc/rfc9110.html#section-7.1)
    public enum Target: Sendable, Equatable, Hashable, Codable {
        /// origin-form: absolute-path [ "?" query ]
        ///
        /// The most common form of request-target, used in requests directly to an origin server.
        /// Consists of the absolute path and optional query component.
        ///
        /// ## Example
        ///
        /// ```
        /// GET /where?q=now HTTP/1.1
        /// Host: www.example.org
        /// ```
        ///
        /// This form is used when the request is made directly to the origin server and
        /// the client knows the authority from the connection context.
        ///
        /// ## Reference
        ///
        /// - [RFC 9110 Section 7.1: origin-form](https://www.rfc-editor.org/rfc/rfc9110.html#section-7.1-2.2.1)
        case origin(path: RFC_3986.URI.Path, query: RFC_3986.URI.Query?)

        /// absolute-form: absolute-URI
        ///
        /// Used in requests to proxies, particularly for HTTP requests.
        /// Contains the complete URI including scheme and authority.
        ///
        /// ## Example
        ///
        /// ```
        /// GET http://www.example.org/pub/WWW/TheProject.html HTTP/1.1
        /// ```
        ///
        /// A proxy is requested to service the request from a valid cache, if available,
        /// or make the same request on the client's behalf to the origin server.
        ///
        /// ## Reference
        ///
        /// - [RFC 9110 Section 7.1: absolute-form](https://www.rfc-editor.org/rfc/rfc9110.html#section-7.1-2.2.2)
        case absolute(RFC_3986.URI)

        /// authority-form: uri-host ":" port
        ///
        /// Used only with the CONNECT method to establish a tunnel through one or more proxies.
        /// Contains only the authority (host and port).
        ///
        /// ## Example
        ///
        /// ```
        /// CONNECT www.example.com:80 HTTP/1.1
        /// Host: www.example.com:80
        /// ```
        ///
        /// Per RFC 9110, the authority-form is only used for CONNECT requests.
        ///
        /// ## Reference
        ///
        /// - [RFC 9110 Section 7.1: authority-form](https://www.rfc-editor.org/rfc/rfc9110.html#section-7.1-2.2.3)
        /// - [RFC 9110 Section 9.3.6: CONNECT](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.3.6)
        case authority(RFC_3986.URI.Authority)

        /// asterisk-form: "*"
        ///
        /// Used only with the OPTIONS method to represent the server as a whole,
        /// rather than a specific resource.
        ///
        /// ## Example
        ///
        /// ```
        /// OPTIONS * HTTP/1.1
        /// Host: www.example.org
        /// ```
        ///
        /// This form is used when the client wants information about the server's
        /// capabilities in general, rather than a specific resource.
        ///
        /// ## Reference
        ///
        /// - [RFC 9110 Section 7.1: asterisk-form](https://www.rfc-editor.org/rfc/rfc9110.html#section-7.1-2.2.4)
        /// - [RFC 9110 Section 9.3.7: OPTIONS](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.3.7)
        case asterisk

        /// The string representation of the request-target
        ///
        /// Returns the request-target as it would appear in an HTTP request line.
        public var rawValue: String {
            switch self {
            case .origin(let path, let query):
                if let query = query, !query.isEmpty {
                    return "\(path.description)?\(query.description)"
                } else {
                    return path.description
                }

            case .absolute(let uri):
                return uri.value

            case .authority(let authority):
                return authority.rawValue

            case .asterisk:
                return "*"
            }
        }

        /// Returns the path component, if applicable
        ///
        /// For origin-form, returns the path.
        /// For absolute-form, attempts to extract the path from the URI.
        /// For authority-form and asterisk-form, returns nil.
        public var path: RFC_3986.URI.Path? {
            switch self {
            case .origin(let path, _):
                return path

            case .absolute(let uri):
                // Return path from URI
                return uri.path

            case .authority, .asterisk:
                return nil
            }
        }

        /// Returns the query component, if applicable
        ///
        /// For origin-form, returns the query.
        /// For absolute-form, attempts to extract the query from the URI.
        /// For authority-form and asterisk-form, returns nil.
        public var query: RFC_3986.URI.Query? {
            switch self {
            case .origin(_, let query):
                return query

            case .absolute(let uri):
                // Return query from URI
                return uri.query

            case .authority, .asterisk:
                return nil
            }
        }

        /// Returns true if this is origin-form
        public var isOriginForm: Bool {
            if case .origin = self { return true }
            return false
        }

        /// Returns true if this is absolute-form
        public var isAbsoluteForm: Bool {
            if case .absolute = self { return true }
            return false
        }

        /// Returns true if this is authority-form
        public var isAuthorityForm: Bool {
            if case .authority = self { return true }
            return false
        }

        /// Returns true if this is asterisk-form
        public var isAsteriskForm: Bool {
            if case .asterisk = self { return true }
            return false
        }
    }
}

// MARK: - Validation Error

extension RFC_9110.Request {
    /// Errors that occur during request validation
    public enum Error: Swift.Error, Sendable {
        /// Invalid method for the request-target form
        case invalidMethodForTarget(
            method: RFC_9110.Method,
            target: Target,
            reason: String
        )
    }
}

// MARK: - Codable

extension RFC_9110.Request {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let method = try container.decode(RFC_9110.Method.self, forKey: .method)
        let target = try container.decode(RFC_9110.Request.Target.self, forKey: .target)
        let headers = try container.decodeIfPresent(RFC_9110.Headers.self, forKey: .headers) ?? []
        let body = try container.decodeIfPresent([UInt8].self, forKey: .body)

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

extension RFC_9110.Request.Target {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let form = try container.decode(String.self, forKey: .form)

        switch form {
        case "origin":
            let path = try container.decode(RFC_3986.URI.Path.self, forKey: .path)
            let query = try container.decodeIfPresent(RFC_3986.URI.Query.self, forKey: .query)
            self = .origin(path: path, query: query)

        case "absolute":
            let uriString = try container.decode(String.self, forKey: .uri)
            let uri = try RFC_3986.URI(uriString)
            self = .absolute(uri)

        case "authority":
            let authority = try container.decode(RFC_3986.URI.Authority.self, forKey: .authority)
            self = .authority(authority)

        case "asterisk":
            self = .asterisk

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .form,
                in: container,
                debugDescription: "Unknown request-target form: \(form)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .origin(let path, let query):
            try container.encode("origin", forKey: .form)
            try container.encode(path, forKey: .path)
            if let query = query {
                try container.encode(query, forKey: .query)
            }

        case .absolute(let uri):
            try container.encode("absolute", forKey: .form)
            try container.encode(uri.value, forKey: .uri)

        case .authority(let authority):
            try container.encode("authority", forKey: .form)
            try container.encode(authority, forKey: .authority)

        case .asterisk:
            try container.encode("asterisk", forKey: .form)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case form
        case path
        case query
        case uri
        case authority
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Request: CustomStringConvertible {
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

extension RFC_9110.Request.Target: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - CustomDebugStringConvertible

extension RFC_9110.Request: CustomDebugStringConvertible {
    /// Returns a detailed debug description of the request
    ///
    /// Provides a structured view showing method, target, header count, and body size.
    ///
    /// ## Example Output
    ///
    /// ```
    /// HTTP.Request(
    ///   method: GET
    ///   target: /api/users
    ///   headers: 3 field(s)
    ///   body: 0 bytes
    /// )
    /// ```
    public var debugDescription: String {
        """
        HTTP.Request(
          method: \(method.rawValue)
          target: \(target.rawValue)
          headers: \(headers.count) field\(headers.count == 1 ? "" : "s")
          body: \(body?.count ?? 0) bytes
        )
        """
    }
}
