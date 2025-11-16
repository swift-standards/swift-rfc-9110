// HTTP.CacheControl.swift
// swift-rfc-9110
//
// RFC 9110 Section 5.2: Cache-Control
// https://www.rfc-editor.org/rfc/rfc9110.html#section-5.2
//
// Cache directives for request and response caching behavior

import Foundation

extension RFC_9110 {
    /// HTTP Cache-Control directives (RFC 9110 Section 5.2)
    ///
    /// The Cache-Control header field is used to specify directives for
    /// caching mechanisms in both requests and responses.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// // Response caching
    /// var cacheControl = HTTP.CacheControl()
    /// cacheControl.maxAge = 3600
    /// cacheControl.isPublic = true
    /// print(cacheControl.headerValue)
    /// // "public, max-age=3600"
    ///
    /// // Request caching
    /// var requestCache = HTTP.CacheControl()
    /// requestCache.noCache = true
    /// requestCache.maxAge = 0
    /// // "no-cache, max-age=0"
    ///
    /// // Parsing
    /// let parsed = HTTP.CacheControl.parse("public, max-age=3600, must-revalidate")
    /// // parsed.isPublic == true
    /// // parsed.maxAge == 3600
    /// // parsed.mustRevalidate == true
    /// ```
    ///
    /// ## RFC 9110 Reference
    ///
    /// From RFC 9110 Section 5.2:
    /// ```
    /// Cache-Control   = #cache-directive
    /// cache-directive = token [ "=" ( token / quoted-string ) ]
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 5.2: Cache-Control](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.2)
    /// - [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111.html)
    public struct CacheControl: Sendable, Equatable, Hashable {

        // MARK: - Request Directives

        /// max-age: Maximum age (in seconds) of cached response
        ///
        /// Indicates that the client is willing to accept a response whose age
        /// is no greater than the specified number of seconds.
        public var maxAge: TimeInterval?

        /// max-stale: Accept stale response (with optional max staleness in seconds)
        ///
        /// Indicates that the client is willing to accept a response that has
        /// exceeded its freshness lifetime.
        public var maxStale: TimeInterval?

        /// min-fresh: Require response to be fresh for at least n seconds
        ///
        /// Indicates that the client wants a response that will still be fresh
        /// for at least the specified number of seconds.
        public var minFresh: TimeInterval?

        /// no-cache: Must revalidate with origin server before using cached copy
        ///
        /// The cache must not use stored response without successful validation
        /// with the origin server.
        public var noCache: Bool = false

        /// no-store: Do not store this request or response
        ///
        /// Caches must not store any part of the request or response.
        public var noStore: Bool = false

        /// no-transform: Do not transform the response (e.g., image conversion)
        ///
        /// Intermediaries must not transform the representation.
        public var noTransform: Bool = false

        /// only-if-cached: Only return cached response, don't contact origin
        ///
        /// The client only wishes to obtain a cached response.
        public var onlyIfCached: Bool = false

        // MARK: - Response Directives

        /// public: May be cached by any cache
        ///
        /// Indicates that the response may be stored by any cache.
        public var isPublic: Bool = false

        /// private: May only be cached by browser cache, not shared caches
        ///
        /// Indicates that the response is intended for a single user.
        public var isPrivate: Bool = false

        /// must-revalidate: Must revalidate stale responses with origin server
        ///
        /// The cache must revalidate the response with the origin server
        /// once it becomes stale.
        public var mustRevalidate: Bool = false

        /// proxy-revalidate: Like must-revalidate, but only for shared caches
        ///
        /// Similar to must-revalidate, but only applies to shared caches.
        public var proxyRevalidate: Bool = false

        /// s-maxage: Maximum age for shared caches (overrides max-age)
        ///
        /// Indicates that in shared caches, the maximum age specified by this
        /// directive overrides the max-age directive.
        public var sharedMaxAge: TimeInterval?

        /// immutable: Response body will not change over time
        ///
        /// Indicates that the response body will not change.
        /// Clients can avoid revalidation for the duration of max-age.
        public var immutable: Bool = false

        /// stale-while-revalidate: Serve stale content while revalidating
        ///
        /// Indicates that caches can serve stale responses while revalidating
        /// in the background.
        public var staleWhileRevalidate: TimeInterval?

        /// stale-if-error: Serve stale content if origin returns error
        ///
        /// Indicates that caches can serve stale responses when an error
        /// is encountered.
        public var staleIfError: TimeInterval?

        // MARK: - Initialization

        /// Creates an empty Cache-Control directive set
        public init() {}

        // MARK: - Parsing

        /// Parses Cache-Control directives from a header value
        ///
        /// - Parameter headerValue: The Cache-Control header value
        /// - Returns: A CacheControl with parsed directives
        ///
        /// ## Example
        ///
        /// ```swift
        /// let cc = CacheControl.parse("public, max-age=3600, must-revalidate")
        /// // cc.isPublic == true
        /// // cc.maxAge == 3600
        /// // cc.mustRevalidate == true
        /// ```
        public static func parse(_ headerValue: String) -> CacheControl {
            var cacheControl = CacheControl()

            let directives = headerValue.components(separatedBy: ",")

            for directive in directives {
                let trimmed = directive.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.components(separatedBy: "=")
                let name = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
                let value = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil

                switch name {
                // Request & Response directives
                case "max-age":
                    if let value = value, let seconds = TimeInterval(value) {
                        cacheControl.maxAge = seconds
                    }
                case "no-cache":
                    cacheControl.noCache = true
                case "no-store":
                    cacheControl.noStore = true
                case "no-transform":
                    cacheControl.noTransform = true

                // Request-only directives
                case "max-stale":
                    if let value = value, let seconds = TimeInterval(value) {
                        cacheControl.maxStale = seconds
                    } else {
                        cacheControl.maxStale = .infinity
                    }
                case "min-fresh":
                    if let value = value, let seconds = TimeInterval(value) {
                        cacheControl.minFresh = seconds
                    }
                case "only-if-cached":
                    cacheControl.onlyIfCached = true

                // Response-only directives
                case "public":
                    cacheControl.isPublic = true
                case "private":
                    cacheControl.isPrivate = true
                case "must-revalidate":
                    cacheControl.mustRevalidate = true
                case "proxy-revalidate":
                    cacheControl.proxyRevalidate = true
                case "s-maxage":
                    if let value = value, let seconds = TimeInterval(value) {
                        cacheControl.sharedMaxAge = seconds
                    }
                case "immutable":
                    cacheControl.immutable = true
                case "stale-while-revalidate":
                    if let value = value, let seconds = TimeInterval(value) {
                        cacheControl.staleWhileRevalidate = seconds
                    }
                case "stale-if-error":
                    if let value = value, let seconds = TimeInterval(value) {
                        cacheControl.staleIfError = seconds
                    }
                default:
                    break // Unknown directive - ignore per RFC 9110
                }
            }

            return cacheControl
        }

        // MARK: - Header Value

        /// Formats the directives as a Cache-Control header value
        ///
        /// - Returns: The formatted header value
        ///
        /// ## Example
        ///
        /// ```swift
        /// var cc = CacheControl()
        /// cc.isPublic = true
        /// cc.maxAge = 3600
        /// print(cc.headerValue)
        /// // "public, max-age=3600"
        /// ```
        public var headerValue: String {
            var directives: [String] = []

            // Boolean directives
            if noCache { directives.append("no-cache") }
            if noStore { directives.append("no-store") }
            if noTransform { directives.append("no-transform") }
            if onlyIfCached { directives.append("only-if-cached") }
            if isPublic { directives.append("public") }
            if isPrivate { directives.append("private") }
            if mustRevalidate { directives.append("must-revalidate") }
            if proxyRevalidate { directives.append("proxy-revalidate") }
            if immutable { directives.append("immutable") }

            // Value directives
            if let maxAge = maxAge {
                directives.append("max-age=\(Int(maxAge))")
            }
            if let maxStale = maxStale {
                if maxStale.isInfinite {
                    directives.append("max-stale")
                } else {
                    directives.append("max-stale=\(Int(maxStale))")
                }
            }
            if let minFresh = minFresh {
                directives.append("min-fresh=\(Int(minFresh))")
            }
            if let sharedMaxAge = sharedMaxAge {
                directives.append("s-maxage=\(Int(sharedMaxAge))")
            }
            if let staleWhileRevalidate = staleWhileRevalidate {
                directives.append("stale-while-revalidate=\(Int(staleWhileRevalidate))")
            }
            if let staleIfError = staleIfError {
                directives.append("stale-if-error=\(Int(staleIfError))")
            }

            return directives.joined(separator: ", ")
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.CacheControl: CustomStringConvertible {
    public var description: String {
        headerValue
    }
}

// MARK: - Codable

extension RFC_9110.CacheControl: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = RFC_9110.CacheControl.parse(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(headerValue)
    }
}
