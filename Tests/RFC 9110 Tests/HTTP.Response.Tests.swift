// HTTP.Response.Tests.swift
// swift-rfc-9110

import Testing
import Foundation
@testable import RFC_9110

@Suite("HTTP.Response Tests")
struct HTTPResponseMessageTests {

    @Test("Simple 200 OK response")
    func simpleOkResponse() async throws {
        let response = HTTP.Response(
            status: .ok
        )

        #expect(response.status == .ok)
        #expect(response.headers.isEmpty)
        #expect(response.body == nil)
    }

    @Test("Response with headers and body")
    func responseWithHeadersAndBody() async throws {
        let jsonData = Data("{\"message\":\"success\"}".utf8)
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json"),
                .init(name: "Content-Length", value: "\(jsonData.count)")
            ],
            body: jsonData
        )

        #expect(response.status.code == 200)
        #expect(response.body == jsonData)
        #expect(response.headers["Content-Type"]?.first?.rawValue == "application/json")
    }

    @Test("Header accessors")
    func headerAccessors() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Set-Cookie", value: "session=abc123"),
                .init(name: "Set-Cookie", value: "user=john")
            ]
        )

        // header() method
        let cookies = response.header(.init("Set-Cookie"))
        #expect(cookies.count == 2)

        // firstHeader() method
        let firstCookie = response.firstHeader(.init("Set-Cookie"))
        #expect(firstCookie?.rawValue == "session=abc123")
    }

    @Test("Adding headers")
    func addingHeaders() async throws {
        let response = HTTP.Response(status: .ok)

        let withHeader = response.addingHeader(
            try .init(name: "Content-Type", value: "application/json")
        )

        #expect(withHeader.headers.count == 1)
        #expect(response.headers.count == 0) // Original unchanged
    }

    @Test("Removing headers")
    func removingHeaders() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json"),
                .init(name: "X-Custom", value: "value")
            ]
        )

        let withoutCustom = response.removingHeaders(.init("X-Custom"))

        #expect(withoutCustom.headers.count == 1)
        #expect(withoutCustom.headers.contains("X-Custom") == false)
        #expect(response.headers.count == 2) // Original unchanged
    }

    @Test("Convenience constructor - ok()")
    func convenienceOk() async throws {
        let response = HTTP.Response.ok(
            body: Data("success".utf8)
        )

        #expect(response.status == .ok)
        #expect(response.body == Data("success".utf8))
    }

    @Test("Convenience constructor - created()")
    func convenienceCreated() async throws {
        let response = try HTTP.Response.created(
            location: "/users/123",
            body: Data("created".utf8)
        )

        #expect(response.status == .created)
        #expect(response.headers["Location"]?.first?.rawValue == "/users/123")
        #expect(response.body == Data("created".utf8))
    }

    @Test("Convenience constructor - noContent()")
    func convenienceNoContent() async throws {
        let response = HTTP.Response.noContent()

        #expect(response.status == .noContent)
        #expect(response.body == nil)
    }

    @Test("Convenience constructor - movedPermanently()")
    func convenienceMovedPermanently() async throws {
        let response = try HTTP.Response.movedPermanently(
            to: "https://newlocation.com"
        )

        #expect(response.status == .movedPermanently)
        #expect(response.headers["Location"]?.first?.rawValue == "https://newlocation.com")
    }

    @Test("Convenience constructor - found()")
    func convenienceFound() async throws {
        let response = try HTTP.Response.found(
            at: "/temporary/location"
        )

        #expect(response.status == .found)
        #expect(response.headers["Location"]?.first?.rawValue == "/temporary/location")
    }

    @Test("Convenience constructor - seeOther()")
    func convenienceSeeOther() async throws {
        let response = try HTTP.Response.seeOther(
            at: "/other/resource"
        )

        #expect(response.status == .seeOther)
        #expect(response.headers["Location"]?.first?.rawValue == "/other/resource")
    }

    @Test("Convenience constructor - notModified()")
    func convenienceNotModified() async throws {
        let response = HTTP.Response.notModified(
            headers: try [
                .init(name: "ETag", value: "\"abc123\"")
            ]
        )

        #expect(response.status == .notModified)
        #expect(response.body == nil)
        #expect(response.headers["ETag"]?.first?.rawValue == "\"abc123\"")
    }

    @Test("Convenience constructor - badRequest()")
    func convenienceBadRequest() async throws {
        let response = HTTP.Response.badRequest(
            body: Data("Invalid request".utf8)
        )

        #expect(response.status == .badRequest)
        #expect(response.body == Data("Invalid request".utf8))
    }

    @Test("Convenience constructor - unauthorized()")
    func convenienceUnauthorized() async throws {
        let response = try HTTP.Response.unauthorized(
            wwwAuthenticate: "Bearer realm=\"api\""
        )

        #expect(response.status == .unauthorized)
        #expect(response.headers["WWW-Authenticate"]?.first?.rawValue == "Bearer realm=\"api\"")
    }

    @Test("Convenience constructor - forbidden()")
    func convenienceForbidden() async throws {
        let response = HTTP.Response.forbidden()

        #expect(response.status == .forbidden)
    }

    @Test("Convenience constructor - notFound()")
    func convenienceNotFound() async throws {
        let response = HTTP.Response.notFound(
            body: Data("Not found".utf8)
        )

        #expect(response.status == .notFound)
        #expect(response.body == Data("Not found".utf8))
    }

    @Test("Convenience constructor - internalServerError()")
    func convenienceInternalServerError() async throws {
        let response = HTTP.Response.internalServerError(
            body: Data("Internal error".utf8)
        )

        #expect(response.status == .internalServerError)
        #expect(response.body == Data("Internal error".utf8))
    }

    @Test("Convenience constructor - serviceUnavailable()")
    func convenienceServiceUnavailable() async throws {
        let response = try HTTP.Response.serviceUnavailable(
            retryAfter: "120"
        )

        #expect(response.status == .serviceUnavailable)
        #expect(response.headers["Retry-After"]?.first?.rawValue == "120")
    }

    @Test("Response codable")
    func responseCodable() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json")
            ],
            body: Data("test".utf8)
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(response)
        let decoded = try decoder.decode(HTTP.Response.self, from: encoded)

        #expect(decoded == response)
    }

    @Test("Response description")
    func responseDescription() async throws {
        let response = try HTTP.Response(
            status: .ok,
            headers: [
                .init(name: "Content-Type", value: "application/json")
            ],
            body: Data("test".utf8)
        )

        let description = response.description
        #expect(description.contains("200"))
        #expect(description.contains("Content-Type: application/json"))
        #expect(description.contains("[Body: 4 bytes]"))
    }

    @Test("Response status category checks")
    func statusCategoryChecks() async throws {
        #expect(HTTP.Response.ok().status.isSuccessful)
        #expect(HTTP.Response.badRequest().status.isClientError)
        #expect(HTTP.Response.internalServerError().status.isServerError)
        #expect(try HTTP.Response.found(at: "/").status.isRedirection)
    }
}
