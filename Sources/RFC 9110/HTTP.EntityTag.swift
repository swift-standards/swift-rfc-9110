// HTTP.EntityTag.swift
// swift-rfc-9110
//
// RFC 9110 Section 8.8.3: ETag
// https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3
//
// Entity tags (ETags) are used for cache validation and conditional requests

import Standards
import INCITS_4_1986

extension RFC_9110 {
    /// HTTP Entity Tag (ETag) per RFC 9110 Section 8.8.3
    ///
    /// An entity tag (ETag) is an opaque validator for differentiating between
    /// multiple representations of the same resource.
    ///
    /// ## Weak vs Strong ETags
    ///
    /// - **Strong ETags**: Indicate byte-for-byte equivalence
    ///   - Format: `"value"`
    ///   - Example: `"686897696a7c876b7e"`
    ///
    /// - **Weak ETags**: Indicate semantic equivalence (representation may differ slightly)
    ///   - Format: `W/"value"`
    ///   - Example: `W/"686897696a7c876b7e"`
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// // Strong ETag
    /// let strong = HTTP.EntityTag(value: "686897696a7c876b7e", isWeak: false)
    /// print(strong.headerValue) // "686897696a7c876b7e"
    ///
    /// // Weak ETag
    /// let weak = HTTP.EntityTag(value: "686897696a7c876b7e", isWeak: true)
    /// print(weak.headerValue) // W/"686897696a7c876b7e"
    ///
    /// // Parsing
    /// let parsed = HTTP.EntityTag.parse("W/\"686897696a7c876b7e\"")
    /// // parsed?.value == "686897696a7c876b7e"
    /// // parsed?.isWeak == true
    /// ```
    ///
    /// ## RFC 9110 Reference
    ///
    /// From RFC 9110 Section 8.8.3:
    /// ```
    /// ETag       = entity-tag
    /// entity-tag = [ weak ] opaque-tag
    /// weak       = %s"W/"
    /// opaque-tag = DQUOTE *etagc DQUOTE
    /// etagc      = %x21 / %x23-7E / obs-text
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 8.8.3: ETag](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3)
    /// - [RFC 9110 Section 13.1: Validators](https://www.rfc-editor.org/rfc/rfc9110.html#section-13.1)
    public struct EntityTag: Sendable, Equatable, Hashable, Codable {
        /// The opaque tag value (without quotes)
        public let value: String

        /// Whether this is a weak entity tag
        ///
        /// - `true`: Weak tag (semantic equivalence) - prefixed with W/
        /// - `false`: Strong tag (byte-for-byte equivalence)
        public let isWeak: Bool

        /// Creates an entity tag
        ///
        /// - Parameters:
        ///   - value: The opaque tag value (without quotes)
        ///   - isWeak: Whether this is a weak entity tag (defaults to false)
        public init(value: String, isWeak: Bool = false) {
            self.value = value
            self.isWeak = isWeak
        }

        /// The header value representation
        ///
        /// - Returns: The ETag formatted for use in HTTP headers
        ///
        /// ## Examples
        ///
        /// ```swift
        /// EntityTag.strong("abc").headerValue  // "abc"
        /// EntityTag.weak("abc").headerValue    // W/"abc"
        /// ```
        public var headerValue: String {
            if isWeak {
                return "W/\"\(value)\""
            } else {
                return "\"\(value)\""
            }
        }

        /// Parses an entity tag from a header value
        ///
        /// - Parameter headerValue: The ETag header value to parse
        /// - Returns: An EntityTag if parsing succeeds, nil otherwise
        ///
        /// ## Example
        ///
        /// ```swift
        /// EntityTag.parse("\"abc123\"")        // EntityTag(value: "abc123", isWeak: false)
        /// EntityTag.parse("W/\"abc123\"")      // EntityTag(value: "abc123", isWeak: true)
        /// EntityTag.parse("invalid")           // nil
        /// ```
        public static func parse(_ headerValue: String) -> EntityTag? {
            let trimmed = headerValue.trimming(.ascii.whitespaces)

            // Check for weak prefix
            let isWeak: Bool
            let tagPart: String

            if trimmed.hasPrefix("W/\"") {
                isWeak = true
                tagPart = String(trimmed.dropFirst(2)) // Remove "W/"
            } else if trimmed.hasPrefix("\"") {
                isWeak = false
                tagPart = trimmed
            } else {
                return nil
            }

            // Extract quoted value
            guard tagPart.hasPrefix("\"") && tagPart.hasSuffix("\"") else {
                return nil
            }

            let value = String(tagPart.dropFirst().dropLast())
            return EntityTag(value: value, isWeak: isWeak)
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.EntityTag: CustomStringConvertible {
    public var description: String {
        headerValue
    }
}

// MARK: - Codable

extension RFC_9110.EntityTag {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let entityTag = RFC_9110.EntityTag.parse(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid entity tag: \(string)"
            )
        }

        self = entityTag
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(headerValue)
    }
}

// MARK: - LosslessStringConvertible

extension RFC_9110.EntityTag: LosslessStringConvertible {
    /// Creates an entity tag from a string description
    ///
    /// - Parameter description: The ETag string (e.g., `"abc123"`, `W/"abc123"`)
    /// - Returns: An entity tag instance, or nil if parsing fails
    ///
    /// # Example
    ///
    /// ```swift
    /// let etag = HTTP.EntityTag("\"abc123\"")  // Strong ETag
    /// let str = String(etag)                   // "\"abc123\"" - perfect round-trip
    /// ```
    public init?(_ description: String) {
        guard let parsed = Self.parse(description) else { return nil }
        self = parsed
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_9110.EntityTag: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        if let parsed = RFC_9110.EntityTag.parse(value) {
            self = parsed
        } else {
            // Fallback: treat as strong ETag with the literal value
            self = RFC_9110.EntityTag(value: value, isWeak: false)
        }
    }
}

// MARK: - Factory Methods and Comparison

extension RFC_9110.EntityTag {
    /// Creates a strong entity tag
    ///
    /// - Parameter value: The opaque tag value
    /// - Returns: A strong entity tag
    public static func strong(_ value: String) -> Self {
        Self(value: value, isWeak: false)
    }

    /// Creates a weak entity tag
    ///
    /// - Parameter value: The opaque tag value
    /// - Returns: A weak entity tag
    public static func weak(_ value: String) -> Self {
        Self(value: value, isWeak: true)
    }

    /// Performs a strong comparison between two entity tags
    ///
    /// Strong comparison returns true only if both tags are strong and
    /// their values match byte-for-byte.
    ///
    /// - Parameters:
    ///   - lhs: The first entity tag
    ///   - rhs: The second entity tag
    /// - Returns: True if both are strong tags with matching values
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 8.8.3.2: Comparison](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3.2)
    public static func strongCompare(_ lhs: Self, _ rhs: Self) -> Bool {
        !lhs.isWeak && !rhs.isWeak && lhs.value == rhs.value
    }

    /// Performs a weak comparison between two entity tags
    ///
    /// Weak comparison returns true if the values match, regardless of
    /// whether the tags are weak or strong.
    ///
    /// - Parameters:
    ///   - lhs: The first entity tag
    ///   - rhs: The second entity tag
    /// - Returns: True if the values match
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 8.8.3.2: Comparison](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3.2)
    public static func weakCompare(_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.value == rhs.value
    }
}
