// HTTP.ContentLanguage.swift
// swift-rfc-9110

import Standards
import INCITS_4_1986

extension HTTP {
    /// Content-Language header field (RFC 9110 Section 8.5)
    ///
    /// The "Content-Language" header field describes the natural language(s)
    /// of the intended audience for the representation.
    ///
    /// # Example
    ///
    /// ```swift
    /// let language = HTTP.ContentLanguage("en-US")
    /// let languages = HTTP.ContentLanguage.parse("en-US, fr-CA")
    /// ```
    ///
    /// # RFC 9110 Section 8.5
    ///
    /// ```
    /// Content-Language = #language-tag
    /// ```
    ///
    /// Language tags are defined in [RFC 5646](https://www.rfc-editor.org/rfc/rfc5646.html).
    ///
    public struct ContentLanguage: Sendable, Equatable, Hashable {
        /// The language tag (e.g., "en", "en-US", "fr-CA")
        public let tag: String

        /// Creates a content language with the specified language tag
        ///
        /// - Parameter tag: A language tag per RFC 5646 (e.g., "en-US")
        public init(_ tag: String) {
            // Normalize to lowercase for case-insensitive comparison
            self.tag = tag.lowercased()
        }

        // MARK: - Header Parsing

        /// Parses a Content-Language header value into an array of ContentLanguage values
        ///
        /// - Parameter headerValue: The Content-Language header value (e.g., "en-US, fr-CA")
        /// - Returns: An array of ContentLanguage values
        ///
        /// # Example
        ///
        /// ```swift
        /// let languages = HTTP.ContentLanguage.parse("en-US, fr-CA")
        /// // [ContentLanguage("en-us"), ContentLanguage("fr-ca")]
        /// ```
        public static func parse(_ headerValue: String) -> [ContentLanguage] {
            return headerValue
                .split(separator: ",")
                .map { $0.trimming(.whitespaces) }
                .filter { !$0.isEmpty }
                .map { ContentLanguage(String($0)) }
        }

        /// Formats an array of ContentLanguage values into a header value
        ///
        /// - Parameter languages: The languages to format
        /// - Returns: A Content-Language header value
        ///
        /// # Example
        ///
        /// ```swift
        /// let header = HTTP.ContentLanguage.formatHeader([.englishUS, .frenchCA])
        /// // "en-us, fr-ca"
        /// ```
        public static func formatHeader(_ languages: [ContentLanguage]) -> String {
            return languages
                .map { $0.tag }
                .joined(separator: ", ")
        }
    }
}

// MARK: - Codable

extension HTTP.ContentLanguage: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let tag = try container.decode(String.self)
        self.init(tag)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(tag)
    }
}

// MARK: - CustomStringConvertible

extension HTTP.ContentLanguage: CustomStringConvertible {
    public var description: String {
        return tag
    }
}

// MARK: - ExpressibleByStringLiteral

extension HTTP.ContentLanguage: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - Common Language Tags

extension HTTP.ContentLanguage {
    /// English
    public static let english = Self("en")

    /// English (United States)
    public static let englishUS = Self("en-US")

    /// English (United Kingdom)
    public static let englishUK = Self("en-GB")

    /// French
    public static let french = Self("fr")

    /// French (Canada)
    public static let frenchCA = Self("fr-CA")

    /// German
    public static let german = Self("de")

    /// Spanish
    public static let spanish = Self("es")

    /// Italian
    public static let italian = Self("it")

    /// Japanese
    public static let japanese = Self("ja")

    /// Chinese (Simplified)
    public static let chineseSimplified = Self("zh-Hans")

    /// Chinese (Traditional)
    public static let chineseTraditional = Self("zh-Hant")

    /// Portuguese
    public static let portuguese = Self("pt")

    /// Dutch
    public static let dutch = Self("nl")

    /// Russian
    public static let russian = Self("ru")
}
