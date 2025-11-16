// HTTP.CacheControl.Tests.swift
// swift-rfc-9110

import Testing
import Foundation
@testable import RFC_9110

@Suite("HTTP.CacheControl Tests")
struct HTTPCacheControlTests {

    @Test("Empty cache control")
    func emptyCacheControl() async throws {
        let cc = HTTP.CacheControl()

        #expect(cc.headerValue == "")
    }

    @Test("no-cache directive")
    func noCacheDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.noCache = true

        #expect(cc.headerValue == "no-cache")
    }

    @Test("no-store directive")
    func noStoreDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.noStore = true

        #expect(cc.headerValue == "no-store")
    }

    @Test("max-age directive")
    func maxAgeDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.maxAge = 3600

        #expect(cc.headerValue == "max-age=3600")
    }

    @Test("public directive")
    func publicDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.isPublic = true

        #expect(cc.headerValue == "public")
    }

    @Test("private directive")
    func privateDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.isPrivate = true

        #expect(cc.headerValue == "private")
    }

    @Test("must-revalidate directive")
    func mustRevalidateDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.mustRevalidate = true

        #expect(cc.headerValue == "must-revalidate")
    }

    @Test("immutable directive")
    func immutableDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.immutable = true

        #expect(cc.headerValue == "immutable")
    }

    @Test("Multiple directives")
    func multipleDirectives() async throws {
        var cc = HTTP.CacheControl()
        cc.isPublic = true
        cc.maxAge = 3600
        cc.mustRevalidate = true

        let headerValue = cc.headerValue

        #expect(headerValue.contains("public"))
        #expect(headerValue.contains("max-age=3600"))
        #expect(headerValue.contains("must-revalidate"))
    }

    @Test("s-maxage directive")
    func sharedMaxAgeDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.sharedMaxAge = 7200

        #expect(cc.headerValue == "s-maxage=7200")
    }

    @Test("stale-while-revalidate directive")
    func staleWhileRevalidateDirective() async throws {
        var cc = HTTP.CacheControl()
        cc.staleWhileRevalidate = 86400

        #expect(cc.headerValue == "stale-while-revalidate=86400")
    }

    @Test("Parse no-cache")
    func parseNoCache() async throws {
        let cc = HTTP.CacheControl.parse("no-cache")

        #expect(cc.noCache == true)
    }

    @Test("Parse max-age")
    func parseMaxAge() async throws {
        let cc = HTTP.CacheControl.parse("max-age=3600")

        #expect(cc.maxAge == 3600)
    }

    @Test("Parse public")
    func parsePublic() async throws {
        let cc = HTTP.CacheControl.parse("public")

        #expect(cc.isPublic == true)
    }

    @Test("Parse multiple directives")
    func parseMultipleDirectives() async throws {
        let cc = HTTP.CacheControl.parse("public, max-age=3600, must-revalidate")

        #expect(cc.isPublic == true)
        #expect(cc.maxAge == 3600)
        #expect(cc.mustRevalidate == true)
    }

    @Test("Parse with whitespace")
    func parseWithWhitespace() async throws {
        let cc = HTTP.CacheControl.parse(" public ,  max-age = 3600  ")

        #expect(cc.isPublic == true)
        #expect(cc.maxAge == 3600)
    }

    @Test("Parse max-stale without value")
    func parseMaxStaleWithoutValue() async throws {
        let cc = HTTP.CacheControl.parse("max-stale")

        #expect(cc.maxStale == .infinity)
    }

    @Test("Parse max-stale with value")
    func parseMaxStaleWithValue() async throws {
        let cc = HTTP.CacheControl.parse("max-stale=600")

        #expect(cc.maxStale == 600)
    }

    @Test("Parse unknown directive")
    func parseUnknownDirective() async throws {
        let cc = HTTP.CacheControl.parse("public, unknown-directive, max-age=3600")

        #expect(cc.isPublic == true)
        #expect(cc.maxAge == 3600)
        // Unknown directive should be ignored
    }

    @Test("Round trip - format and parse")
    func roundTrip() async throws {
        var original = HTTP.CacheControl()
        original.isPublic = true
        original.maxAge = 3600
        original.mustRevalidate = true

        let headerValue = original.headerValue
        let parsed = HTTP.CacheControl.parse(headerValue)

        #expect(parsed.isPublic == original.isPublic)
        #expect(parsed.maxAge == original.maxAge)
        #expect(parsed.mustRevalidate == original.mustRevalidate)
    }

    @Test("Equality")
    func equality() async throws {
        var cc1 = HTTP.CacheControl()
        cc1.maxAge = 3600
        cc1.isPublic = true

        var cc2 = HTTP.CacheControl()
        cc2.maxAge = 3600
        cc2.isPublic = true

        var cc3 = HTTP.CacheControl()
        cc3.maxAge = 7200

        #expect(cc1 == cc2)
        #expect(cc1 != cc3)
    }

    @Test("Hashable")
    func hashable() async throws {
        var set: Set<HTTP.CacheControl> = []

        var cc1 = HTTP.CacheControl()
        cc1.maxAge = 3600

        var cc2 = HTTP.CacheControl()
        cc2.maxAge = 3600

        var cc3 = HTTP.CacheControl()
        cc3.maxAge = 7200

        set.insert(cc1)
        set.insert(cc2) // Duplicate
        set.insert(cc3)

        #expect(set.count == 2)
    }

    @Test("Codable")
    func codable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        var cc = HTTP.CacheControl()
        cc.isPublic = true
        cc.maxAge = 3600

        let encoded = try encoder.encode(cc)
        let decoded = try decoder.decode(HTTP.CacheControl.self, from: encoded)

        #expect(decoded == cc)
    }

    @Test("Description")
    func description() async throws {
        var cc = HTTP.CacheControl()
        cc.isPublic = true
        cc.maxAge = 3600

        let description = cc.description

        #expect(description.contains("public"))
        #expect(description.contains("max-age=3600"))
    }

    @Test("Complex caching scenario")
    func complexCachingScenario() async throws {
        var cc = HTTP.CacheControl()
        cc.isPublic = true
        cc.maxAge = 86400        // 1 day
        cc.sharedMaxAge = 604800 // 1 week
        cc.mustRevalidate = true
        cc.immutable = true

        let headerValue = cc.headerValue

        #expect(headerValue.contains("public"))
        #expect(headerValue.contains("max-age=86400"))
        #expect(headerValue.contains("s-maxage=604800"))
        #expect(headerValue.contains("must-revalidate"))
        #expect(headerValue.contains("immutable"))

        // Round trip
        let parsed = HTTP.CacheControl.parse(headerValue)
        #expect(parsed == cc)
    }
}
