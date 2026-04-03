// HTTP.Header.Field.swift
// swift-rfc-9110

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
        public init(name: String, value: String) throws(Error) {
            self.name = Name(name)
            self.value = try Value(value)
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Header.Field: CustomStringConvertible {
    /// Returns the header field in HTTP format (name: value)
    public var description: String {
        "\(name.rawValue): \(value.rawValue)"
    }
}
