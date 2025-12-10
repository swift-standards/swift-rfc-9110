// HTTP.MediaType.Tests.swift
// swift-rfc-9110

import Testing

@testable import RFC_9110

@Suite
struct `HTTP.MediaType Tests` {

    @Test
    func `Media type creation`() async throws {
        let json = HTTP.MediaType("application", "json")

        #expect(json.type == "application")
        #expect(json.subtype == "json")
        #expect(json.parameters.isEmpty)
        #expect(json.value == "application/json")
    }

    @Test
    func `Media type with parameters`() async throws {
        let html = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])

        #expect(html.type == "text")
        #expect(html.subtype == "html")
        #expect(html.parameters["charset"] == "utf-8")
        #expect(html.value == "text/html; charset=utf-8")
    }

    @Test
    func `Media type normalization`() async throws {
        let mt = HTTP.MediaType("TEXT", "HTML")

        // Type and subtype should be normalized to lowercase
        #expect(mt.type == "text")
        #expect(mt.subtype == "html")
    }

    @Test
    func `Media type parsing - simple`() async throws {
        let mt = HTTP.MediaType.parse("application/json")

        #expect(mt?.type == "application")
        #expect(mt?.subtype == "json")
        #expect(mt?.parameters.isEmpty == true)
    }

    @Test
    func `Media type parsing - with parameters`() async throws {
        let mt = HTTP.MediaType.parse("text/html; charset=utf-8")

        #expect(mt?.type == "text")
        #expect(mt?.subtype == "html")
        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test
    func `Media type parsing - multiple parameters`() async throws {
        let mt = HTTP.MediaType.parse(
            "multipart/form-data; boundary=----WebKitFormBoundary; charset=utf-8"
        )

        #expect(mt?.type == "multipart")
        #expect(mt?.subtype == "form-data")
        #expect(mt?.parameters["boundary"] == "----WebKitFormBoundary")
        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test
    func `Media type parsing - quoted parameter`() async throws {
        let mt = HTTP.MediaType.parse("text/html; charset=\"utf-8\"")

        #expect(mt?.parameters["charset"] == "utf-8")
    }

    @Test
    func `Media type parsing - invalid`() async throws {
        #expect(HTTP.MediaType.parse("invalid") == nil)
        #expect(HTTP.MediaType.parse("") == nil)
        #expect(HTTP.MediaType.parse("/json") == nil)
        #expect(HTTP.MediaType.parse("application/") == nil)
    }

    @Test
    func `Standard media types`() async throws {
        #expect(HTTP.MediaType.json.value == "application/json")
        #expect(HTTP.MediaType.html.value == "text/html")
        #expect(HTTP.MediaType.xml.value == "text/xml")
        #expect(HTTP.MediaType.plain.value == "text/plain")
        #expect(HTTP.MediaType.pdf.value == "application/pdf")
        #expect(HTTP.MediaType.png.value == "image/png")
        #expect(HTTP.MediaType.jpeg.value == "image/jpeg")
    }

    @Test
    func `Media type matching - exact`() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("application/json"))
        #expect(!json.matches("text/html"))
    }

    @Test
    func `Media type matching - wildcard subtype`() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("application/*"))
        #expect(!json.matches("text/*"))
    }

    @Test
    func `Media type matching - wildcard all`() async throws {
        let json = HTTP.MediaType.json

        #expect(json.matches("*/*"))
    }

    @Test
    func `Media type equality`() async throws {
        let json1 = HTTP.MediaType.json
        let json2 = HTTP.MediaType("application", "json")
        let html = HTTP.MediaType.html

        #expect(json1 == json2)
        #expect(json1 != html)
    }

    @Test
    func `Media type equality ignores parameters`() async throws {
        let html1 = HTTP.MediaType("text", "html")
        let html2 = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])

        #expect(html1 == html2)
    }

    @Test
    func `Media type hashable`() async throws {
        var set: Set<HTTP.MediaType> = []
        set.insert(.json)
        set.insert(.html)
        set.insert(.json)  // duplicate

        #expect(set.count == 2)
    }

    @Test
    func `Media type codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(HTTP.MediaType.json)
        let decoded = try decoder.decode(HTTP.MediaType.self, from: encoded)

        #expect(decoded == .json)
    }

    @Test
    func `Media type string literal`() async throws {
        let json: HTTP.MediaType = "application/json"

        #expect(json == .json)
    }

    @Test
    func `Media type description`() async throws {
        let json = HTTP.MediaType.json
        #expect(json.description == "application/json")

        let html = HTTP.MediaType("text", "html", parameters: ["charset": "utf-8"])
        #expect(html.description == "text/html; charset=utf-8")
    }
}
