// HTTP.Status.swift
// swift-rfc-9110
//
// RFC 9110 Section 15: Status Codes
// https://www.rfc-editor.org/rfc/rfc9110.html#section-15
//
// The status code of a response is a three-digit integer code that
// describes the result of the request and the semantics of the response.

import Foundation

extension RFC_9110 {
    /// HTTP Status Code (RFC 9110 Section 15)
    ///
    /// A status code indicates the result of an HTTP request.
    ///
    /// Status code classes (RFC 9110 Section 15.1):
    /// - 1xx (Informational): Request received, continuing process
    /// - 2xx (Successful): Request successfully received, understood, and accepted
    /// - 3xx (Redirection): Further action needs to be taken to complete request
    /// - 4xx (Client Error): Request contains bad syntax or cannot be fulfilled
    /// - 5xx (Server Error): Server failed to fulfill valid request
    public struct Status: Hashable, Sendable, Codable {
        /// The three-digit status code
        public let code: Int
        
        /// The optional reason phrase
        ///
        /// RFC 9110 allows custom reason phrases, though they are optional
        /// and clients SHOULD ignore them.
        public let reasonPhrase: String?
        
        /// Creates a status with a code and optional reason phrase
        ///
        /// - Parameters:
        ///   - code: The three-digit status code
        ///   - reasonPhrase: Optional reason phrase
        public init(_ code: Int, _ reasonPhrase: String? = nil) {
            self.code = code
            self.reasonPhrase = reasonPhrase
        }
    }
}

extension RFC_9110.Status {
    
    // MARK: - Status Code Properties
    
    /// Whether this is an informational status (1xx)
    public var isInformational: Bool {
        (100...199).contains(code)
    }
    
    /// Whether this is a successful status (2xx)
    public var isSuccessful: Bool {
        (200...299).contains(code)
    }
    
    /// Whether this is a redirection status (3xx)
    public var isRedirection: Bool {
        (300...399).contains(code)
    }
    
    /// Whether this is a client error status (4xx)
    public var isClientError: Bool {
        (400...499).contains(code)
    }
    
    /// Whether this is a server error status (5xx)
    public var isServerError: Bool {
        (500...599).contains(code)
    }
}
 
extension RFC_9110.Status {
    // MARK: - Equatable
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.code == rhs.code
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    
    // MARK: - Codable
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.code = try container.decode(Int.self)
        self.reasonPhrase = nil
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }
}


// MARK: - CustomStringConvertible

