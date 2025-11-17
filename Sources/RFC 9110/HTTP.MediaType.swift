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
    public struct MediaType: Sendable, Equatable, Hashable, Codable {
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

// MARK: - LosslessStringConvertible

extension RFC_9110.MediaType: LosslessStringConvertible {
    /// Creates a media type from a string description
    ///
    /// - Parameter description: The media type string (e.g., "text/html", "application/json;charset=utf-8")
    /// - Returns: A media type instance, or nil if parsing fails
    ///
    /// # Example
    ///
    /// ```swift
    /// let mediaType = HTTP.MediaType("text/html; charset=utf-8")
    /// let str = String(mediaType)  // "text/html; charset=utf-8" - perfect round-trip
    /// ```
    public init?(_ description: String) {
        guard let parsed = Self.parse(description) else { return nil }
        self = parsed
    }
}

// MARK: - Codable

extension RFC_9110.MediaType {
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

// MARK: - Common Media Types

extension RFC_9110.MediaType {
    // MARK: - Text Types

    /// text/plain
    public static let plain = RFC_9110.MediaType("text", "plain")

    /// text/html
    public static let html = RFC_9110.MediaType("text", "html")

    /// text/css
    public static let css = RFC_9110.MediaType("text", "css")

    /// text/csv
    public static let csv = RFC_9110.MediaType("text", "csv")

    /// text/xml
    public static let xml = RFC_9110.MediaType("text", "xml")

    // MARK: - Application Types

    /// application/json
    public static let json = RFC_9110.MediaType("application", "json")

    /// application/xml
    public static let xml_app = RFC_9110.MediaType("application", "xml")

    /// application/pdf
    public static let pdf = RFC_9110.MediaType("application", "pdf")

    /// application/zip
    public static let zip = RFC_9110.MediaType("application", "zip")

    /// application/gzip
    public static let gzip = RFC_9110.MediaType("application", "gzip")

    /// application/octet-stream
    public static let octetStream = RFC_9110.MediaType("application", "octet-stream")

    /// application/x-www-form-urlencoded
    public static let formUrlEncoded = RFC_9110.MediaType("application", "x-www-form-urlencoded")

    /// multipart/form-data
    public static let formData = RFC_9110.MediaType("multipart", "form-data")

    // MARK: - Image Types

    /// image/jpeg
    public static let jpeg = RFC_9110.MediaType("image", "jpeg")

    /// image/png
    public static let png = RFC_9110.MediaType("image", "png")

    /// image/gif
    public static let gif = RFC_9110.MediaType("image", "gif")

    /// image/svg+xml
    public static let svg = RFC_9110.MediaType("image", "svg+xml")

    /// image/webp
    public static let webp = RFC_9110.MediaType("image", "webp")

    /// image/x-icon
    public static let ico = RFC_9110.MediaType("image", "x-icon")

    // MARK: - Audio Types

    /// audio/mpeg
    public static let mp3 = RFC_9110.MediaType("audio", "mpeg")

    /// audio/wav
    public static let wav = RFC_9110.MediaType("audio", "wav")

    /// audio/ogg
    public static let ogg_audio = RFC_9110.MediaType("audio", "ogg")

    // MARK: - Video Types

    /// video/mp4
    public static let mp4 = RFC_9110.MediaType("video", "mp4")

    /// video/webm
    public static let webm = RFC_9110.MediaType("video", "webm")

    /// video/ogg
    public static let ogg_video = RFC_9110.MediaType("video", "ogg")

    // MARK: - Font Types

    /// font/woff
    public static let woff = RFC_9110.MediaType("font", "woff")

    /// font/woff2
    public static let woff2 = RFC_9110.MediaType("font", "woff2")

    /// font/ttf
    public static let ttf = RFC_9110.MediaType("font", "ttf")

    /// font/otf
    public static let otf = RFC_9110.MediaType("font", "otf")
}
