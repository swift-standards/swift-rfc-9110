// HTTP.Response.swift
// swift-rfc-9110
//
// RFC 9110 Section 15: Status Codes
// RFC 9110 Section 6: Message Abstraction
// https://www.rfc-editor.org/rfc/rfc9110.html#section-6
//
// HTTP response message semantics

import Foundation

extension RFC_9110 {
    /// HTTP response message per RFC 9110 Section 15
    ///
    /// An HTTP response message consists of a status line (status code),
    /// header fields, and an optional message body.
    ///
    /// ## Example
    /// ```swift
    /// // Simple 200 OK response
    /// let response = HTTP.Response(
    ///     status: .ok,
    ///     headers: [
    ///         .init(name: "Content-Type", value: "application/json")
    ///     ],
    ///     body: jsonData
    /// )
    ///
    /// // 404 Not Found response
    /// let notFound = HTTP.Response(
    ///     status: .notFound,
    ///     headers: [
    ///         .init(name: "Content-Type", value: "text/plain")
    ///     ],
    ///     body: Data("Not Found".utf8)
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
    /// status-line    = HTTP-version SP status-code SP [ reason-phrase ]
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 3: Message Format](https://www.rfc-editor.org/rfc/rfc9110.html#section-3)
    /// - [RFC 9110 Section 6: Message Abstraction](https://www.rfc-editor.org/rfc/rfc9110.html#section-6)
    /// - [RFC 9110 Section 15: Status Codes](https://www.rfc-editor.org/rfc/rfc9110.html#section-15)
    public struct Response: Sendable, Equatable, Hashable, Codable {
        // MARK: - Status Line Components
        
        /// HTTP status code (required per RFC 9110 Section 15)
        ///
        /// The status-code element is a three-digit integer code describing
        /// the result of the server's attempt to understand and satisfy the request.
        public var status: RFC_9110.Status
        
        // MARK: - Message Components
        
        /// Header fields (case-insensitive per RFC 9110 Section 5.1)
        ///
        /// Each header field consists of a case-insensitive field name followed by a
        /// colon (":"), optional whitespace, the field value, and optional trailing whitespace.
        ///
        /// Use subscript for convenient access: `response.headers["content-type"]?.first`
        public var headers: RFC_9110.Headers
        
        /// Message body (optional per RFC 9110 Section 6.4)
        ///
        /// The message body (if any) carries the content of the response.
        public var body: Data?
        
        // MARK: - Initialization
        
        /// Creates an HTTP response message
        ///
        /// - Parameters:
        ///   - status: The HTTP status code (required)
        ///   - headers: The header fields (defaults to empty)
        ///   - body: The message body (optional)
        public init(
            status: RFC_9110.Status,
            headers: RFC_9110.Headers = [],
            body: Data? = nil
        ) {
            self.status = status
            self.headers = headers
            self.body = body
        }
    }
}

extension RFC_9110.Response {
    
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
    /// - Returns: A new response with the header field added
    public func addingHeader(_ field: RFC_9110.Header.Field) -> Self {
        var copy = self
        copy.headers.append(field)
        return copy
    }
    
    /// Removes all header fields with the given name
    ///
    /// - Parameter name: The header field name to remove (case-insensitive)
    /// - Returns: A new response with the header fields removed
    public func removingHeaders(_ name: RFC_9110.Header.Field.Name) -> Self {
        var copy = self
        copy.headers.removeAll(named: name.rawValue)
        return copy
    }
}


// MARK: - Codable

extension RFC_9110.Response {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(RFC_9110.Status.self, forKey: .status)
        let headers = try container.decodeIfPresent(RFC_9110.Headers.self, forKey: .headers) ?? []
        let body = try container.decodeIfPresent(Data.self, forKey: .body)

