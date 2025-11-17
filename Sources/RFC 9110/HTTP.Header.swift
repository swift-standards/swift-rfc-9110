// HTTP.Header.swift
// swift-rfc-9110
//
// RFC 9110 Section 6.3: Header Fields
// https://www.rfc-editor.org/rfc/rfc9110.html#section-6.3
//
// HTTP header fields are key-value pairs that convey information about the
// message, its content, or the connection itself.

import Foundation

extension RFC_9110 {
    /// HTTP Header namespace (RFC 9110 Section 6.3)
    ///
    /// Header fields are sent and received in both HTTP requests and responses.
    /// They provide information about the request, response, or about the object
    /// sent in the message body.
    public enum Header {}
}

// MARK: - Header Field

extension RFC_9110.Header {
    /// An HTTP header field (name-value pair) per RFC 9110 Section 6.3
    ///
    /// Each header field consists of a case-insensitive field name followed by a
    /// colon (":"), optional whitespace, and the field value.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let field = try HTTP.Header.Field(
    ///     name: "Content-Type",
    ///     value: "application/json"
    /// )
    /// ```
    ///
    /// ## RFC 9110 Structure
    ///
    /// From RFC 9110 Section 5.1:
    /// ```
    /// header-field   = field-name ":" OWS field-value OWS
    /// field-name     = token
    /// field-value    = *field-content
    /// field-content  = field-vchar [ 1*( SP / HTAB / field-vchar ) field-vchar ]
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 6.3: Field Syntax](https://www.rfc-editor.org/rfc/rfc9110.html#section-6.3)
    public struct Field: Hashable, Sendable, Codable {
        /// The header field name (case-insensitive)
        public let name: Name

        /// The validated header field value
        public let value: Value

        /// Creates an HTTP header field
        ///
        /// - Parameters:
        ///   - name: The header field name
        ///   - value: The validated header field value
        public init(name: Name, value: Value) {
            self.name = name
            self.value = value
        }

        /// Creates an HTTP header field from strings
        ///
        /// - Parameters:
        ///   - name: The header field name
        ///   - value: The header field value (will be validated)
        /// - Throws: `ValidationError` if the value contains invalid characters
        public init(name: String, value: String) throws {
            self.name = Name(name)
            self.value = try Value(value)
        }
    }
}

// MARK: - Field.Name

extension RFC_9110.Header.Field {
    /// An HTTP header field name per RFC 9110 Section 5.1
    ///
    /// Header field names are case-insensitive tokens consisting of
    /// alphanumeric characters and certain special characters.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let contentType = HTTP.Header.Field.Name("Content-Type")
    /// let accept = HTTP.Header.Field.Name("Accept")
    /// let custom = HTTP.Header.Field.Name("X-Custom-Header")
    /// ```
    ///
    /// ## RFC 9110 Syntax
    ///
    /// From RFC 9110 Section 5.1:
    /// ```
    /// field-name     = token
    /// token          = 1*tchar
    /// tchar          = "!" / "#" / "$" / "%" / "&" / "'" / "*"
    ///                / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
    ///                / DIGIT / ALPHA
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 5.1: Field Names](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.1)
    public struct Name: Hashable, Sendable, Codable {
        /// The header field name
        ///
        /// Note: Header field names are case-insensitive per RFC 9110,
        /// but we preserve the original case for display purposes.
        public let rawValue: String

        /// Creates a header field name
        ///
        /// - Parameter rawValue: The header field name
        ///
        /// - Note: No validation is performed as field-name validation
        ///   is typically done at the protocol level
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        /// Hash value (case-insensitive per RFC 9110)
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue.lowercased())
        }

        /// Equality comparison (case-insensitive per RFC 9110)
        public static func == (lhs: Name, rhs: Name) -> Bool {
            lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
        }
    }
}

// MARK: - Field.Value

