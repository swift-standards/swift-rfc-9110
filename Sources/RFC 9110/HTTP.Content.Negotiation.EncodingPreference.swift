// HTTP.Content.Negotiation.EncodingPreference.swift
// swift-rfc-9110
//
// RFC 9110 Section 12.5.3: Accept-Encoding
// https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.3
//
// Content encoding preference for content negotiation

import Parser_Primitives

// MARK: - Encoding Preference (Section 12.5.3)

extension RFC_9110.Content.Negotiation {
    /// Content encoding preference from Accept-Encoding header (RFC 9110 Section 12.5.3)
    ///
    /// Represents a content encoding with an optional quality value.
    ///
    /// ## Example
    ///
    /// ```
    /// Accept-Encoding: gzip;q=1.0, br;q=0.8, deflate;q=0.5
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.5.3: Accept-Encoding](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.3)
    public struct EncodingPreference: Sendable, Equatable {
        /// The content encoding
        public let encoding: RFC_9110.Content.Encoding

        /// The quality value (defaults to 1.0)
        public let quality: QualityValue

        /// Creates an encoding preference
        ///
        /// - Parameters:
        ///   - encoding: The content encoding
        ///   - quality: The quality value (defaults to 1.0)
        public init(encoding: RFC_9110.Content.Encoding, quality: QualityValue = .default) {
            self.encoding = encoding
            self.quality = quality
        }

        /// Parses encoding preferences from an Accept-Encoding header value
        ///
        /// - Parameter headerValue: The Accept-Encoding header value
        /// - Returns: An array of encoding preferences, sorted by quality (descending)
        ///
        /// ## Example
        ///
        /// ```swift
        /// let prefs = HTTP.Content.Negotiation.EncodingPreference.parse(
        ///     "gzip;q=1.0, br;q=0.8, deflate;q=0.5"
        /// )
        /// ```
        public static func parse(_ headerValue: String) -> [EncodingPreference] {
            var input = Parser_Primitives.Parser.Input.Bytes(utf8: headerValue)
            let preferences = HTTP.Parse.CommaSeparated<Parser_Primitives.Parser.Input.Bytes, EncodingPreference> { element in
                var sub = element
                guard let token = try? HTTP.Parse.Token<Parser_Primitives.Parser.Input.Bytes>().parse(&sub) else {
                    return nil
                }
                let encoding = RFC_9110.Content.Encoding(String(decoding: token, as: UTF8.self))
                var quality = QualityValue.default
                if let q = try? HTTP.Parse.QualityValue<Parser_Primitives.Parser.Input.Bytes>().parse(&sub) {
                    quality = QualityValue(Double(q) / 1000.0)
                }
                return EncodingPreference(encoding: encoding, quality: quality)
            }.parse(&input)
            return preferences.sorted { $0.quality > $1.quality }
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Content.Negotiation.EncodingPreference: CustomStringConvertible {
    public var description: String {
        if quality == .default {
            return encoding.value
        } else {
            return "\(encoding.value);q=\(quality)"
        }
    }
}
