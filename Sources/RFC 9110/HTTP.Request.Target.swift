// HTTP.Request.Target.swift
// swift-rfc-9110
//
// RFC 9110 Section 7.1: Request Target
// https://www.rfc-editor.org/rfc/rfc9110.html#section-7.1
//
// The request-target identifies the target resource upon which to apply the request.

import Foundation
import RFC_3986

extension RFC_9110 {
    /// HTTP Request namespace
    public enum Request {}
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
    ///     path: try .init("/users/123"),
    ///     query: try .init("page=1")
    /// )
    ///
    /// // absolute-form (used in requests to proxies)
    /// let absolute = HTTP.Request.Target.absolute(
    ///     try .init("http://www.example.org/pub/WWW/TheProject.html")
    /// )
    ///
    /// // authority-form (used only with CONNECT)
    /// let authority = HTTP.Request.Target.authority(
    ///     try .init(host: .name("www.example.com"), port: .init(80))
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
    public enum Target: Sendable, Equatable, Hashable {
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
                    return "\(path.string)?\(query.string)"
                } else {
                    return path.string
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
                // Try to extract path from URI
                if let pathString = uri.path {
                    return try? RFC_3986.URI.Path(pathString)
                }
                return nil

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
                // Try to extract query from URI
                if let queryString = uri.query {
                    return try? RFC_3986.URI.Query(queryString)
                }
                return nil

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

// MARK: - CustomStringConvertible

extension RFC_9110.Request.Target: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

extension RFC_9110.Request.Target: Codable {
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
