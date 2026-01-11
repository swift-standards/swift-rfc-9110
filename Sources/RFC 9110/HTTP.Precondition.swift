// HTTP.Precondition.swift
// swift-rfc-9110

import INCITS_4_1986
public import RFC_5322
import Standard_Library_Extensions

extension HTTP {
    /// Conditional request preconditions (RFC 9110 Section 13)
    ///
    /// Preconditions are used to make requests conditional based on the state
    /// of the target resource. They enable cache validation and optimistic
    /// concurrency control.
    ///
    /// # Example
    ///
    /// ```swift
    /// // Only update if ETag matches
    /// let precondition = HTTP.Precondition.ifMatch([.strong("abc123")])
    ///
    /// // Only fetch if modified since date
    /// let precondition = HTTP.Precondition.ifModifiedSince(Date())
    ///
    /// // Conditional range request
    /// let precondition = HTTP.Precondition.ifRange(.etag(.strong("abc123")))
    /// ```
    ///
    public enum Precondition: Sendable, Equatable {
        /// If-Match: Only perform the action if the current ETag matches one of the provided ETags
        ///
        /// Used for updates to ensure the resource hasn't changed (optimistic locking).
        /// Use `[.wildcard]` to match any representation.
        ///
        /// # RFC 9110 Section 13.1.1
        case ifMatch([HTTP.EntityTag])

        /// If-None-Match: Only perform the action if the current ETag doesn't match any provided ETags
        ///
        /// Used with GET/HEAD for cache validation. Use `[.wildcard]` to match any representation.
        ///
        /// # RFC 9110 Section 13.1.2
        case ifNoneMatch([HTTP.EntityTag])

        /// If-Modified-Since: Only perform the action if modified after the specified date
        ///
        /// Used with GET/HEAD for cache validation.
        ///
        /// # RFC 9110 Section 13.1.3
        case ifModifiedSince(RFC_5322.DateTime)

        /// If-Unmodified-Since: Only perform the action if not modified since the specified date
        ///
        /// Used for updates to ensure the resource hasn't changed.
        ///
        /// # RFC 9110 Section 13.1.4
        case ifUnmodifiedSince(RFC_5322.DateTime)

        /// If-Range: Make range request conditional on validator match
        ///
        /// If the validator matches, return the requested range.
        /// If it doesn't match, return the entire representation.
        ///
        /// # RFC 9110 Section 13.1.5
        case ifRange(Validator)

        /// A validator for If-Range precondition
        public enum Validator: Sendable, Equatable {
            case etag(HTTP.EntityTag)
            case date(RFC_5322.DateTime)
        }

        /// Wildcard entity tag for matching any representation
        public static let wildcardTag = HTTP.EntityTag.strong("*")
    }
}

// MARK: - Header Generation

extension HTTP.Precondition {
    /// The header field name for this precondition
    public var headerName: String {
        switch self {
        case .ifMatch:
            return "If-Match"
        case .ifNoneMatch:
            return "If-None-Match"
        case .ifModifiedSince:
            return "If-Modified-Since"
        case .ifUnmodifiedSince:
            return "If-Unmodified-Since"
        case .ifRange:
            return "If-Range"
        }
    }

    /// The header value for this precondition
    public var headerValue: String {
        switch self {
        case .ifMatch(let etags):
            if etags.count == 1 && etags[0].value == "*" {
                return "*"
            }
            return etags.map { $0.headerValue }.joined(separator: ", ")

        case .ifNoneMatch(let etags):
            if etags.count == 1 && etags[0].value == "*" {
                return "*"
            }
            return etags.map { $0.headerValue }.joined(separator: ", ")

        case .ifModifiedSince(let date):
            return String(date)

        case .ifUnmodifiedSince(let date):
            return String(date)

        case .ifRange(.etag(let etag)):
            return etag.headerValue

        case .ifRange(.date(let date)):
            return String(date)
        }
    }
}

// MARK: - Header Parsing

extension HTTP.Precondition {
    /// Parses an If-Match header value
    ///
    /// - Parameter headerValue: The If-Match header value
    /// - Returns: An If-Match precondition, or nil if parsing fails
    public static func parseIfMatch(_ headerValue: String) -> HTTP.Precondition? {
        let trimmed = headerValue.trimming(.ascii.whitespaces)

        // Wildcard case
        if trimmed == "*" {
            return .ifMatch([wildcardTag])
        }

        // Parse comma-separated ETags
        let etags =
            trimmed
            .split(separator: ",")
            .compactMap { HTTP.EntityTag.parse(String($0.trimming(.ascii.whitespaces))) }

        return etags.isEmpty ? nil : .ifMatch(etags)
    }

