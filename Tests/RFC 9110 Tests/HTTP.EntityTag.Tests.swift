// HTTP.EntityTag.Tests.swift
// swift-rfc-9110

import Testing
@testable import RFC_9110

@Suite("HTTP.EntityTag Tests")
struct HTTPEntityTagTests {

    @Test("Strong ETag creation")
    func strongETagCreation() async throws {
        let etag = HTTP.EntityTag.strong("686897696a7c876b7e")

        #expect(etag.value == "686897696a7c876b7e")
        #expect(etag.isWeak == false)
    }

    @Test("Weak ETag creation")
    func weakETagCreation() async throws {
        let etag = HTTP.EntityTag.weak("686897696a7c876b7e")

        #expect(etag.value == "686897696a7c876b7e")
        #expect(etag.isWeak == true)
    }

    @Test("Strong ETag header value")
    func strongETagHeaderValue() async throws {
        let etag = HTTP.EntityTag.strong("abc123")

        #expect(etag.headerValue == "\"abc123\"")
    }

    @Test("Weak ETag header value")
    func weakETagHeaderValue() async throws {
        let etag = HTTP.EntityTag.weak("abc123")

        #expect(etag.headerValue == "W/\"abc123\"")
    }

    @Test("Parse strong ETag")
    func parseStrongETag() async throws {
        let parsed = HTTP.EntityTag.parse("\"abc123\"")

        #expect(parsed?.value == "abc123")
        #expect(parsed?.isWeak == false)
    }

    @Test("Parse weak ETag")
    func parseWeakETag() async throws {
        let parsed = HTTP.EntityTag.parse("W/\"abc123\"")

        #expect(parsed?.value == "abc123")
        #expect(parsed?.isWeak == true)
    }

    @Test("Parse invalid ETag")
    func parseInvalidETag() async throws {
        #expect(HTTP.EntityTag.parse("invalid") == nil)
        #expect(HTTP.EntityTag.parse("") == nil)
        #expect(HTTP.EntityTag.parse("abc123") == nil)
    }

    @Test("Strong comparison - both strong and equal")
    func strongComparisonBothStrongEqual() async throws {
        let etag1 = HTTP.EntityTag.strong("abc")
        let etag2 = HTTP.EntityTag.strong("abc")

        #expect(HTTP.EntityTag.strongCompare(etag1, etag2) == true)
    }

    @Test("Strong comparison - both strong but different")
    func strongComparisonBothStrongDifferent() async throws {
        let etag1 = HTTP.EntityTag.strong("abc")
        let etag2 = HTTP.EntityTag.strong("xyz")

        #expect(HTTP.EntityTag.strongCompare(etag1, etag2) == false)
    }

    @Test("Strong comparison - one weak")
    func strongComparisonOneWeak() async throws {
        let strong = HTTP.EntityTag.strong("abc")
        let weak = HTTP.EntityTag.weak("abc")

        #expect(HTTP.EntityTag.strongCompare(strong, weak) == false)
        #expect(HTTP.EntityTag.strongCompare(weak, strong) == false)
    }

    @Test("Strong comparison - both weak")
    func strongComparisonBothWeak() async throws {
        let weak1 = HTTP.EntityTag.weak("abc")
        let weak2 = HTTP.EntityTag.weak("abc")

        #expect(HTTP.EntityTag.strongCompare(weak1, weak2) == false)
    }

    @Test("Weak comparison - values match")
    func weakComparisonValuesMatch() async throws {
        let strong = HTTP.EntityTag.strong("abc")
        let weak = HTTP.EntityTag.weak("abc")

        #expect(HTTP.EntityTag.weakCompare(strong, weak) == true)
        #expect(HTTP.EntityTag.weakCompare(weak, strong) == true)
    }

    @Test("Weak comparison - values differ")
    func weakComparisonValuesDiffer() async throws {
        let etag1 = HTTP.EntityTag.strong("abc")
        let etag2 = HTTP.EntityTag.weak("xyz")

        #expect(HTTP.EntityTag.weakCompare(etag1, etag2) == false)
    }

    @Test("Equality")
    func equality() async throws {
        let strong1 = HTTP.EntityTag.strong("abc")
        let strong2 = HTTP.EntityTag.strong("abc")
        let weak1 = HTTP.EntityTag.weak("abc")
        let weak2 = HTTP.EntityTag.weak("abc")
        let different = HTTP.EntityTag.strong("xyz")

        #expect(strong1 == strong2)
        #expect(weak1 == weak2)
        #expect(strong1 != weak1) // Different isWeak
        #expect(strong1 != different)
    }

    @Test("Hashable")
    func hashable() async throws {
        var set: Set<HTTP.EntityTag> = []
        set.insert(.strong("abc"))
        set.insert(.strong("abc")) // Duplicate
        set.insert(.weak("abc"))   // Different (isWeak differs)
        set.insert(.strong("xyz"))

        #expect(set.count == 3)
    }

    @Test("Codable - strong")
    func codableStrong() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let etag = HTTP.EntityTag.strong("abc123")
        let encoded = try encoder.encode(etag)
        let decoded = try decoder.decode(HTTP.EntityTag.self, from: encoded)

        #expect(decoded == etag)
    }

    @Test("Codable - weak")
    func codableWeak() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let etag = HTTP.EntityTag.weak("abc123")
        let encoded = try encoder.encode(etag)
        let decoded = try decoder.decode(HTTP.EntityTag.self, from: encoded)

        #expect(decoded == etag)
    }

    @Test("Description")
    func description() async throws {
        let strong = HTTP.EntityTag.strong("abc")
        #expect(strong.description == "\"abc\"")

        let weak = HTTP.EntityTag.weak("abc")
        #expect(weak.description == "W/\"abc\"")
    }

    @Test("String literal")
    func stringLiteral() async throws {
        let strong: HTTP.EntityTag = "\"abc\""
        #expect(strong.value == "abc")
        #expect(strong.isWeak == false)

        let weak: HTTP.EntityTag = "W/\"abc\""
        #expect(weak.value == "abc")
        #expect(weak.isWeak == true)
    }
}
