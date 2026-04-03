import Foundation
// HTTP.Content.Encoding.Tests.swift
// swift-rfc-9110

import Testing

@testable import RFC_9110

@Suite
struct `HTTP.Content.Encoding Tests` {

    @Test
    func `Standard encodings`() async throws {
        #expect(HTTP.Content.Encoding.gzip.value == "gzip")
        #expect(HTTP.Content.Encoding.deflate.value == "deflate")
        #expect(HTTP.Content.Encoding.compress.value == "compress")
        #expect(HTTP.Content.Encoding.brotli.value == "br")
        #expect(HTTP.Content.Encoding.identity.value == "identity")
    }

    @Test
    func `Custom encoding`() async throws {
        let custom = HTTP.Content.Encoding("custom-encoding")

        #expect(custom.value == "custom-encoding")
    }

    @Test
    func `Case insensitive`() async throws {
        let upper = HTTP.Content.Encoding("GZIP")
        let lower = HTTP.Content.Encoding("gzip")

        #expect(upper.value == "gzip")
        #expect(lower.value == "gzip")
        #expect(upper == lower)
    }

    @Test
    func `Parse single encoding`() async throws {
        let encodings = HTTP.Content.Encoding.parse("gzip")

        #expect(encodings.count == 1)
        #expect(encodings[0] == .gzip)
    }

    @Test
    func `Parse multiple encodings`() async throws {
        let encodings = HTTP.Content.Encoding.parse("gzip, deflate")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .deflate)
    }

    @Test
    func `Parse with whitespace`() async throws {
        let encodings = HTTP.Content.Encoding.parse(" gzip ,  br  ")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .brotli)
    }

    @Test
    func `Parse empty string`() async throws {
        let encodings = HTTP.Content.Encoding.parse("")

        #expect(encodings.isEmpty)
    }

    @Test
    func `Format header - single`() async throws {
        let header = HTTP.Content.Encoding.formatHeader([.gzip])

        #expect(header == "gzip")
    }

    @Test
    func `Format header - multiple`() async throws {
        let header = HTTP.Content.Encoding.formatHeader([.gzip, .deflate, .brotli])

        #expect(header == "gzip, deflate, br")
    }

    @Test
    func `Format header - empty`() async throws {
        let header = HTTP.Content.Encoding.formatHeader([])

        #expect(header.isEmpty)
    }

    @Test
    func `Equality`() async throws {
        let gzip1 = HTTP.Content.Encoding.gzip
        let gzip2 = HTTP.Content.Encoding("gzip")
        let br = HTTP.Content.Encoding.brotli

        #expect(gzip1 == gzip2)
        #expect(gzip1 != br)
    }

    @Test
    func `Hashable`() async throws {
        var set: Set<HTTP.Content.Encoding> = []
        set.insert(.gzip)
        set.insert(.gzip)  // Duplicate
        set.insert(.brotli)

        #expect(set.count == 2)
    }

    @Test
    func `Codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoding = HTTP.Content.Encoding.gzip
        let encoded = try encoder.encode(encoding)
        let decoded = try decoder.decode(HTTP.Content.Encoding.self, from: encoded)

        #expect(decoded == encoding)
    }

    @Test
    func `Description`() async throws {
        #expect(HTTP.Content.Encoding.gzip.description == "gzip")
        #expect(HTTP.Content.Encoding.brotli.description == "br")
    }

    @Test
    func `String literal`() async throws {
        let gzip: HTTP.Content.Encoding = "gzip"
        let custom: HTTP.Content.Encoding = "custom"

        #expect(gzip == .gzip)
        #expect(custom.value == "custom")
    }
}
