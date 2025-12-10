// HTTP.ContentNegotiation.swift
// swift-rfc-9110
//
// RFC 9110 Section 12: Content Negotiation
// https://www.rfc-editor.org/rfc/rfc9110.html#section-12
//
// Proactive content negotiation mechanisms

import INCITS_4_1986
import Standards

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

// MARK: - QualityValue Numeric Literals

extension RFC_9110.ContentNegotiation.QualityValue: ExpressibleByFloatLiteral {
    /// Creates a quality value from a floating-point literal
    ///
    /// - Parameter value: The floating-point literal (0.0 to 1.0)
    ///
    /// # Example
    ///
    /// ```swift
    /// let q: HTTP.ContentNegotiation.QualityValue = 0.8
    /// ```
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension RFC_9110.ContentNegotiation.QualityValue: ExpressibleByIntegerLiteral {
    /// Creates a quality value from an integer literal
    ///
    /// - Parameter value: The integer literal (typically 0 or 1)
    ///
    /// # Example
    ///
    /// ```swift
    /// let full: HTTP.ContentNegotiation.QualityValue = 1
    /// let none: HTTP.ContentNegotiation.QualityValue = 0
    /// ```
    public init(integerLiteral value: Int) {
        self.init(Double(value))
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
            let components = headerValue.split(separator: ",")
            var preferences: [MediaTypePreference] = []

            for component in components {
                let trimmed = component.trimming(.ascii.whitespaces)

                // Split on semicolon to separate media type from parameters
                let parts = trimmed.split(separator: ";")
                guard let typeSubtype = parts.first,
                    let mediaType = RFC_9110.MediaType.parse(String(typeSubtype))
                else {
                    continue
                }

                // Look for q parameter
                var quality = QualityValue.default
                for part in parts.dropFirst() {
                    let param = part.trimming(.ascii.whitespaces)
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
        return
            results
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.ContentNegotiation.QualityValue: CustomStringConvertible {
    public var description: String {
        // Convert to string with 3 decimal places
        let rounded = (value * 1000).rounded() / 1000
        var result = "\(rounded)"

        // If no decimal point, we're done
        guard result.contains(".") else { return result }

        // Remove trailing zeros and decimal point if needed
        result = result.replacing(/\.?0+$/, with: "")

        return result
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

// MARK: - Encoding Preference (Section 12.5.3)

extension RFC_9110.ContentNegotiation {
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
        public let encoding: RFC_9110.ContentEncoding

        /// The quality value (defaults to 1.0)
        public let quality: QualityValue

        /// Creates an encoding preference
        ///
        /// - Parameters:
        ///   - encoding: The content encoding
        ///   - quality: The quality value (defaults to 1.0)
        public init(encoding: RFC_9110.ContentEncoding, quality: QualityValue = .default) {
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
        /// let prefs = HTTP.ContentNegotiation.EncodingPreference.parse(
        ///     "gzip;q=1.0, br;q=0.8, deflate;q=0.5"
        /// )
        /// ```
        public static func parse(_ headerValue: String) -> [EncodingPreference] {
            let components = headerValue.split(separator: ",")
            var preferences: [EncodingPreference] = []

            for component in components {
                let trimmed = component.trimming(.ascii.whitespaces)

                // Split on semicolon to separate encoding from quality
                let parts = trimmed.split(separator: ";")
                guard let encodingString = parts.first?.trimming(.ascii.whitespaces),
                    !encodingString.isEmpty
                else {
                    continue
                }

                let encoding = RFC_9110.ContentEncoding(encodingString)

                // Look for q parameter
                var quality = QualityValue.default
                for part in parts.dropFirst() {
                    let param = part.trimming(.ascii.whitespaces)
                    if param.hasPrefix("q=") {
                        let qValue = String(param.dropFirst(2))
                        if let parsed = QualityValue.parse(qValue) {
                            quality = parsed
                        }
                    }
                }

                preferences.append(EncodingPreference(encoding: encoding, quality: quality))
            }

            // Sort by quality (descending)
            return preferences.sorted { $0.quality > $1.quality }
        }
    }
}

extension RFC_9110.ContentNegotiation.EncodingPreference: CustomStringConvertible {
    public var description: String {
        if quality == .default {
            return encoding.value
        } else {
            return "\(encoding.value);q=\(quality)"
        }
    }
}

// MARK: - Language Preference (Section 12.5.4)

extension RFC_9110.ContentNegotiation {
    /// Language preference from Accept-Language header (RFC 9110 Section 12.5.4)
    ///
    /// Represents a language tag with an optional quality value.
    ///
    /// ## Example
    ///
    /// ```
    /// Accept-Language: en-US;q=1.0, fr;q=0.8, de;q=0.5
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.5.4: Accept-Language](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.4)
    public struct LanguagePreference: Sendable, Equatable {
        /// The language tag (e.g., "en-US", "fr", "de")
        public let language: String

        /// The quality value (defaults to 1.0)
        public let quality: QualityValue

        /// Creates a language preference
        ///
        /// - Parameters:
        ///   - language: The language tag
        ///   - quality: The quality value (defaults to 1.0)
        public init(language: String, quality: QualityValue = .default) {
            self.language = language
            self.quality = quality
        }

        /// Parses language preferences from an Accept-Language header value
        ///
        /// - Parameter headerValue: The Accept-Language header value
        /// - Returns: An array of language preferences, sorted by quality (descending)
        ///
        /// ## Example
        ///
        /// ```swift
        /// let prefs = HTTP.ContentNegotiation.LanguagePreference.parse(
        ///     "en-US;q=1.0, fr;q=0.8, *;q=0.1"
        /// )
        /// ```
        public static func parse(_ headerValue: String) -> [LanguagePreference] {
            let components = headerValue.split(separator: ",")
            var preferences: [LanguagePreference] = []

            for component in components {
                let trimmed = component.trimming(.ascii.whitespaces)

                // Split on semicolon to separate language from quality
                let parts = trimmed.split(separator: ";")
                guard let language = parts.first?.trimming(.ascii.whitespaces),
                    !language.isEmpty
                else {
                    continue
                }

                // Look for q parameter
                var quality = QualityValue.default
                for part in parts.dropFirst() {
                    let param = part.trimming(.ascii.whitespaces)
                    if param.hasPrefix("q=") {
                        let qValue = String(param.dropFirst(2))
                        if let parsed = QualityValue.parse(qValue) {
                            quality = parsed
                        }
                    }
                }

                preferences.append(LanguagePreference(language: language, quality: quality))
            }

            // Sort by quality (descending), then by specificity
            return preferences.sorted { lhs, rhs in
                if lhs.quality.value != rhs.quality.value {
                    return lhs.quality > rhs.quality
                }
                // More specific language tags come first (en-US before en)
                return lhs.language.count > rhs.language.count
            }
        }
    }
}

extension RFC_9110.ContentNegotiation.LanguagePreference: CustomStringConvertible {
    public var description: String {
        if quality == .default {
            return language
        } else {
            return "\(language);q=\(quality)"
        }
    }
}

// MARK: - Charset Preference (Section 12.5.2)

extension RFC_9110.ContentNegotiation {
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
        /// let prefs = HTTP.ContentNegotiation.CharsetPreference.parse(
        ///     "utf-8;q=1.0, iso-8859-1;q=0.5"
        /// )
        /// ```
        public static func parse(_ headerValue: String) -> [CharsetPreference] {
            let components = headerValue.split(separator: ",")
            var preferences: [CharsetPreference] = []

            for component in components {
                let trimmed = component.trimming(.ascii.whitespaces)

                // Split on semicolon to separate charset from quality
                let parts = trimmed.split(separator: ";")
                guard let charset = parts.first?.trimming(.ascii.whitespaces),
                    !charset.isEmpty
                else {
                    continue
                }

                // Look for q parameter
                var quality = QualityValue.default
                for part in parts.dropFirst() {
                    let param = part.trimming(.ascii.whitespaces)
                    if param.hasPrefix("q=") {
                        let qValue = String(param.dropFirst(2))
                        if let parsed = QualityValue.parse(qValue) {
                            quality = parsed
                        }
                    }
                }

                preferences.append(CharsetPreference(charset: charset, quality: quality))
            }

            // Sort by quality (descending)
            return preferences.sorted { $0.quality > $1.quality }
        }
    }
}

extension RFC_9110.ContentNegotiation.CharsetPreference: CustomStringConvertible {
    public var description: String {
        if quality == .default {
            return charset
        } else {
            return "\(charset);q=\(quality)"
        }
    }
}
