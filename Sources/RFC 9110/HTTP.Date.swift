// HTTP.Date.swift
// swift-rfc-9110
//
// RFC 9110 Section 5.6.7: Date/Time Formats
// https://www.rfc-editor.org/rfc/rfc9110.html#section-5.6.7
//
// HTTP date/time values in RFC 5322 format

import Foundation

extension RFC_9110 {
    /// HTTP Date/Time wrapper (RFC 9110 Section 5.6.7)
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
    /// // Create from Date
    /// let httpDate = HTTP.Date(Date())
    ///
    /// // Format for headers
    /// print(httpDate.headerValue)
    /// // "Mon, 16 Nov 2025 21:30:00 GMT"
    ///
    /// // Parse from header
    /// let parsed = HTTP.Date.parse("Sun, 06 Nov 1994 08:49:37 GMT")
    /// // parsed?.date
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
    public struct Date: Sendable, Equatable, Hashable {
        /// The underlying date value
        public let date: Foundation.Date

        /// Creates an HTTP date from a Foundation Date
        ///
        /// - Parameter date: The date to wrap
        public init(_ date: Foundation.Date) {
            self.date = date
        }

        /// The header value representation (IMF-fixdate format)
        ///
        /// Format: `Day, DD Mon YYYY HH:MM:SS GMT`
        ///
        /// ## Example
        ///
        /// ```swift
        /// let date = HTTP.Date(Date())
        /// print(date.headerValue)
        /// // "Mon, 16 Nov 2025 21:30:00 GMT"
        /// ```
        public var headerValue: String {
            Self.formatter.string(from: date)
        }

        /// Parses an HTTP date from a header value
        ///
        /// Supports both IMF-fixdate (preferred) and obsolete RFC 850/asctime formats.
        ///
        /// - Parameter headerValue: The date string to parse
        /// - Returns: An HTTP.Date if parsing succeeds, nil otherwise
        ///
        /// ## Example
        ///
        /// ```swift
        /// HTTP.Date.parse("Sun, 06 Nov 1994 08:49:37 GMT")
        /// HTTP.Date.parse("Sunday, 06-Nov-94 08:49:37 GMT")  // RFC 850 (obsolete)
        /// HTTP.Date.parse("Sun Nov  6 08:49:37 1994")         // asctime (obsolete)
        /// ```
        public static func parse(_ headerValue: String) -> Date? {
            // Try IMF-fixdate format (preferred)
            if let date = formatter.date(from: headerValue) {
                return Date(date)
            }

            // Try RFC 850 format (obsolete but must accept)
            if let date = rfc850Formatter.date(from: headerValue) {
                return Date(date)
            }

            // Try asctime format (obsolete but must accept)
            if let date = asctimeFormatter.date(from: headerValue) {
                return Date(date)
            }

            return nil
        }

        // MARK: - Date Formatters

        /// IMF-fixdate formatter (preferred format)
        ///
        /// Format: `Day, DD Mon YYYY HH:MM:SS GMT`
        /// Example: `Sun, 06 Nov 1994 08:49:37 GMT`
        private static let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()

        /// RFC 850 formatter (obsolete format, must accept)
        ///
        /// Format: `Weekday, DD-Mon-YY HH:MM:SS GMT`
        /// Example: `Sunday, 06-Nov-94 08:49:37 GMT`
        private static let rfc850Formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd-MMM-yy HH:mm:ss 'GMT'"
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()

        /// asctime formatter (obsolete format, must accept)
        ///
        /// Format: `Day Mon DD HH:MM:SS YYYY`
        /// Example: `Sun Nov  6 08:49:37 1994`
        private static let asctimeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM  d HH:mm:ss yyyy"
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Date: CustomStringConvertible {
    public var description: String {
        headerValue
    }
}

// MARK: - Codable

extension RFC_9110.Date: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let httpDate = RFC_9110.Date.parse(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid HTTP date: \(string)"
            )
        }

        self = httpDate
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(headerValue)
    }
}

// MARK: - Comparable

extension RFC_9110.Date: Comparable {
    public static func < (lhs: RFC_9110.Date, rhs: RFC_9110.Date) -> Bool {
        lhs.date < rhs.date
    }
}

// MARK: - Foundation.Date Conversion

extension Foundation.Date {
    /// Creates a Foundation Date from an HTTP Date
    ///
    /// - Parameter httpDate: The HTTP date to convert
    ///
    /// # Example
    ///
    /// ```swift
    /// let httpDate = HTTP.Date(Date())
    /// let date = Date(httpDate)  // Bidirectional conversion
    /// ```
    public init(_ httpDate: RFC_9110.Date) {
        self = httpDate.date
    }
}
