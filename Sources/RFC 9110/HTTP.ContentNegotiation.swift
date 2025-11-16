// HTTP.ContentNegotiation.swift
// swift-rfc-9110
//
// RFC 9110 Section 12: Content Negotiation
// https://www.rfc-editor.org/rfc/rfc9110.html#section-12
//
// Proactive content negotiation mechanisms

import Foundation

extension RFC_9110 {
    /// HTTP Content Negotiation (RFC 9110 Section 12)
    ///
    /// Content negotiation allows servers to select the most appropriate representation
    /// of a resource based on client preferences expressed in request headers.
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12: Content Negotiation](https://www.rfc-editor.org/rfc/rfc9110.html#section-12)
    public enum ContentNegotiation {}
}

// MARK: - Quality Value

extension RFC_9110.ContentNegotiation {
    /// Quality value (qvalue) per RFC 9110 Section 12.4.2
    ///
    /// Quality values indicate relative preference, ranging from 0 (not acceptable)
    /// to 1 (most preferred).
    ///
    /// ## Example
    ///
    /// ```
    /// Accept: text/html;q=1.0, text/plain;q=0.8, */*;q=0.1
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.4.2: Quality Values](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.4.2)
    public struct QualityValue: Sendable, Equatable, Hashable, Comparable {
        /// The quality value (0.0 to 1.0)
        public let value: Double

        /// Creates a quality value
        ///
        /// - Parameter value: The quality value (clamped to 0.0...1.0)
        public init(_ value: Double) {
            self.value = min(max(value, 0.0), 1.0)
        }

        /// Parses a quality value from a string
        ///
        /// - Parameter string: The quality value string (e.g., "0.8", "1.0")
        /// - Returns: A QualityValue if parsing succeeds, nil otherwise
        public static func parse(_ string: String) -> QualityValue? {
            guard let doubleValue = Double(string) else { return nil }
            return QualityValue(doubleValue)
        }

        /// Default quality value (1.0)
        public static let `default` = QualityValue(1.0)

        /// Zero quality value (not acceptable)
        public static let zero = QualityValue(0.0)

        // MARK: - Comparable

        public static func < (lhs: QualityValue, rhs: QualityValue) -> Bool {
            lhs.value < rhs.value
        }
    }
}

// MARK: - Media Type Preference

extension RFC_9110.ContentNegotiation {
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
        /// let prefs = HTTP.ContentNegotiation.MediaTypePreference.parse(
        ///     "text/html, application/json;q=0.9, */*;q=0.1"
        /// )
        /// // Returns 3 preferences sorted by quality
        /// ```
        public static func parse(_ headerValue: String) -> [MediaTypePreference] {
            let components = headerValue.components(separatedBy: ",")
            var preferences: [MediaTypePreference] = []

            for component in components {
                let trimmed = component.trimmingCharacters(in: .whitespaces)

                // Split on semicolon to separate media type from parameters
                let parts = trimmed.components(separatedBy: ";")
                guard let typeSubtype = parts.first,
                      let mediaType = RFC_9110.MediaType.parse(typeSubtype) else {
                    continue
                }

                // Look for q parameter
                var quality = QualityValue.default
                for part in parts.dropFirst() {
                    let param = part.trimmingCharacters(in: .whitespaces)
                    if param.hasPrefix("q=") {
                        let qValue = String(param.dropFirst(2))
                        if let parsed = QualityValue.parse(qValue) {
                            quality = parsed
                        }
                    }
                }

                preferences.append(MediaTypePreference(mediaType: mediaType, quality: quality))
            }

            // Sort by quality (descending), then by specificity
            return preferences.sorted { lhs, rhs in
                if lhs.quality.value != rhs.quality.value {
                    return lhs.quality > rhs.quality
                }

                // More specific types come first
                if lhs.mediaType.type == "*" && rhs.mediaType.type != "*" {
                    return false
                }
                if lhs.mediaType.type != "*" && rhs.mediaType.type == "*" {
                    return true
                }
                if lhs.mediaType.subtype == "*" && rhs.mediaType.subtype != "*" {
                    return false
                }
                if lhs.mediaType.subtype != "*" && rhs.mediaType.subtype == "*" {
                    return true
                }

                return false
            }
        }
    }
}

// MARK: - Content Negotiation Algorithm

extension RFC_9110.ContentNegotiation {
    /// Selects the best media type from available options based on Accept header
    ///
    /// - Parameters:
    ///   - available: The available media types that can be served
    ///   - acceptHeader: The Accept header value from the request
    /// - Returns: The best matching media type, or nil if none is acceptable
    ///
    /// ## Example
    ///
    /// ```swift
    /// let available = [HTTP.MediaType.json, HTTP.MediaType.xml]
    /// let selected = HTTP.ContentNegotiation.selectMediaType(
    ///     from: available,
    ///     acceptHeader: "application/json, application/xml;q=0.9"
    /// )
    /// // Returns .json (highest quality match)
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.1: Proactive Negotiation](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.1)
    public static func selectMediaType(
        from available: [RFC_9110.MediaType],
        acceptHeader: String
    ) -> RFC_9110.MediaType? {
        let preferences = MediaTypePreference.parse(acceptHeader)

        // Try each preference in order (already sorted by quality)
        for preference in preferences {
            // Find first available type that matches this preference
            for availableType in available {
                if availableType.matches(preference.mediaType) {
                    return availableType
                }
            }
        }

        return nil
    }

    /// Selects the best media types from available options based on Accept header
    ///
    /// Returns all acceptable media types sorted by preference.
    ///
    /// - Parameters:
    ///   - available: The available media types that can be served
    ///   - acceptHeader: The Accept header value from the request
    /// - Returns: Array of acceptable media types sorted by quality (best first)
    public static func selectMediaTypes(
        from available: [RFC_9110.MediaType],
        acceptHeader: String
    ) -> [RFC_9110.MediaType] {
        let preferences = MediaTypePreference.parse(acceptHeader)
        var results: [(RFC_9110.MediaType, QualityValue)] = []

        for availableType in available {
            // Find the best matching preference for this available type
            var bestQuality: QualityValue?

            for preference in preferences {
                if availableType.matches(preference.mediaType) {
                    if bestQuality == nil || preference.quality > bestQuality! {
                        bestQuality = preference.quality
                    }
                }
            }

            if let quality = bestQuality, quality.value > 0.0 {
                results.append((availableType, quality))
            }
        }

        // Sort by quality (descending)
        return results
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.ContentNegotiation.QualityValue: CustomStringConvertible {
    public var description: String {
        String(format: "%.3f", value).replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
    }
}

extension RFC_9110.ContentNegotiation.MediaTypePreference: CustomStringConvertible {
    public var description: String {
        if quality == .default {
            return mediaType.value
        } else {
            return "\(mediaType.value);q=\(quality)"
        }
    }
}