    /// Parses an If-None-Match header value
    ///
    /// - Parameter headerValue: The If-None-Match header value
    /// - Returns: An If-None-Match precondition, or nil if parsing fails
    public static func parseIfNoneMatch(_ headerValue: String) -> HTTP.Precondition? {
        let trimmed = headerValue.trimming(.ascii.whitespaces)

        // Wildcard case
        if trimmed == "*" {
            return .ifNoneMatch([wildcardTag])
        }

        // Parse comma-separated ETags
        let etags =
            trimmed
            .split(separator: ",")
            .compactMap { HTTP.EntityTag.parse(String($0.trimming(.ascii.whitespaces))) }

        return etags.isEmpty ? nil : .ifNoneMatch(etags)
    }

    /// Parses an If-Modified-Since header value
    ///
    /// - Parameter headerValue: The If-Modified-Since header value
    /// - Returns: An If-Modified-Since precondition, or nil if parsing fails
    public static func parseIfModifiedSince(_ headerValue: String) -> HTTP.Precondition? {
        guard let httpDate = try? RFC_5322.DateTime(ascii: headerValue.utf8) else {
            return nil
        }
        return .ifModifiedSince(httpDate)
    }

    /// Parses an If-Unmodified-Since header value
    ///
    /// - Parameter headerValue: The If-Unmodified-Since header value
    /// - Returns: An If-Unmodified-Since precondition, or nil if parsing fails
    public static func parseIfUnmodifiedSince(_ headerValue: String) -> HTTP.Precondition? {
        guard let httpDate = try? RFC_5322.DateTime(ascii: headerValue.utf8) else {
            return nil
        }
        return .ifUnmodifiedSince(httpDate)
    }

    /// Parses an If-Range header value
    ///
    /// - Parameter headerValue: The If-Range header value
    /// - Returns: An If-Range precondition, or nil if parsing fails
    public static func parseIfRange(_ headerValue: String) -> HTTP.Precondition? {
        let trimmed = headerValue.trimming(.ascii.whitespaces)

        // Try to parse as ETag first
        if let etag = HTTP.EntityTag.parse(trimmed) {
            return .ifRange(.etag(etag))
        }

        // Try to parse as date
        if let httpDate = try? RFC_5322.DateTime(ascii: trimmed.utf8) {
            return .ifRange(.date(httpDate))
        }

        return nil
    }
}

// MARK: - Evaluation

extension HTTP.Precondition {
    /// Evaluates whether this precondition is satisfied
    ///
    /// - Parameters:
    ///   - currentETag: The current entity tag of the resource, if any
    ///   - lastModified: The last modified timestamp of the resource, if any
    /// - Returns: true if the precondition is satisfied, false otherwise
    public func evaluate(currentETag: HTTP.EntityTag?, lastModified: RFC_5322.DateTime?) -> Bool {
        switch self {
        case .ifMatch(let etags):
            guard let currentETag = currentETag else {
                return false
            }
            // Wildcard matches any representation
            if etags.contains(where: { $0.value == "*" }) {
                return true
            }
            // Check if any ETag matches using strong comparison
            return etags.contains(where: { HTTP.EntityTag.strongCompare($0, currentETag) })

        case .ifNoneMatch(let etags):
            guard let currentETag = currentETag else {
                // If no current ETag exists, precondition is satisfied
                return true
            }
            // Wildcard matches any representation
            if etags.contains(where: { $0.value == "*" }) {
                return false
            }
            // Check if NO ETag matches using weak comparison
            return !etags.contains(where: { HTTP.EntityTag.weakCompare($0, currentETag) })

        case .ifModifiedSince(let date):
            guard let lastModified = lastModified else {
                // If no last modified date exists, assume modified
                return true
            }
            // Satisfied if modified after the specified date
            return lastModified > date

        case .ifUnmodifiedSince(let date):
            guard let lastModified = lastModified else {
                // If no last modified date exists, assume unmodified
                return true
            }
            // Satisfied if not modified since the specified date
            return lastModified <= date

        case .ifRange(.etag(let etag)):
            guard let currentETag = currentETag else {
                return false
            }
            // Must use strong comparison for If-Range
            return HTTP.EntityTag.strongCompare(etag, currentETag)

        case .ifRange(.date(let date)):
            guard let lastModified = lastModified else {
                return false
            }
            // Satisfied if not modified since the date
            return lastModified <= date
        }
    }
}

// MARK: - CustomStringConvertible

extension HTTP.Precondition: CustomStringConvertible {
    public var description: String {
        return "\(headerName): \(headerValue)"
    }
}

extension HTTP.Precondition.Validator: CustomStringConvertible {
    public var description: String {
        switch self {
        case .etag(let etag):
            return etag.description
        case .date(let date):
            return String(date)
        }
    }
}
