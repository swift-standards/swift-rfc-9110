// HTTP.Content.Negotiation.MediaTypePreference.swift
// swift-rfc-9110
//
// RFC 9110 Section 12.5.1: Accept
// https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.1
//
// Media type preference for content negotiation

import Parser_Primitives

// MARK: - Media Type Preference

extension RFC_9110.Content.Negotiation {
    /// Media type preference from Accept header (RFC 9110 Section 12.5.1)
    ///
    /// Represents a media type pattern with an optional quality value.
    ///
    /// ## Example
    ///
    /// ```
    /// Accept: text/html, application/json;q=0.9, */*;q=0.1
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.5.1: Accept](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.1)
    public struct MediaTypePreference: Sendable, Equatable {
        /// The media type pattern
        public let mediaType: RFC_9110.MediaType

        /// The quality value (defaults to 1.0)
        public let quality: QualityValue

        /// Creates a media type preference
        ///
        /// - Parameters:
        ///   - mediaType: The media type
        ///   - quality: The quality value (defaults to 1.0)
        public init(mediaType: RFC_9110.MediaType, quality: QualityValue = .default) {
            self.mediaType = mediaType
            self.quality = quality
        }

        /// Parses media type preferences from an Accept header value
        ///
        /// - Parameter headerValue: The Accept header value
        /// - Returns: An array of media type preferences, sorted by quality (descending)
        ///
        /// ## Example
        ///
        /// ```swift
        /// let prefs = HTTP.Content.Negotiation.MediaTypePreference.parse(
        ///     "text/html, application/json;q=0.9, */*;q=0.1"
        /// )
        /// // Returns 3 preferences sorted by quality
        /// ```
        public static func parse(_ headerValue: String) -> [MediaTypePreference] {
            var input = Parser_Primitives.Parser.Input.Bytes(utf8: headerValue)
            let preferences = HTTP.Parse.CommaSeparated<Parser_Primitives.Parser.Input.Bytes, MediaTypePreference> { element in
                var sub = element
                guard let mediaType = try? HTTP.MediaType.Parser<Parser_Primitives.Parser.Input.Bytes>().parse(&sub) else {
                    return nil
                }
                // Extract quality from parameters (q= is parsed as a media type parameter)
                var quality = QualityValue.default
                if let qStr = mediaType.parameters["q"], let q = Double(qStr) {
                    quality = QualityValue(q)
                }
                // Remove q from media type parameters
                var params = mediaType.parameters
                params.removeValue(forKey: "q")
                let cleanMediaType = RFC_9110.MediaType(mediaType.type, mediaType.subtype, parameters: params)
                return MediaTypePreference(mediaType: cleanMediaType, quality: quality)
            }.parse(&input)

            // Sort by quality (descending), then by specificity
            return preferences.sorted { lhs, rhs in
                if lhs.quality.value != rhs.quality.value {
                    return lhs.quality > rhs.quality
                }
                if lhs.mediaType.type == "*" && rhs.mediaType.type != "*" { return false }
                if lhs.mediaType.type != "*" && rhs.mediaType.type == "*" { return true }
                if lhs.mediaType.subtype == "*" && rhs.mediaType.subtype != "*" { return false }
                if lhs.mediaType.subtype != "*" && rhs.mediaType.subtype == "*" { return true }
                return false
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Content.Negotiation.MediaTypePreference: CustomStringConvertible {
    public var description: String {
        if quality == .default {
            return mediaType.value
        } else {
            return "\(mediaType.value);q=\(quality)"
        }
    }
}