extension RFC_9110.Header.Field {
    /// A validated HTTP header field value per RFC 9110 Section 5.5
    ///
    /// This type ensures header field values conform to RFC 9110 requirements.
    /// Specifically, field values MUST NOT contain CR (carriage return) or
    /// LF (line feed) characters to prevent header injection attacks.
    ///
    /// ## Security
    ///
    /// This validation prevents HTTP header injection attacks where an attacker
    /// could inject additional headers or control characters by including CRLF
    /// sequences in header values.
    ///
    /// ## RFC 9110 Syntax
    ///
    /// From RFC 9110 Section 5.5:
    /// ```
    /// field-value    = *field-content
    /// field-content  = field-vchar [ 1*( SP / HTAB / field-vchar ) field-vchar ]
    /// field-vchar    = VCHAR / obs-text
    /// obs-text       = %x80-FF
    /// ```
    ///
    /// Notably, CR and LF are not allowed in field-content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Valid header value
    /// let contentType = try HTTP.Header.Field.Value("application/json")
    ///
    /// // Invalid - contains CRLF
    /// do {
    ///     let malicious = try HTTP.Header.Field.Value("value\r\nX-Evil: injected")
    /// } catch {
    ///     print("Rejected: \(error)")
    /// }
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 5.5: Field Values](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.5)
    public struct Value: Hashable, Sendable, Codable {
        /// The validated header field value
        public let rawValue: String

        /// Creates a validated header field value
        ///
        /// - Parameter rawValue: The header field value to validate
        /// - Throws: `ValidationError` if the value contains CR or LF characters
        ///
        /// ## Example
        ///
        /// ```swift
        /// let valid = try HTTP.Header.Field.Value("text/html; charset=utf-8")
        /// ```
        public init(_ rawValue: String) throws {
            // RFC 9110 Section 5.5: field-content cannot contain CR or LF
            // Check for CR (U+000D) and LF (U+000A) characters
            if rawValue.unicodeScalars.contains(where: { $0 == "\r" }) {
                throw ValidationError.invalidFieldValue(
                    value: rawValue,
                    reason: "Header field value contains CR (carriage return) character, forbidden by RFC 9110 §5.5"
                )
            }

            if rawValue.unicodeScalars.contains(where: { $0 == "\n" }) {
                throw ValidationError.invalidFieldValue(
                    value: rawValue,
                    reason: "Header field value contains LF (line feed) character, forbidden by RFC 9110 §5.5"
                )
            }

            self.rawValue = rawValue
        }

        /// Creates a field value without validation
        ///
        /// - Parameter rawValue: The header field value
        ///
        /// - Warning: This initializer bypasses validation and should only be used
        ///   when you have already validated the input or are certain it's safe.
        public init(unchecked rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Validation Error

extension RFC_9110.Header.Field {
    /// Errors that occur during header field validation
    public enum ValidationError: Error, Sendable {
        /// The header field value is invalid
        case invalidFieldValue(value: String, reason: String)
    }
}

// MARK: - LocalizedError Conformance

extension RFC_9110.Header.Field.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFieldValue(let value, let reason):
            return "Invalid HTTP header field value: \(reason) - Value: \"\(value)\""
        }
    }
}

// MARK: - Name String Conversion

extension RFC_9110.Header.Field.Name: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension RFC_9110.Header.Field.Name: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Value String Conversion

extension RFC_9110.Header.Field.Value: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Field String Conversion

extension RFC_9110.Header.Field: CustomStringConvertible {
    /// Returns the header field in HTTP format (name: value)
    public var description: String {
        "\(name.rawValue): \(value.rawValue)"
    }
}

// MARK: - Common Header Names

extension RFC_9110.Header.Field.Name {
    // MARK: - Control Data (RFC 9110 Section 6.6)

    /// Cache-Control header (RFC 9110 Section 5.2)
    public static let cacheControl = Self("Cache-Control")

    /// Expect header (RFC 9110 Section 10.1.1)
    public static let expect = Self("Expect")

    /// Host header (RFC 9110 Section 7.2)
    public static let host = Self("Host")

    /// Max-Forwards header (RFC 9110 Section 7.6.2)
    public static let maxForwards = Self("Max-Forwards")

    /// Pragma header (RFC 9110 Section 5.4)
    public static let pragma = Self("Pragma")

    /// Range header (RFC 9110 Section 14.2)
    public static let range = Self("Range")

    /// TE header (RFC 9110 Section 10.1.4)
    public static let te = Self("TE")

    // MARK: - Request Context (RFC 9110 Section 10.1)

    /// From header (RFC 9110 Section 10.1.2)
    public static let from = Self("From")

    /// Referer header (RFC 9110 Section 10.1.3)
    public static let referer = Self("Referer")

    /// User-Agent header (RFC 9110 Section 10.1.5)
    public static let userAgent = Self("User-Agent")

    // MARK: - Request Content Negotiation (RFC 9110 Section 12)

    /// Accept header (RFC 9110 Section 12.5.1)
    public static let accept = Self("Accept")

