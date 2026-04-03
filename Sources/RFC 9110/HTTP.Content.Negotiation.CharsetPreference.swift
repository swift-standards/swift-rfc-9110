// HTTP.Content.Negotiation.CharsetPreference.swift
// swift-rfc-9110
//
// RFC 9110 Section 12.5.2: Accept-Charset
// https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.2
//
// Charset preference for content negotiation

import Parser_Primitives

// MARK: - Charset Preference (Section 12.5.2)

extension RFC_9110.Content.Negotiation {
    /// Charset preference from Accept-Charset header (RFC 9110 Section 12.5.2)
    ///
    /// Represents a character encoding with an optional quality value.
    ///
    /// ## Example
    ///
    /// ```
    /// Accept-Charset: utf-8;q=1.0, iso-8859-1;q=0.5
    /// ```
    ///
    /// ## Note
    ///
    /// Accept-Charset is rarely used in modern applications since UTF-8
    /// has become the universal standard.
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.5.2: Accept-Charset](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.2)
    public struct CharsetPreference: Sendable, Equatable {
        /// The charset name (e.g., "utf-8", "iso-8859-1")
        public let charset: String

        /// The quality value (defaults to 1.0)
        public let quality: QualityValue

        /// Creates a charset preference
        ///
        /// - Parameters:
        ///   - charset: The charset name
        ///   - quality: The quality value (defaults to 1.0)
        public init(charset: String, quality: QualityValue = .default) {
            self.charset = charset.lowercased()
            self.quality = quality
        }

        /// Parses charset preferences from an Accept-Charset header value
        ///
        /// - Parameter headerValue: The Accept-Charset header value
        /// - Returns: An array of charset preferences, sorted by quality (descending)
        ///
        /// ## Example
        ///
        /// ```swift
        /// let prefs = HTTP.Content.Negotiation.CharsetPreference.parse(
        ///     "utf-8;q=1.0, iso-8859-1;q=0.5"
        /// )
        /// ```
        public static func parse(_ headerValue: String) -> [CharsetPreference] {
            var input = Parser_Primitives.Parser.Input.Bytes(utf8: headerValue)
            let preferences = HTTP.Parse.CommaSeparated<Parser_Primitives.Parser.Input.Bytes, CharsetPreference> { element in
                var sub = element
                guard let token = try? HTTP.Parse.Token<Parser_Primitives.Parser.Input.Bytes>().parse(&sub) else {
                    return nil
                }
                var quality = QualityValue.default
                if let q = try? HTTP.Parse.QualityValue<Parser_Primitives.Parser.Input.Bytes>().parse(&sub) {
                    quality = QualityValue(Double(q) / 1000.0)
                }
                return CharsetPreference(charset: String(decoding: token, as: UTF8.self), quality: quality)
            }.parse(&input)
            return preferences.sorted { $0.quality > $1.quality }
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Content.Negotiation.CharsetPreference: CustomStringConvertible {
    public var description: String {
        if quality == .default {
            return charset
        } else {
            return "\(charset);q=\(quality)"
        }
    }
}
