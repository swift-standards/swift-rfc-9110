import Foundation
// HTTP.Response.Tests.swift
// swift-rfc-9110

import Testing

@testable import RFC_9110

@Suite
struct `HTTP.Response Tests` {

    @Test
    func `Simple 200 OK response`() async throws {
        let response = HTTP.Response(
            status: .ok
        )

        #expect(response.status == .ok)
        #expect(response.headers.isEmpty)
        #expect(response.body == nil)
    }

    @Test
    func `Response with headers and body`() async throws {
        let jsonData = Array("{\"message\":\"success\"}".utf8)
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json"),
                .init(name: "Content-Length", value: "\(jsonData.count)"),
            ],
            body: jsonData
        )

        #expect(response.status.code == 200)
        #expect(response.body == jsonData)
        #expect(response.headers["Content-Type"]?.first?.rawValue == "application/json")
    }

    @Test
    func `Header accessors`() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Set-Cookie", value: "session=abc123"),
                .init(name: "Set-Cookie", value: "user=john"),
            ]
        )

        // header() method
        let cookies = response.header(.init("Set-Cookie"))
        #expect(cookies.count == 2)

        // firstHeader() method
        let firstCookie = response.firstHeader(.init("Set-Cookie"))
        #expect(firstCookie?.rawValue == "session=abc123")
    }

    @Test
    func `Adding headers`() async throws {
        let response = HTTP.Response(status: .ok)

        let withHeader = response.addingHeader(
            try .init(name: "Content-Type", value: "application/json")
        )

        #expect(withHeader.headers.count == 1)
        #expect(response.headers.isEmpty)  // Original unchanged
    }

    @Test
    func `Removing headers`() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json"),
                .init(name: "X-Custom", value: "value"),
            ]
        )

        let withoutCustom = response.removingHeaders(.init("X-Custom"))

        #expect(withoutCustom.headers.count == 1)
        #expect(withoutCustom.headers.contains("X-Custom") == false)
        #expect(response.headers.count == 2)  // Original unchanged
    }

    @Test
    func `Convenience constructor - ok()`() async throws {
        let response = HTTP.Response.ok(
            body: Array("success".utf8)
        )

        #expect(response.status == .ok)
        #expect(response.body == Array("success".utf8))
    }

    @Test
    func `Convenience constructor - created()`() async throws {
        let response = try HTTP.Response.created(
            location: "/users/123",
            body: Array("created".utf8)
        )

        #expect(response.status == .created)
        #expect(response.headers["Location"]?.first?.rawValue == "/users/123")
        #expect(response.body == Array("created".utf8))
    }

    @Test
    func `Convenience constructor - noContent()`() async throws {
        let response = HTTP.Response.noContent()

        #expect(response.status == .noContent)
        #expect(response.body == nil)
    }

    @Test
    func `Convenience constructor - movedPermanently()`() async throws {
        let response = try HTTP.Response.movedPermanently(
            to: "https://newlocation.com"
        )

        #expect(response.status == .movedPermanently)
        #expect(response.headers["Location"]?.first?.rawValue == "https://newlocation.com")
    }

    @Test
    func `Convenience constructor - found()`() async throws {
        let response = try HTTP.Response.found(
            at: "/temporary/location"
        )

        #expect(response.status == .found)
        #expect(response.headers["Location"]?.first?.rawValue == "/temporary/location")
    }

    @Test
    func `Convenience constructor - seeOther()`() async throws {
        let response = try HTTP.Response.seeOther(
            at: "/other/resource"
        )

        #expect(response.status == .seeOther)
        #expect(response.headers["Location"]?.first?.rawValue == "/other/resource")
    }

    @Test
    func `Convenience constructor - notModified()`() async throws {
        let response = HTTP.Response.notModified(
            headers: try [
                .init(name: "ETag", value: "\"abc123\"")
            ]
        )

        #expect(response.status == .notModified)
        #expect(response.body == nil)
        #expect(response.headers["ETag"]?.first?.rawValue == "\"abc123\"")
    }

    @Test
    func `Convenience constructor - badRequest()`() async throws {
        let response = HTTP.Response.badRequest(
            body: Array("Invalid request".utf8)
        )

        #expect(response.status == .badRequest)
        #expect(response.body == Array("Invalid request".utf8))
    }

    @Test
    func `Convenience constructor - unauthorized()`() async throws {
        let response = try HTTP.Response.unauthorized(
            wwwAuthenticate: "Bearer realm=\"api\""
        )

        #expect(response.status == .unauthorized)
        #expect(response.headers["WWW-Authenticate"]?.first?.rawValue == "Bearer realm=\"api\"")
    }

    @Test
    func `Convenience constructor - forbidden()`() async throws {
        let response = HTTP.Response.forbidden()

        #expect(response.status == .forbidden)
    }

    @Test
    func `Convenience constructor - notFound()`() async throws {
        let response = HTTP.Response.notFound(
            body: Array("Not found".utf8)
        )

        #expect(response.status == .notFound)
        #expect(response.body == Array("Not found".utf8))
    }

    @Test
    func `Convenience constructor - internalServerError()`() async throws {
        let response = HTTP.Response.internalServerError(
            body: Array("Internal error".utf8)
        )

        #expect(response.status == .internalServerError)
        #expect(response.body == Array("Internal error".utf8))
    }

    @Test
    func `Convenience constructor - serviceUnavailable()`() async throws {
        let response = try HTTP.Response.serviceUnavailable(
            retryAfter: "120"
        )

        #expect(response.status == .serviceUnavailable)
        #expect(response.headers["Retry-After"]?.first?.rawValue == "120")
    }

    @Test
    func `Response codable`() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json")
            ],
            body: Array("test".utf8)
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(response)
        let decoded = try decoder.decode(HTTP.Response.self, from: encoded)

        #expect(decoded == response)
    }

    @Test
    func `Response description`() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json")
            ],
            body: Array("test".utf8)
        )

        let description = response.description
        #expect(description.contains("200"))
        #expect(description.contains("Content-Type: application/json"))
        #expect(description.contains("[Body: 4 bytes]"))
    }

    @Test
    func `Response status category checks`() async throws {
        #expect(HTTP.Response.ok().status.isSuccessful)
        #expect(HTTP.Response.badRequest().status.isClientError)
        #expect(HTTP.Response.internalServerError().status.isServerError)
        #expect(try HTTP.Response.found(at: "/").status.isRedirection)
    }
}
