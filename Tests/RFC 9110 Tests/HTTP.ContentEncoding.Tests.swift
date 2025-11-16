// HTTP.ContentEncoding.Tests.swift
// swift-rfc-9110

import Testing
import Foundation
@testable import RFC_9110

@Suite("HTTP.ContentEncoding Tests")
struct HTTPContentEncodingTests {

    @Test("Standard encodings")
    func standardEncodings() async throws {
        #expect(HTTP.ContentEncoding.gzip.value == "gzip")
        #expect(HTTP.ContentEncoding.deflate.value == "deflate")
        #expect(HTTP.ContentEncoding.compress.value == "compress")
        #expect(HTTP.ContentEncoding.brotli.value == "br")
        #expect(HTTP.ContentEncoding.identity.value == "identity")
    }

    @Test("Custom encoding")
    func customEncoding() async throws {
        let custom = HTTP.ContentEncoding("custom-encoding")

        #expect(custom.value == "custom-encoding")
    }

    @Test("Case insensitive")
    func caseInsensitive() async throws {
        let upper = HTTP.ContentEncoding("GZIP")
        let lower = HTTP.ContentEncoding("gzip")

        #expect(upper.value == "gzip")
        #expect(lower.value == "gzip")
        #expect(upper == lower)
    }

    @Test("Parse single encoding")
    func parseSingleEncoding() async throws {
        let encodings = HTTP.ContentEncoding.parse("gzip")

        #expect(encodings.count == 1)
        #expect(encodings[0] == .gzip)
    }

    @Test("Parse multiple encodings")
    func parseMultipleEncodings() async throws {
        let encodings = HTTP.ContentEncoding.parse("gzip, deflate")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .deflate)
    }

    @Test("Parse with whitespace")
    func parseWithWhitespace() async throws {
        let encodings = HTTP.ContentEncoding.parse(" gzip ,  br  ")

        #expect(encodings.count == 2)
        #expect(encodings[0] == .gzip)
        #expect(encodings[1] == .brotli)
    }

    @Test("Parse empty string")
    func parseEmptyString() async throws {
        let encodings = HTTP.ContentEncoding.parse("")

        #expect(encodings.isEmpty)
    }

    @Test("Format header - single")
    func formatHeaderSingle() async throws {
        let header = HTTP.ContentEncoding.formatHeader([.gzip])

        #expect(header == "gzip")
    }

    @Test("Format header - multiple")
    func formatHeaderMultiple() async throws {
        let header = HTTP.ContentEncoding.formatHeader([.gzip, .deflate, .brotli])

        #expect(header == "gzip, deflate, br")
    }

    @Test("Format header - empty")
    func formatHeaderEmpty() async throws {
        let header = HTTP.ContentEncoding.formatHeader([])

        #expect(header == "")
    }

    @Test("Equality")
    func equality() async throws {
        let gzip1 = HTTP.ContentEncoding.gzip
        let gzip2 = HTTP.ContentEncoding("gzip")
        let br = HTTP.ContentEncoding.brotli

        #expect(gzip1 == gzip2)
        #expect(gzip1 != br)
    }

    @Test("Hashable")
    func hashable() async throws {
        var set: Set<HTTP.ContentEncoding> = []
        set.insert(.gzip)
        set.insert(.gzip) // Duplicate
        set.insert(.brotli)

        #expect(set.count == 2)
    }

    @Test("Codable")
    func codable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoding = HTTP.ContentEncoding.gzip
        let encoded = try encoder.encode(encoding)
        let decoded = try decoder.decode(HTTP.ContentEncoding.self, from: encoded)

        #expect(decoded == encoding)
    }

    @Test("Description")
    func description() async throws {
        #expect(HTTP.ContentEncoding.gzip.description == "gzip")
        #expect(HTTP.ContentEncoding.brotli.description == "br")
    }

    @Test("String literal")
    func stringLiteral() async throws {
        let gzip: HTTP.ContentEncoding = "gzip"
        let custom: HTTP.ContentEncoding = "custom"

        #expect(gzip == .gzip)
        #expect(custom.value == "custom")
    }
}
