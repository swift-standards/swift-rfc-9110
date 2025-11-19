// HTTP.EntityTag.Tests.swift
// swift-rfc-9110

import Testing
@testable import RFC_9110

@Suite
struct `HTTP.EntityTag Tests` {

    @Test
    func `Strong ETag creation`() async throws {
        let etag = HTTP.EntityTag.strong("686897696a7c876b7e")

        #expect(etag.value == "686897696a7c876b7e")
        #expect(etag.isWeak == false)
    }

    @Test
    func `Weak ETag creation`() async throws {
        let etag = HTTP.EntityTag.weak("686897696a7c876b7e")

        #expect(etag.value == "686897696a7c876b7e")
        #expect(etag.isWeak == true)
    }

    @Test
    func `Strong ETag header value`() async throws {
        let etag = HTTP.EntityTag.strong("abc123")

        #expect(etag.headerValue == "\"abc123\"")
    }

    @Test
    func `Weak ETag header value`() async throws {
        let etag = HTTP.EntityTag.weak("abc123")

        #expect(etag.headerValue == "W/\"abc123\"")
    }

    @Test
    func `Parse strong ETag`() async throws {
        let parsed = HTTP.EntityTag.parse("\"abc123\"")

        #expect(parsed?.value == "abc123")
        #expect(parsed?.isWeak == false)
    }

    @Test
    func `Parse weak ETag`() async throws {
        let parsed = HTTP.EntityTag.parse("W/\"abc123\"")

        #expect(parsed?.value == "abc123")
        #expect(parsed?.isWeak == true)
    }

    @Test
    func `Parse invalid ETag`() async throws {
        #expect(HTTP.EntityTag.parse("invalid") == nil)
        #expect(HTTP.EntityTag.parse("") == nil)
        #expect(HTTP.EntityTag.parse("abc123") == nil)
    }

    @Test
    func `Strong comparison - both strong and equal`() async throws {
        let etag1 = HTTP.EntityTag.strong("abc")
        let etag2 = HTTP.EntityTag.strong("abc")

        #expect(HTTP.EntityTag.strongCompare(etag1, etag2) == true)
    }

    @Test
    func `Strong comparison - both strong but different`() async throws {
        let etag1 = HTTP.EntityTag.strong("abc")
        let etag2 = HTTP.EntityTag.strong("xyz")

        #expect(HTTP.EntityTag.strongCompare(etag1, etag2) == false)
    }

    @Test
    func `Strong comparison - one weak`() async throws {
        let strong = HTTP.EntityTag.strong("abc")
        let weak = HTTP.EntityTag.weak("abc")

        #expect(HTTP.EntityTag.strongCompare(strong, weak) == false)
        #expect(HTTP.EntityTag.strongCompare(weak, strong) == false)
    }

    @Test
    func `Strong comparison - both weak`() async throws {
        let weak1 = HTTP.EntityTag.weak("abc")
        let weak2 = HTTP.EntityTag.weak("abc")

        #expect(HTTP.EntityTag.strongCompare(weak1, weak2) == false)
    }

    @Test
    func `Weak comparison - values match`() async throws {
        let strong = HTTP.EntityTag.strong("abc")
        let weak = HTTP.EntityTag.weak("abc")

        #expect(HTTP.EntityTag.weakCompare(strong, weak) == true)
        #expect(HTTP.EntityTag.weakCompare(weak, strong) == true)
    }

    @Test
    func `Weak comparison - values differ`() async throws {
        let etag1 = HTTP.EntityTag.strong("abc")
        let etag2 = HTTP.EntityTag.weak("xyz")

        #expect(HTTP.EntityTag.weakCompare(etag1, etag2) == false)
    }

    @Test
    func `Equality`() async throws {
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

    @Test
    func `Hashable`() async throws {
        var set: Set<HTTP.EntityTag> = []
        set.insert(.strong("abc"))
        set.insert(.strong("abc")) // Duplicate
        set.insert(.weak("abc"))   // Different (isWeak differs)
        set.insert(.strong("xyz"))

        #expect(set.count == 3)
    }

    @Test
    func `Codable - strong`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let etag = HTTP.EntityTag.strong("abc123")
        let encoded = try encoder.encode(etag)
        let decoded = try decoder.decode(HTTP.EntityTag.self, from: encoded)

        #expect(decoded == etag)
    }

    @Test
    func `Codable - weak`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let etag = HTTP.EntityTag.weak("abc123")
        let encoded = try encoder.encode(etag)
        let decoded = try decoder.decode(HTTP.EntityTag.self, from: encoded)

        #expect(decoded == etag)
    }

    @Test
    func `Description`() async throws {
        let strong = HTTP.EntityTag.strong("abc")
        #expect(strong.description == "\"abc\"")

        let weak = HTTP.EntityTag.weak("abc")
        #expect(weak.description == "W/\"abc\"")
    }

    @Test
    func `String literal`() async throws {
        let strong: HTTP.EntityTag = "\"abc\""
        #expect(strong.value == "abc")
        #expect(strong.isWeak == false)

        let weak: HTTP.EntityTag = "W/\"abc\""
        #expect(weak.value == "abc")
        #expect(weak.isWeak == true)
    }
}