        self.init(
            status: status,
            headers: headers,
            body: body
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        if !headers.isEmpty {
            try container.encode(Array(headers), forKey: .headers)
        }
        if let body = body {
            try container.encode(body, forKey: .body)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case headers
        case body
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Response: CustomStringConvertible {
    /// Returns a string representation of the response
    ///
    /// Format: "STATUS_CODE Reason\nHeader: Value\n..."
    public var description: String {
        var result = status.description
        for header in headers {
            result += "\n\(header.description)"
        }
        if let body = body {
            result += "\n\n[Body: \(body.count) bytes]"
        }
        return result
    }
}

// MARK: - CustomDebugStringConvertible

extension RFC_9110.Response: CustomDebugStringConvertible {
    /// Returns a detailed debug description of the response
    ///
    /// Provides a structured view showing status code, header count, and body size.
    ///
    /// ## Example Output
    ///
    /// ```
    /// HTTP.Response(
    ///   status: 200 OK
    ///   headers: 3 field(s)
    ///   body: 1024 bytes
    /// )
    /// ```
    public var debugDescription: String {
        let statusLine = if let reasonPhrase = status.reasonPhrase {
            "\(status.code) \(reasonPhrase)"
        } else {
            "\(status.code)"
        }

        return """
        HTTP.Response(
          status: \(statusLine)
          headers: \(headers.count) field\(headers.count == 1 ? "" : "s")
          body: \(body?.count ?? 0) bytes
        )
        """
    }
}

// MARK: - Common Response Constructors

extension RFC_9110.Response {
    /// Creates a 200 OK response
    ///
    /// - Parameters:
    ///   - headers: Optional headers
    ///   - body: Optional body
    /// - Returns: A response with status 200
    public static func ok(
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) -> Self {
        Self(status: .ok, headers: headers, body: body)
    }

    /// Creates a 201 Created response
    ///
    /// - Parameters:
    ///   - location: The location of the created resource
    ///   - headers: Optional additional headers
    ///   - body: Optional body
    /// - Returns: A response with status 201
    public static func created(
        location: String? = nil,
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) throws -> Self {
        var responseHeaders = headers
        if let location = location {
            responseHeaders.append(try .init(name: "Location", value: location))
        }
        return Self(status: .created, headers: responseHeaders, body: body)
    }

    /// Creates a 204 No Content response
    ///
    /// - Parameter headers: Optional headers
    /// - Returns: A response with status 204 and no body
    public static func noContent(
        headers: RFC_9110.Headers = []
    ) -> Self {
        Self(status: .noContent, headers: headers, body: nil)
    }

    /// Creates a 301 Moved Permanently redirect response
    ///
    /// - Parameters:
    ///   - location: The new permanent location
    ///   - headers: Optional additional headers
    /// - Returns: A response with status 301
    public static func movedPermanently(
        to location: String,
        headers: RFC_9110.Headers = []
    ) throws -> Self {
        var responseHeaders = headers
        responseHeaders.append(try .init(name: "Location", value: location))
        return Self(status: .movedPermanently, headers: responseHeaders, body: nil)
    }

    /// Creates a 302 Found redirect response
    ///
    /// - Parameters:
    ///   - location: The temporary location
    ///   - headers: Optional additional headers
    /// - Returns: A response with status 302
    public static func found(
        at location: String,
        headers: RFC_9110.Headers = []
    ) throws -> Self {
        var responseHeaders = headers
        responseHeaders.append(try .init(name: "Location", value: location))
        return Self(status: .found, headers: responseHeaders, body: nil)
    }

    /// Creates a 303 See Other redirect response
    ///
    /// - Parameters:
    ///   - location: The location to see
    ///   - headers: Optional additional headers
    /// - Returns: A response with status 303
    public static func seeOther(
        at location: String,
        headers: RFC_9110.Headers = []
    ) throws -> Self {
        var responseHeaders = headers
        responseHeaders.append(try .init(name: "Location", value: location))
        return Self(status: .seeOther, headers: responseHeaders, body: nil)
    }

    /// Creates a 304 Not Modified response
    ///
    /// - Parameter headers: Optional headers (typically ETag or Last-Modified)
    /// - Returns: A response with status 304 and no body
    public static func notModified(
        headers: RFC_9110.Headers = []
    ) -> Self {
        Self(status: .notModified, headers: headers, body: nil)
    }

    /// Creates a 400 Bad Request response
    ///
    /// - Parameters:
    ///   - headers: Optional headers
    ///   - body: Optional body explaining the error
    /// - Returns: A response with status 400
    public static func badRequest(
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) -> Self {
        Self(status: .badRequest, headers: headers, body: body)
    }

    /// Creates a 401 Unauthorized response
    ///
    /// - Parameters:
    ///   - wwwAuthenticate: The WWW-Authenticate header value
    ///   - headers: Optional additional headers
    ///   - body: Optional body
    /// - Returns: A response with status 401
    public static func unauthorized(
        wwwAuthenticate: String,
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) throws -> Self {
        var responseHeaders = headers
        responseHeaders.append(try .init(name: "WWW-Authenticate", value: wwwAuthenticate))
        return Self(status: .unauthorized, headers: responseHeaders, body: body)
    }

    /// Creates a 403 Forbidden response
    ///
    /// - Parameters:
    ///   - headers: Optional headers
    ///   - body: Optional body explaining why access is forbidden
    /// - Returns: A response with status 403
    public static func forbidden(
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) -> Self {
        Self(status: .forbidden, headers: headers, body: body)
    }

    /// Creates a 404 Not Found response
    ///
    /// - Parameters:
    ///   - headers: Optional headers
    ///   - body: Optional body
    /// - Returns: A response with status 404
    public static func notFound(
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) -> Self {
        Self(status: .notFound, headers: headers, body: body)
    }

    /// Creates a 500 Internal Server Error response
    ///
    /// - Parameters:
    ///   - headers: Optional headers
    ///   - body: Optional body
    /// - Returns: A response with status 500
    public static func internalServerError(
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) -> Self {
        Self(status: .internalServerError, headers: headers, body: body)
    }

    /// Creates a 503 Service Unavailable response
    ///
    /// - Parameters:
    ///   - retryAfter: Optional Retry-After header value (seconds or date)
    ///   - headers: Optional additional headers
    ///   - body: Optional body
    /// - Returns: A response with status 503
    public static func serviceUnavailable(
        retryAfter: String? = nil,
        headers: RFC_9110.Headers = [],
        body: Data? = nil
    ) throws -> Self {
        var responseHeaders = headers
        if let retryAfter = retryAfter {
            responseHeaders.append(try .init(name: "Retry-After", value: retryAfter))
        }
        return Self(status: .serviceUnavailable, headers: responseHeaders, body: body)
    }
}