    /// Accept-Charset header (RFC 9110 Section 12.5.2)
    public static let acceptCharset = Self("Accept-Charset")

    /// Accept-Encoding header (RFC 9110 Section 12.5.3)
    public static let acceptEncoding = Self("Accept-Encoding")

    /// Accept-Language header (RFC 9110 Section 12.5.4)
    public static let acceptLanguage = Self("Accept-Language")

    // MARK: - Authentication (RFC 9110 Section 11)

    /// Authorization header (RFC 9110 Section 11.6.2)
    public static let authorization = Self("Authorization")

    /// Proxy-Authorization header (RFC 9110 Section 11.7.2)
    public static let proxyAuthorization = Self("Proxy-Authorization")

    /// WWW-Authenticate header (RFC 9110 Section 11.6.1)
    public static let wwwAuthenticate = Self("WWW-Authenticate")

    /// Proxy-Authenticate header (RFC 9110 Section 11.7.1)
    public static let proxyAuthenticate = Self("Proxy-Authenticate")

    // MARK: - Response Control Data (RFC 9110 Section 10.2)

    /// Age header (RFC 9110 Section 5.1)
    public static let age = Self("Age")

    /// Expires header (RFC 9110 Section 5.3)
    public static let expires = Self("Expires")

    /// Date header (RFC 9110 Section 6.6.1)
    public static let date = Self("Date")

    /// Location header (RFC 9110 Section 10.2.2)
    public static let location = Self("Location")

    /// Retry-After header (RFC 9110 Section 10.2.3)
    public static let retryAfter = Self("Retry-After")

    /// Vary header (RFC 9110 Section 12.5.5)
    public static let vary = Self("Vary")

    /// Server header (RFC 9110 Section 10.2.4)
    public static let server = Self("Server")

    // MARK: - Representation Metadata (RFC 9110 Section 8.3)

    /// Content-Type header (RFC 9110 Section 8.3)
    public static let contentType = Self("Content-Type")

    /// Content-Encoding header (RFC 9110 Section 8.4)
    public static let contentEncoding = Self("Content-Encoding")

    /// Content-Language header (RFC 9110 Section 8.5)
    public static let contentLanguage = Self("Content-Language")

    /// Content-Location header (RFC 9110 Section 8.7)
    public static let contentLocation = Self("Content-Location")

    // MARK: - Payload (RFC 9110 Section 8.6)

    /// Content-Length header (RFC 9110 Section 8.6)
    public static let contentLength = Self("Content-Length")

    /// Content-Range header (RFC 9110 Section 14.4)
    public static let contentRange = Self("Content-Range")

    /// Trailer header (RFC 9110 Section 6.6.2)
    public static let trailer = Self("Trailer")

    /// Transfer-Encoding header (RFC 9110 Section 6.1)
    public static let transferEncoding = Self("Transfer-Encoding")

    // MARK: - Validators (RFC 9110 Section 8.8)

    /// ETag header (RFC 9110 Section 8.8.3)
    public static let etag = Self("ETag")

    /// Last-Modified header (RFC 9110 Section 8.8.2)
    public static let lastModified = Self("Last-Modified")

    // MARK: - Conditional Requests (RFC 9110 Section 13)

    /// If-Match header (RFC 9110 Section 13.1.1)
    public static let ifMatch = Self("If-Match")

    /// If-None-Match header (RFC 9110 Section 13.1.2)
    public static let ifNoneMatch = Self("If-None-Match")

    /// If-Modified-Since header (RFC 9110 Section 13.1.3)
    public static let ifModifiedSince = Self("If-Modified-Since")

    /// If-Unmodified-Since header (RFC 9110 Section 13.1.4)
    public static let ifUnmodifiedSince = Self("If-Unmodified-Since")

    /// If-Range header (RFC 9110 Section 13.1.5)
    public static let ifRange = Self("If-Range")

    // MARK: - Connection Management (RFC 9110 Section 7.6.1)

    /// Connection header (RFC 9110 Section 7.6.1)
    public static let connection = Self("Connection")

    /// Close connection token
    public static let close = Self("close")

    /// Keep-Alive header
    public static let keepAlive = Self("Keep-Alive")

    // MARK: - Other

    /// Allow header (RFC 9110 Section 10.2.1)
    public static let allow = Self("Allow")
}

// MARK: - Value Codable (custom implementation for throwing init)

extension RFC_9110.Header.Field.Value {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
