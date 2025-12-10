// HTTP.Date.swift
// swift-rfc-9110
//
// RFC 9110 Section 5.6.7: Date/Time Formats
// https://www.rfc-editor.org/rfc/rfc9110.html#section-5.6.7
//
// HTTP date/time values in RFC 5322 format

public import RFC_5322

extension RFC_9110 {
    /// HTTP Date/Time (RFC 9110 Section 5.6.7)
    ///
    /// HTTP uses RFC 5322 date format for timestamps in headers like
    /// Date, Last-Modified, and Expires.
    ///
    /// ## Format
    ///
    /// The preferred format is IMF-fixdate:
    /// ```
    /// Sun, 06 Nov 1994 08:49:37 GMT
    /// ```
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// // Create from components
    /// let httpDate = HTTP.Date(year: 2025, month: 11, day: 16, hour: 21, minute: 30, second: 0)
    ///
    /// // Create header field from date
    /// let field = HTTP.Header.Field(dateTime: httpDate)
    /// // Field(name: "Date", value: "Mon, 16 Nov 2025 21:30:00 +0000")
    ///
    /// // Parse from header field
    /// if let parsed = RFC_5322.DateTime(field) {
    ///     print(parsed)
    /// }
    /// ```
    ///
    /// ## RFC 9110 Reference
    ///
    /// From RFC 9110 Section 5.6.7:
    /// ```
    /// HTTP-date    = IMF-fixdate / obs-date
    /// IMF-fixdate  = day-name "," SP date1 SP time-of-day SP GMT
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 5.6.7: Date/Time Formats](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.6.7)
    /// - [RFC 5322: Internet Message Format](https://www.rfc-editor.org/rfc/rfc5322.html)
    ///
    /// ## Note
    ///
    /// Currently only supports IMF-fixdate format (RFC 5322 format).
    /// Obsolete formats (RFC 850, asctime) are not yet supported for parsing.
    public typealias Date = RFC_5322.DateTime
}

// MARK: - HTTP-Specific Extensions

// MARK: - HTTP.Header.Field -> RFC_5322.DateTime

extension RFC_5322.DateTime {
    /// Creates an RFC 5322 DateTime from an HTTP header field value
    ///
    /// Parses date headers like Date, Last-Modified, and Expires.
    /// Currently supports IMF-fixdate format (RFC 5322 format).
    ///
    /// - Parameter field: The HTTP header field containing the date
    ///
    /// ## Example
    ///
    /// ```swift
    /// let field = try HTTP.Header.Field(name: "Date", value: "Sun, 06 Nov 1994 08:49:37 +0000")
    /// if let dateTime = RFC_5322.DateTime(field) {
    ///     print(dateTime)
    /// }
    /// ```
    ///
    /// ## Note
    ///
    /// Obsolete formats (RFC 850, asctime) are not yet supported.
    public init?(_ field: RFC_9110.Header.Field) {
        guard let parsed = try? RFC_5322.DateTime(ascii: field.value.rawValue.utf8) else {
            return nil
        }
        self = parsed
    }

    /// Creates an RFC 5322 DateTime from an HTTP header field value
    ///
    /// - Parameter value: The HTTP header field value containing the date
    public init?(_ value: RFC_9110.Header.Field.Value) {
        guard let parsed = try? RFC_5322.DateTime(ascii: value.rawValue.utf8) else {
            return nil
        }
        self = parsed
    }
}

// MARK: - RFC_5322.DateTime -> HTTP.Header.Field

extension RFC_9110.Header.Field {
    /// Creates a Date header field from an RFC 5322 DateTime
    ///
    /// Format: `Day, DD Mon YYYY HH:MM:SS +0000`
    ///
    /// - Parameter dateTime: The RFC 5322 DateTime to format
    /// - Parameter name: The header name (default: "Date")
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dateTime = HTTP.Date(year: 2025, month: 11, day: 16, hour: 21, minute: 30, second: 0)
    /// let field = HTTP.Header.Field(dateTime: dateTime)
    /// // Field(name: "Date", value: "Mon, 16 Nov 2025 21:30:00 +0000")
    /// ```
    public init(dateTime: RFC_5322.DateTime, name: Name = .date) {
        self.init(
            name: name,
            value: .init(unchecked: String(dateTime))
        )
    }
}
