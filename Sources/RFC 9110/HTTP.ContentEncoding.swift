// HTTP.ContentEncoding.swift
// swift-rfc-9110
//
// RFC 9110 Section 8.4: Content-Encoding
// https://www.rfc-editor.org/rfc/rfc9110.html#section-8.4
//
// Content coding values indicate an encoding transformation applied to the representation

import INCITS_4_1986
import Standards

extension RFC_9110 {
    /// HTTP Content Encoding (RFC 9110 Section 8.4)
    ///
    /// Content-Encoding indicates what encoding transformations have been
    /// applied to the representation (and thus what decoding mechanisms must
    /// be applied to obtain the original representation).
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let gzip = HTTP.ContentEncoding.gzip
    /// let br = HTTP.ContentEncoding.brotli
    /// let custom = HTTP.ContentEncoding("custom-encoding")
    ///
    /// // Header value
    /// print(gzip.value) // "gzip"
    ///
    /// // Parsing
    /// let parsed = HTTP.ContentEncoding.parse("gzip, deflate")
    /// // [.gzip, .deflate]
    /// ```
    ///
    /// ## RFC 9110 Reference
    ///
    /// From RFC 9110 Section 8.4:
    /// ```
    /// Content-Encoding = #content-coding
    /// content-coding   = token
    /// ```
    ///
    /// ## Standard Encodings
    ///
    /// - `gzip`: GZIP compression (RFC 1952)
    /// - `compress`: UNIX compress (obsolete)
    /// - `deflate`: DEFLATE compression (RFC 1951)
    /// - `br`: Brotli compression (RFC 7932)
    /// - `identity`: No encoding (implied if absent)
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 8.4: Content-Encoding](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.4)
    /// - [RFC 9110 Section 8.4.1: Content Codings](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.4.1)
    public struct ContentEncoding: Sendable, Equatable, Hashable, Codable {
        /// The encoding name (case-insensitive token)
        public let value: String

        /// Creates a content encoding
        ///
        /// - Parameter value: The encoding name
        public init(_ value: String) {
            self.value = value.lowercased()
        }

        /// Parses content encodings from a header value
        ///
        /// Supports comma-separated list of encodings.
        ///
        /// - Parameter headerValue: The Content-Encoding header value
        /// - Returns: Array of content encodings
        ///
        /// ## Example
        ///
        /// ```swift
        /// ContentEncoding.parse("gzip")
        /// // [.gzip]
        ///
        /// ContentEncoding.parse("gzip, deflate")
        /// // [.gzip, .deflate]
        ///
        /// ContentEncoding.parse("br")
        /// // [.brotli]
        /// ```
        public static func parse(_ headerValue: String) -> [ContentEncoding] {
            headerValue
                .split(separator: ",")
                .map { $0.trimming(.ascii.whitespaces) }
                .filter { !$0.isEmpty }
                .map { ContentEncoding($0) }
        }

        /// Formats multiple encodings as a header value
        ///
        /// - Parameter encodings: The encodings to format
        /// - Returns: Comma-separated encoding list
        ///
        /// ## Example
        ///
        /// ```swift
        /// ContentEncoding.formatHeader([.gzip, .deflate])
        /// // "gzip, deflate"
        /// ```
        public static func formatHeader(_ encodings: [ContentEncoding]) -> String {
            encodings.map(\.value).joined(separator: ", ")
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.ContentEncoding: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - Codable

extension RFC_9110.ContentEncoding {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_9110.ContentEncoding: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - Standard Encodings

extension RFC_9110.ContentEncoding {
    /// GZIP compression (RFC 1952)
    ///
    /// Format using LZ77 and Huffman coding.
    /// Widely supported and recommended for general use.
    public static let gzip = Self("gzip")

    /// DEFLATE compression (RFC 1951)
    ///
    /// Uses the zlib structure with deflate compression.
    public static let deflate = Self("deflate")

    /// UNIX compress (obsolete)
    ///
    /// Legacy LZW algorithm. Not recommended for new implementations.
    public static let compress = Self("compress")

    /// Brotli compression (RFC 7932)
    ///
    /// Modern compression algorithm offering better compression than gzip.
    /// Supported by most modern browsers.
    public static let brotli = Self("br")

    /// Identity encoding (no transformation)
    ///
    /// Explicitly indicates no encoding. Normally this is implied by absence.
    public static let identity = Self("identity")
}
