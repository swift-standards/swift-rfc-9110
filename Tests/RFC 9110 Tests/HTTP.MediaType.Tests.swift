// HTTP.MediaType.Tests.swift
// swift-rfc-9110

import Testing
@testable import RFC_9110

@Suite("HTTP.MediaType Tests")
struct HTTPMediaTypeTests {

    @Test("Media type creation")
    func mediaTypeCreation() async throws {
        let json = HTTP.MediaType("application", "json")

        #expect(json.type == "application")
        #expect(json.subtype == "json")
        #expect(json.parameters.isEmpty)
        #expect(json.value == "application/json")
    }

    @Test("Media type with parameters")
    func mediaTypeWithParameters() async throws {
        let html = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])

        #expect(html.type == "text")
        #expect(html.subtype == "html")
        #expect(html.parameters["charset"] == "utf-8")
        #expect(html.value == "text/html; charset=utf-8")
    }

    @Test("Media type normalization")
    func mediaTypeNormalization() async throws {
        let mt = HTTP.MediaType("TEXT", "HTML")

        // Type and subtype should be normalized to lowercase
        #expect(mt.type == "text")
        #expect(mt.subtype == "html")
    }

    @Test("Media type parsing - simple")
    func mediaTypeParsingSimple() async throws {
        let mt = HTTP.MediaType.parse("application/json")

        #expect(mt?.type == "application")
        #expect(mt?.subtype == "json")
        #expect(mt?.parameters.isEmpty == true)
    }

    @Test("Media type parsing - with parameters")
    func mediaTypeParsingWithParameters() async throws {
        let mt = HTTP.MediaType.parse("text/html; charset=utf-8")

        #expect(mt?.type == "text")
        #expect(mt?.subtype == "html")
        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test("Media type parsing - multiple parameters")
    func mediaTypeParsingMultiple() async throws {
        let mt = HTTP.MediaType.parse("multipart/form-data; boundary=----WebKitFormBoundary; charset=utf-8")

        #expect(mt?.type == "multipart")
        #expect(mt?.subtype == "form-data")
        #expect(mt?.parameters["boundary"] == "----WebKitFormBoundary")
        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test("Media type parsing - quoted parameter")
    func mediaTypeParsingQuoted() async throws {
        let mt = HTTP.MediaType.parse("text/html; charset=\"utf-8\"")

        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test("Media type parsing - invalid")
    func mediaTypeParsingInvalid() async throws {
        #expect(HTTP.MediaType.parse("invalid") == nil)
        #expect(HTTP.MediaType.parse("") == nil)
        #expect(HTTP.MediaType.parse("/json") == nil)
        #expect(HTTP.MediaType.parse("application/") == nil)
    }

    @Test("Standard media types")
    func standardMediaTypes() async throws {
        #expect(HTTP.MediaType.json.value == "application/json")
        #expect(HTTP.MediaType.html.value == "text/html")
        #expect(HTTP.MediaType.xml.value == "text/xml")
        #expect(HTTP.MediaType.plain.value == "text/plain")
        #expect(HTTP.MediaType.pdf.value == "application/pdf")
        #expect(HTTP.MediaType.png.value == "image/png")
        #expect(HTTP.MediaType.jpeg.value == "image/jpeg")
    }

    @Test("Media type matching - exact")
    func mediaTypeMatchingExact() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("application/json"))
        #expect(!json.matches("text/html"))
    }

    @Test("Media type matching - wildcard subtype")
    func mediaTypeMatchingWildcardSubtype() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("application/*"))
        #expect(!json.matches("text/*"))
    }

    @Test("Media type matching - wildcard all")
    func mediaTypeMatchingWildcardAll() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("*/*"))
    }

    @Test("Media type equality")
    func mediaTypeEquality() async throws {
        let json1 = HTTP.MediaType.json
        let json2 = HTTP.MediaType("application", "json")
        let html = HTTP.MediaType.html

        #expect(json1 == json2)
        #expect(json1 != html)
    }

    @Test("Media type equality ignores parameters")
    func mediaTypeEqualityIgnoresParameters() async throws {
        let html1 = HTTP.MediaType("text", "html")
        let html2 = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])

        #expect(html1 == html2)
    }

    @Test("Media type hashable")
    func mediaTypeHashable() async throws {
        var set: Set<HTTP.MediaType> = []
        set.insert(.json)
        set.insert(.html)
        set.insert(.json) // duplicate

        #expect(set.count == 2)
    }

    @Test("Media type codable")
    func mediaTypeCodable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(HTTP.MediaType.json)
        let decoded = try decoder.decode(HTTP.MediaType.self, from: encoded)

        #expect(decoded == .json)
    }

    @Test("Media type string literal")
    func mediaTypeStringLiteral() async throws {
        let json: HTTP.MediaType = "application/json"

        #expect(json == .json)
    }

    @Test("Media type description")
    func mediaTypeDescription() async throws {
        let json = HTTP.MediaType.json
        #expect(json.description == "application/json")

        let html = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])
        #expect(html.description == "text/html; charset=utf-8")
    }
}
