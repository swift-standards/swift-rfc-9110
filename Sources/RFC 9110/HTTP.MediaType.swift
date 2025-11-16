// HTTP.MediaType.swift
// swift-rfc-9110
//
// RFC 9110 Section 8.3: Media Type
// RFC 9110 Section 12.5.1: Accept Header
// https://www.rfc-editor.org/rfc/rfc9110.html#section-8.3
//
// Media types for HTTP content negotiation

import Foundation

extension RFC_9110 {
    /// HTTP Media Type (RFC 9110 Section 8.3)
    ///
    /// A media type is a two-part identifier for file formats and format contents
    /// transmitted on the Internet. It consists of a type and a subtype, along
    /// with optional parameters.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let json = HTTP.MediaType("application", "json")
    /// let html = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])
    /// ```
    ///
    /// ## RFC 9110 Reference
    ///
    /// From RFC 9110 Section 8.3.1:
    /// ```
    /// media-type = type "/" subtype parameters
    /// type       = token
    /// subtype    = token
    /// parameters = *( OWS ";" OWS [ parameter ] )
    /// parameter  = parameter-name "=" parameter-value
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 8.3: Content-Type](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.3)
    /// - [RFC 9110 Section 8.3.1: Media Type](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.3.1)
    public struct MediaType: Sendable, Equatable, Hashable {
        /// The top-level media type
        ///
        /// Examples: "text", "application", "image", "audio", "video"
        public let type: String

        /// The media subtype
        ///
        /// Examples: "html", "json", "xml", "plain"
        public let subtype: String

        /// Optional parameters
        ///
        /// Common parameters include "charset", "boundary", "q" (quality factor)
        public var parameters: [String: String]

        /// Creates a media type
        ///
        /// - Parameters:
        ///   - type: The top-level type
        ///   - subtype: The subtype
        ///   - parameters: Optional parameters (defaults to empty)
        public init(_ type: String, _ subtype: String, parameters: [String: String] = [:]) {
            self.type = type.lowercased()
            self.subtype = subtype.lowercased()
            self.parameters = parameters
        }

        /// The complete media type string
        ///
        /// Format: "type/subtype" or "type/subtype; param=value"
        public var value: String {
            var result = "\(type)/\(subtype)"

            if !parameters.isEmpty {
                let params = parameters
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: "; ")
                result += "; \(params)"
            }

            return result
        }

        /// Parses a media type string
        ///
        /// - Parameter string: The media type string to parse
        /// - Returns: A MediaType if parsing succeeds, nil otherwise
        ///
        /// ## Example
        ///
        /// ```swift
        /// let mt = HTTP.MediaType.parse("text/html; charset=utf-8")
        /// // mt?.type == "text"
        /// // mt?.subtype == "html"
        /// // mt?.parameters["charset"] == "utf-8"
        /// ```
        public static func parse(_ string: String) -> MediaType? {
            let trimmed = string.trimmingCharacters(in: .whitespaces)

            // Split on first semicolon to separate type/subtype from parameters
            let components = trimmed.components(separatedBy: ";")
            guard let firstComponent = components.first else { return nil }

            // Parse type/subtype
            let typeComponents = firstComponent.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: "/")
            guard typeComponents.count == 2,
                  !typeComponents[0].isEmpty,
                  !typeComponents[1].isEmpty else {
                return nil
            }

            let type = typeComponents[0].trimmingCharacters(in: .whitespaces)
            let subtype = typeComponents[1].trimmingCharacters(in: .whitespaces)

            // Parse parameters
            var parameters: [String: String] = [:]
            if components.count > 1 {
                for param in components.dropFirst() {
                    let paramParts = param.components(separatedBy: "=")
                    guard paramParts.count == 2 else { continue }

                    let key = paramParts[0].trimmingCharacters(in: .whitespaces).lowercased()
                    var value = paramParts[1].trimmingCharacters(in: .whitespaces)

                    // Remove quotes if present
                    if value.hasPrefix("\"") && value.hasSuffix("\"") {
                        value = String(value.dropFirst().dropLast())
                    }

                    parameters[key] = value
                }
            }

            return MediaType(type, subtype, parameters: parameters)
        }

        // MARK: - Common Media Types

        // Text types
        public static let plain = MediaType("text", "plain")
        public static let html = MediaType("text", "html")
        public static let css = MediaType("text", "css")
        public static let csv = MediaType("text", "csv")
        public static let xml = MediaType("text", "xml")

        // Application types
        public static let json = MediaType("application", "json")
        public static let xml_app = MediaType("application", "xml")
        public static let pdf = MediaType("application", "pdf")
        public static let zip = MediaType("application", "zip")
        public static let gzip = MediaType("application", "gzip")
        public static let octetStream = MediaType("application", "octet-stream")
        public static let formUrlEncoded = MediaType("application", "x-www-form-urlencoded")
        public static let formData = MediaType("multipart", "form-data")

        // Image types
        public static let jpeg = MediaType("image", "jpeg")
        public static let png = MediaType("image", "png")
        public static let gif = MediaType("image", "gif")
        public static let svg = MediaType("image", "svg+xml")
        public static let webp = MediaType("image", "webp")
        public static let ico = MediaType("image", "x-icon")

        // Audio types
        public static let mp3 = MediaType("audio", "mpeg")
        public static let wav = MediaType("audio", "wav")
        public static let ogg_audio = MediaType("audio", "ogg")

        // Video types
        public static let mp4 = MediaType("video", "mp4")
        public static let webm = MediaType("video", "webm")
        public static let ogg_video = MediaType("video", "ogg")

        // Font types
        public static let woff = MediaType("font", "woff")
        public static let woff2 = MediaType("font", "woff2")
        public static let ttf = MediaType("font", "ttf")
        public static let otf = MediaType("font", "otf")

        // MARK: - Matching

        /// Returns true if this media type matches the given pattern
        ///
        /// Supports wildcards: "*/*" matches all, "text/*" matches all text types
        ///
        /// - Parameter pattern: The pattern to match against
        /// - Returns: True if this media type matches the pattern
        ///
        /// ## Example
        ///
        /// ```swift
        /// let json = HTTP.MediaType.json
        /// json.matches("*/*")              // true
        /// json.matches("application/*")    // true
        /// json.matches("application/json") // true
        /// json.matches("text/*")           // false
        /// ```
        public func matches(_ pattern: String) -> Bool {
            guard let patternType = MediaType.parse(pattern) else {
                return false
            }

            return matches(patternType)
        }

        /// Returns true if this media type matches the given media type pattern
        ///
        /// - Parameter other: The media type pattern to match against
        /// - Returns: True if this media type matches the pattern
        public func matches(_ other: MediaType) -> Bool {
            // */* matches everything
            if other.type == "*" && other.subtype == "*" {
                return true
            }

            // type/* matches all subtypes of type
            if other.type == type && other.subtype == "*" {
                return true
            }

            // Exact match (ignoring parameters)
            return type == other.type && subtype == other.subtype
        }

        // MARK: - Equatable (based on type and subtype, ignoring parameters)

        public static func == (lhs: MediaType, rhs: MediaType) -> Bool {
            lhs.type == rhs.type && lhs.subtype == rhs.subtype
        }

        // MARK: - Hashable

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(subtype)
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.MediaType: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - Codable

extension RFC_9110.MediaType: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let mediaType = RFC_9110.MediaType.parse(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid media type: \(string)"
            )
        }

        self = mediaType
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - ExpressibleByStringLiteral

extension RFC_9110.MediaType: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        if let parsed = RFC_9110.MediaType.parse(value) {
            self = parsed
        } else {
            // Fallback to a default
            self = RFC_9110.MediaType("application", "octet-stream")
        }
    }
}
