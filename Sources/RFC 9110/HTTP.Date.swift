// HTTP.Date.swift
// swift-rfc-9110
//
// RFC 9110 Section 5.6.7: Date/Time Formats
// https://www.rfc-editor.org/rfc/rfc9110.html#section-5.6.7
//
// HTTP date/time values in RFC 5322 format

import RFC_5322

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
    /// // Format for headers
    /// print(httpDate.httpHeaderValue)
    /// // "Mon, 16 Nov 2025 21:30:00 +0000"
    ///
    /// // Parse from header
    /// if let parsed = HTTP.Date.parseHTTP("Sun, 06 Nov 1994 08:49:37 +0000") {
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

extension RFC_5322.DateTime {
    /// The HTTP header value representation (IMF-fixdate format)
    ///
    /// Format: `Day, DD Mon YYYY HH:MM:SS +0000`
    ///
    /// ## Example
    ///
    /// ```swift
    /// let ts = HTTP.Date(year: 2025, month: 11, day: 16, hour: 21, minute: 30, second: 0)
    /// print(ts.httpHeaderValue)
    /// // "Mon, 16 Nov 2025 21:30:00 +0000"
    /// ```
    public var httpHeaderValue: String {
        RFC_5322.Date.format(self)
    }

    /// Parses an HTTP date from a header value
    ///
    /// Currently supports IMF-fixdate format (RFC 5322 format).
    ///
    /// - Parameter headerValue: The date string to parse
    /// - Returns: A Timestamp if parsing succeeds, nil otherwise
    ///
    /// ## Example
    ///
    /// ```swift
    /// HTTP.Date.parseHTTP("Sun, 06 Nov 1994 08:49:37 +0000")
    /// ```
    ///
    /// ## Note
    ///
    /// Obsolete formats (RFC 850, asctime) are not yet supported.
    public static func parseHTTP(_ headerValue: String) -> RFC_5322.DateTime? {
        try? RFC_5322.Date.parse(headerValue)
    }
}
