import Foundation
// HTTP.Status.Tests.swift
// swift-rfc-9110

import Testing

@testable import RFC_9110

@Suite
struct `HTTP.Status Tests` {

    @Test
    func `Status code properties`() async throws {
        // Informational 1xx
        #expect(HTTP.Status.continue.isInformational == true)
        #expect(HTTP.Status.continue.code == 100)

        // Successful 2xx
        #expect(HTTP.Status.ok.isSuccessful == true)
        #expect(HTTP.Status.ok.code == 200)
        #expect(HTTP.Status.created.isSuccessful == true)
        #expect(HTTP.Status.noContent.isSuccessful == true)

        // Redirection 3xx
        #expect(HTTP.Status.movedPermanently.isRedirection == true)
        #expect(HTTP.Status.movedPermanently.code == 301)
        #expect(HTTP.Status.found.isRedirection == true)
        #expect(HTTP.Status.notModified.isRedirection == true)

        // Client Error 4xx
        #expect(HTTP.Status.badRequest.isClientError == true)
        #expect(HTTP.Status.badRequest.code == 400)
        #expect(HTTP.Status.unauthorized.isClientError == true)
        #expect(HTTP.Status.notFound.isClientError == true)

        // Server Error 5xx
        #expect(HTTP.Status.internalServerError.isServerError == true)
        #expect(HTTP.Status.internalServerError.code == 500)
        #expect(HTTP.Status.serviceUnavailable.isServerError == true)
    }

    @Test
    func `Status equality based on code`() async throws {
        #expect(HTTP.Status.ok == HTTP.Status(200))
        #expect(HTTP.Status.ok == HTTP.Status(200, "OK"))
        #expect(HTTP.Status.ok != HTTP.Status.created)
    }

    @Test
    func `Status hashable`() async throws {
        var set: Set<HTTP.Status> = []
        set.insert(.ok)
        set.insert(.created)
        set.insert(.ok)  // duplicate

        #expect(set.count == 2)
        #expect(set.contains(.ok))
        #expect(set.contains(.created))
    }

    @Test
    func `Status codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(HTTP.Status.ok)
        let decoded = try decoder.decode(HTTP.Status.self, from: encoded)

        #expect(decoded == .ok)
        #expect(decoded.code == 200)
    }

    @Test
    func `Custom status code`() async throws {
        let custom = HTTP.Status(999, "Custom")
        #expect(custom.code == 999)
        #expect(custom.reasonPhrase == "Custom")
    }

    @Test
    func `Integer literal`() async throws {
        let status: HTTP.Status = 200
        #expect(status.code == 200)
        #expect(status == .ok)
    }

    @Test
    func `Description`() async throws {
        #expect(HTTP.Status.ok.description == "200 OK")
        #expect(HTTP.Status(200).description == "200")
    }

    @Test
    func `All standard status codes`() async throws {
        // Just verify they exist and have correct codes
        #expect(HTTP.Status.continue.code == 100)
        #expect(HTTP.Status.switchingProtocols.code == 101)

        #expect(HTTP.Status.ok.code == 200)
        #expect(HTTP.Status.created.code == 201)
        #expect(HTTP.Status.accepted.code == 202)
        #expect(HTTP.Status.noContent.code == 204)

        #expect(HTTP.Status.movedPermanently.code == 301)
        #expect(HTTP.Status.found.code == 302)
        #expect(HTTP.Status.seeOther.code == 303)
        #expect(HTTP.Status.notModified.code == 304)

        #expect(HTTP.Status.badRequest.code == 400)
        #expect(HTTP.Status.unauthorized.code == 401)
        #expect(HTTP.Status.forbidden.code == 403)
        #expect(HTTP.Status.notFound.code == 404)

        #expect(HTTP.Status.internalServerError.code == 500)
        #expect(HTTP.Status.notImplemented.code == 501)
        #expect(HTTP.Status.badGateway.code == 502)
        #expect(HTTP.Status.serviceUnavailable.code == 503)
    }
}
