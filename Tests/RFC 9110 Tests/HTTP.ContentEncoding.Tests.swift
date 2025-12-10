// HTTP.ContentEncoding.Tests.swift
// swift-rfc-9110

import Testing

@testable import RFC_9110

@Suite
struct `HTTP.ContentEncoding Tests` {

    @Test
    func `Standard encodings`() async throws {
        #expect(HTTP.ContentEncoding.gzip.value == "gzip")
        #expect(HTTP.ContentEncoding.deflate.value == "deflate")
        #expect(HTTP.ContentEncoding.compress.value == "compress")
        #expect(HTTP.ContentEncoding.brotli.value == "br")
        #expect(HTTP.ContentEncoding.identity.value == "identity")
    }

    @Test
    func `Custom encoding`() async throws {
        let custom = HTTP.ContentEncoding("custom-encoding")

        #expect(custom.value == "custom-encoding")
    }

    @Test
    func `Case insensitive`() async throws {
        let upper = HTTP.ContentEncoding("GZIP")
        let lower = HTTP.ContentEncoding("gzip")

        #expect(upper.value == "gzip")
        #expect(lower.value == "gzip")
        #expect(upper == lower)
    }

    @Test
    func `Parse single encoding`() async throws {
        let encodings = HTTP.ContentEncoding.parse("gzip")

        #expect(encodings.count == 1)
        #expect(encodings[0] == .gzip)
    }

    @Test
    func `Parse multiple encodings`() async throws {
        let encodings = HTTP.ContentEncoding.parse("gzip, deflate")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .deflate)
    }

    @Test
    func `Parse with whitespace`() async throws {
        let encodings = HTTP.ContentEncoding.parse(" gzip ,  br  ")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .brotli)
    }

    @Test
    func `Parse empty string`() async throws {
        let encodings = HTTP.ContentEncoding.parse("")

        #expect(encodings.isEmpty)
    }

    @Test
    func `Format header - single`() async throws {
        let header = HTTP.ContentEncoding.formatHeader([.gzip])

        #expect(header == "gzip")
    }

    @Test
    func `Format header - multiple`() async throws {
        let header = HTTP.ContentEncoding.formatHeader([.gzip, .deflate, .brotli])

        #expect(header == "gzip, deflate, br")
    }

    @Test
    func `Format header - empty`() async throws {
        let header = HTTP.ContentEncoding.formatHeader([])

        #expect(header.isEmpty)
    }

    @Test
    func `Equality`() async throws {
        let gzip1 = HTTP.ContentEncoding.gzip
        let gzip2 = HTTP.ContentEncoding("gzip")
        let br = HTTP.ContentEncoding.brotli

        #expect(gzip1 == gzip2)
        #expect(gzip1 != br)
    }

    @Test
    func `Hashable`() async throws {
        var set: Set<HTTP.ContentEncoding> = []
        set.insert(.gzip)
        set.insert(.gzip)  // Duplicate
        set.insert(.brotli)

        #expect(set.count == 2)
    }

    @Test
    func `Codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoding = HTTP.ContentEncoding.gzip
        let encoded = try encoder.encode(encoding)
        let decoded = try decoder.decode(HTTP.ContentEncoding.self, from: encoded)

        #expect(decoded == encoding)
    }

    @Test
    func `Description`() async throws {
        #expect(HTTP.ContentEncoding.gzip.description == "gzip")
        #expect(HTTP.ContentEncoding.brotli.description == "br")
    }

    @Test
    func `String literal`() async throws {
        let gzip: HTTP.ContentEncoding = "gzip"
        let custom: HTTP.ContentEncoding = "custom"

        #expect(gzip == .gzip)
        #expect(custom.value == "custom")
    }
}