extension RFC_9110.Status: CustomStringConvertible {
    public var description: String {
        if let reasonPhrase {
            return "\(code) \(reasonPhrase)"
        } else {
            return "\(code)"
        }
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension RFC_9110.Status: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

// MARK: - Comparable

extension RFC_9110.Status: Comparable {
    /// Compares two status codes by their numeric value
    ///
    /// Enables semantic ordering and range matching for status codes.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Sorting
    /// let statuses: [HTTP.Status] = [.notFound, .ok, .internalServerError]
    /// statuses.sorted()  // [.ok, .notFound, .internalServerError] (200, 404, 500)
    ///
    /// // Range matching for error handling
    /// if status >= .badRequest {  // 4xx or 5xx
    ///     // Handle error
    /// }
    ///
    /// // Pattern matching with ranges
    /// switch status {
    /// case ..<.multipleChoices:              // 1xx, 2xx
    ///     // Success cases
    /// case .multipleChoices..<.badRequest:   // 3xx
    ///     // Redirects
    /// default:                               // 4xx, 5xx
    ///     // Errors
    /// }
    /// ```
    public static func < (lhs: RFC_9110.Status, rhs: RFC_9110.Status) -> Bool {
        lhs.code < rhs.code
    }
}

// MARK: - Standard Status Codes

extension RFC_9110.Status {
    // MARK: - Informational 1xx (RFC 9110 Section 15.2)

    /// 100 Continue (Section 15.2.1)
    ///
    /// The client should continue with its request
    public static let `continue` = Self(100, "Continue")

    /// 101 Switching Protocols (Section 15.2.2)
    ///
    /// The server is switching protocols as requested by the client
    public static let switchingProtocols = Self(101, "Switching Protocols")

    // MARK: - Successful 2xx (RFC 9110 Section 15.3)

    /// 200 OK (Section 15.3.1)
    ///
    /// The request succeeded
    public static let ok = Self(200, "OK")

    /// 201 Created (Section 15.3.2)
    ///
    /// The request succeeded and a new resource was created
    public static let created = Self(201, "Created")

    /// 202 Accepted (Section 15.3.3)
    ///
    /// The request has been accepted for processing, but processing is not complete
    public static let accepted = Self(202, "Accepted")

    /// 203 Non-Authoritative Information (Section 15.3.4)
    ///
    /// The request succeeded but the enclosed content has been modified
    public static let nonAuthoritativeInformation = Self(203, "Non-Authoritative Information")

    /// 204 No Content (Section 15.3.5)
    ///
    /// The request succeeded but there is no content to send
    public static let noContent = Self(204, "No Content")

    /// 205 Reset Content (Section 15.3.6)
    ///
    /// The request succeeded and the user agent should reset the document view
    public static let resetContent = Self(205, "Reset Content")

    /// 206 Partial Content (Section 15.3.7)
    ///
    /// The server is delivering only part of the resource due to a range header
    public static let partialContent = Self(206, "Partial Content")

    // MARK: - Redirection 3xx (RFC 9110 Section 15.4)

    /// 300 Multiple Choices (Section 15.4.1)
    ///
    /// The target resource has more than one representation
    public static let multipleChoices = Self(300, "Multiple Choices")

    /// 301 Moved Permanently (Section 15.4.2)
    ///
    /// The target resource has been assigned a new permanent URI
    public static let movedPermanently = Self(301, "Moved Permanently")

    /// 302 Found (Section 15.4.3)
    ///
    /// The target resource resides temporarily under a different URI
    public static let found = Self(302, "Found")

    /// 303 See Other (Section 15.4.4)
    ///
    /// The server is redirecting the user agent to a different resource
    public static let seeOther = Self(303, "See Other")

    /// 304 Not Modified (Section 15.4.5)
    ///
    /// The resource has not been modified since last requested
    public static let notModified = Self(304, "Not Modified")

    /// 305 Use Proxy (Section 15.4.6) - Deprecated
    ///
    /// Deprecated due to security concerns
    public static let useProxy = Self(305, "Use Proxy")

    /// 307 Temporary Redirect (Section 15.4.8)
    ///
    /// The target resource resides temporarily under a different URI
    /// and the user agent MUST NOT change the request method
    public static let temporaryRedirect = Self(307, "Temporary Redirect")

    /// 308 Permanent Redirect (Section 15.4.9)
    ///
    /// The target resource has been assigned a new permanent URI
    /// and the user agent MUST NOT change the request method
    public static let permanentRedirect = Self(308, "Permanent Redirect")

    // MARK: - Client Error 4xx (RFC 9110 Section 15.5)

    /// 400 Bad Request (Section 15.5.1)
    ///
    /// The server cannot or will not process the request due to client error
    public static let badRequest = Self(400, "Bad Request")

    /// 401 Unauthorized (Section 15.5.2)
    ///
    /// The request requires user authentication
    public static let unauthorized = Self(401, "Unauthorized")

    /// 402 Payment Required (Section 15.5.3)
    ///
    /// Reserved for future use
    public static let paymentRequired = Self(402, "Payment Required")

    /// 403 Forbidden (Section 15.5.4)
    ///
    /// The server understood the request but refuses to authorize it
    public static let forbidden = Self(403, "Forbidden")

    /// 404 Not Found (Section 15.5.5)
    ///
    /// The origin server did not find a representation for the target resource
    public static let notFound = Self(404, "Not Found")

    /// 405 Method Not Allowed (Section 15.5.6)
    ///
    /// The method received in the request is not supported by the target resource
    public static let methodNotAllowed = Self(405, "Method Not Allowed")

    /// 406 Not Acceptable (Section 15.5.7)
    ///
    /// The target resource does not have a representation acceptable to the user agent
    public static let notAcceptable = Self(406, "Not Acceptable")

    /// 407 Proxy Authentication Required (Section 15.5.8)
    ///
    /// The client needs to authenticate itself with the proxy
    public static let proxyAuthenticationRequired = Self(407, "Proxy Authentication Required")

    /// 408 Request Timeout (Section 15.5.9)
    ///
    /// The server timed out waiting for the request
    public static let requestTimeout = Self(408, "Request Timeout")

    /// 409 Conflict (Section 15.5.10)
    ///
    /// The request could not be completed due to a conflict with the current state
    public static let conflict = Self(409, "Conflict")

    /// 410 Gone (Section 15.5.11)
    ///
    /// The target resource is no longer available and this condition is permanent
    public static let gone = Self(410, "Gone")

    /// 411 Length Required (Section 15.5.12)
    ///
    /// The server refuses to accept the request without a defined Content-Length
    public static let lengthRequired = Self(411, "Length Required")

    /// 412 Precondition Failed (Section 15.5.13)
    ///
    /// One or more conditions given in the request header fields evaluated to false
    public static let preconditionFailed = Self(412, "Precondition Failed")

    /// 413 Content Too Large (Section 15.5.14)
    ///
    /// The server is refusing to process a request because the content is too large
    public static let contentTooLarge = Self(413, "Content Too Large")

    /// 414 URI Too Long (Section 15.5.15)
    ///
    /// The server is refusing to service the request because the request-target is too long
    public static let uriTooLong = Self(414, "URI Too Long")

    /// 415 Unsupported Media Type (Section 15.5.16)
    ///
    /// The origin server is refusing to service the request because the content is in an unsupported format
    public static let unsupportedMediaType = Self(415, "Unsupported Media Type")

    /// 416 Range Not Satisfiable (Section 15.5.17)
    ///
    /// None of the ranges in the request's Range header field overlap the current extent of the selected resource
    public static let rangeNotSatisfiable = Self(416, "Range Not Satisfiable")

    /// 417 Expectation Failed (Section 15.5.18)
    ///
    /// The expectation given in the request's Expect header field could not be met
    public static let expectationFailed = Self(417, "Expectation Failed")

    /// 421 Misdirected Request (Section 15.5.20)
    ///
    /// The request was directed at a server that is not able to produce a response
    public static let misdirectedRequest = Self(421, "Misdirected Request")

    /// 422 Unprocessable Content (Section 15.5.21)
    ///
    /// The server understands the content type but was unable to process the contained instructions
    public static let unprocessableContent = Self(422, "Unprocessable Content")

    /// 426 Upgrade Required (Section 15.5.22)
    ///
    /// The server refuses to perform the request using the current protocol
    public static let upgradeRequired = Self(426, "Upgrade Required")

    // MARK: - Server Error 5xx (RFC 9110 Section 15.6)

    /// 500 Internal Server Error (Section 15.6.1)
    ///
    /// The server encountered an unexpected condition that prevented it from fulfilling the request
    public static let internalServerError = Self(500, "Internal Server Error")

    /// 501 Not Implemented (Section 15.6.2)
    ///
    /// The server does not support the functionality required to fulfill the request
    public static let notImplemented = Self(501, "Not Implemented")

    /// 502 Bad Gateway (Section 15.6.3)
    ///
    /// The server received an invalid response from an inbound server
    public static let badGateway = Self(502, "Bad Gateway")

    /// 503 Service Unavailable (Section 15.6.4)
    ///
    /// The server is currently unable to handle the request
    public static let serviceUnavailable = Self(503, "Service Unavailable")

    /// 504 Gateway Timeout (Section 15.6.5)
    ///
    /// The server did not receive a timely response from an upstream server
    public static let gatewayTimeout = Self(504, "Gateway Timeout")

    /// 505 HTTP Version Not Supported (Section 15.6.6)
    ///
    /// The server does not support the HTTP version used in the request
    public static let httpVersionNotSupported = Self(505, "HTTP Version Not Supported")
}
