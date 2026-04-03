// HTTP.Header.Field.Value.swift
// swift-rfc-9110

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
        public init(_ rawValue: String) throws(Error) {
            // RFC 9110 Section 5.5: field-content cannot contain CR or LF
            // Check for CR (U+000D) and LF (U+000A) characters
            if rawValue.unicodeScalars.contains(where: { $0 == "\r" }) {
                throw Error.invalidFieldValue(
                    value: rawValue,
                    reason:
                        "Header field value contains CR (carriage return) character, forbidden by RFC 9110 §5.5"
                )
            }

            if rawValue.unicodeScalars.contains(where: { $0 == "\n" }) {
                throw Error.invalidFieldValue(
                    value: rawValue,
                    reason:
                        "Header field value contains LF (line feed) character, forbidden by RFC 9110 §5.5"
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

// MARK: - CustomStringConvertible

extension RFC_9110.Header.Field.Value: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

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
