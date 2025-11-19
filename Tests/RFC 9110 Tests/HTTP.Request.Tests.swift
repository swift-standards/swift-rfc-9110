// HTTP.Request.Tests.swift
// swift-rfc-9110

import Testing
import RFC_3986
@testable import RFC_9110

@Suite("HTTP.Request.Target Tests")
struct HTTPRequestTargetTests {

    @Test("Origin-form request target")
    func originForm() async throws {
        let target = HTTP.Request.Target.origin(
            path: try .init("/users/123"),
            query: try .init("page=1&limit=10")
        )

        #expect(target.rawValue == "/users/123?page=1&limit=10")
        #expect(target.isOriginForm == true)
        #expect(target.isAbsoluteForm == false)
        #expect(target.path?.string == "/users/123")
        #expect(target.query?.string == "page=1&limit=10")
    }

    @Test("Origin-form without query")
    func originFormNoQuery() async throws {
        let target = HTTP.Request.Target.origin(
            path: try .init("/users"),
            query: nil
        )

        #expect(target.rawValue == "/users")
        #expect(target.query == nil)
    }

    @Test("Absolute-form request target")
    func absoluteForm() async throws {
        let uri = try RFC_3986.URI("http://example.com/users?page=1")
        let target = HTTP.Request.Target.absolute(uri)

        #expect(target.rawValue == "http://example.com/users?page=1")
        #expect(target.isAbsoluteForm == true)
        #expect(target.isOriginForm == false)
    }

    @Test("Authority-form request target")
    func authorityForm() async throws {
        let authority = RFC_3986.URI.Authority(
            userinfo: nil,
            host: try .init("example.com"),
            port: .init(80)
        )
        let target = HTTP.Request.Target.authority(authority)

        #expect(target.isAuthorityForm == true)
        #expect(target.isOriginForm == false)
    }

    @Test("Asterisk-form request target")
    func asteriskForm() async throws {
        let target = HTTP.Request.Target.asterisk

        #expect(target.rawValue == "*")
        #expect(target.isAsteriskForm == true)
        #expect(target.path == nil)
        #expect(target.query == nil)
    }

    @Test("Request target codable")
    func targetCodable() async throws {
        let target = HTTP.Request.Target.origin(
            path: try .init("/users"),
            query: try .init("page=1")
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(target)
        let decoded = try decoder.decode(HTTP.Request.Target.self, from: encoded)

        #expect(decoded == target)
    }
}

@Suite("HTTP.Request Tests")
struct HTTPRequestMessageTests {

    @Test("Simple GET request")
    func simpleGetRequest() async throws {
        let request = HTTP.Request(
            method: .get,
            target: .origin(path: try .init("/users"), query: nil)
        )

        #expect(request.method == .get)
        #expect(request.target.rawValue == "/users")
        #expect(request.headers.isEmpty)
        #expect(request.body == nil)
    }

    @Test("POST request with body and headers")
    func postRequestWithBody() async throws {
        let jsonData = Array("{\"name\":\"John\"}".utf8)
        let request = try HTTP.Request(
            method: .post,
            target: .origin(path: .init("/users"), query: nil),
            headers: [
                .init(name: "Content-Type", value: "application/json"),
                .init(name: "Content-Length", value: "\(jsonData.count)")
            ],
            body: jsonData
        )

        #expect(request.method == .post)
        #expect(request.body == jsonData)
        #expect(request.headers["Content-Type"]?.first?.rawValue == "application/json")
    }

    @Test("Convenience initializer with URI components")
    func convenienceInitializer() async throws {
        let request = HTTP.Request(
            method: .get,
            scheme: try .init("https"),
            host: try .init("api.example.com"),
            port: .init(443),
            path: try .init("/v1/users"),
            query: try .init("page=1")
        )

        #expect(request.method == .get)
        #expect(request.target.isAbsoluteForm == true)
        #expect(request.path?.string == "/v1/users")
        #expect(request.query?.string == "page=1")
    }

    @Test("Header accessors")
    func headerAccessors() async throws {
        let request = try HTTP.Request(
            method: .get,
            target: .origin(path: .init("/"), query: nil),
            headers: [
                .init(name: "Accept", value: "application/json"),
                .init(name: "Accept", value: "text/html")
            ]
        )

        // header() method
        let accepts = request.header(.accept)
        #expect(accepts.count == 2)

        // firstHeader() method
        let firstAccept = request.firstHeader(.accept)
        #expect(firstAccept?.rawValue == "application/json")

        // Missing header
        let missing = request.firstHeader(.authorization)
        #expect(missing == nil)
    }

    @Test("Adding headers")
    func addingHeaders() async throws {
        let request = HTTP.Request(
            method: .get,
            target: .origin(path: try .init("/"), query: nil)
        )

        let withHeader = request.addingHeader(
            try .init(name: "Accept", value: "application/json")
        )

        #expect(withHeader.headers.count == 1)
        #expect(request.headers.count == 0) // Original unchanged
    }

    @Test("Removing headers")
    func removingHeaders() async throws {
        let request = try HTTP.Request(
            method: .get,
            target: .origin(path: .init("/"), query: nil),
            headers: [
                .init(name: "Accept", value: "application/json"),
                .init(name: "Authorization", value: "Bearer token")
            ]
        )

        let withoutAuth = request.removingHeaders(.authorization)

        #expect(withoutAuth.headers.count == 1)
        #expect(withoutAuth.headers.contains("Authorization") == false)
        #expect(request.headers.count == 2) // Original unchanged
    }

    @Test("Request validation - CONNECT with authority-form")
    func validationConnectAuthority() async throws {
        let request = HTTP.Request(
            method: .connect,
            target: .authority(
                RFC_3986.URI.Authority(
                    userinfo: nil,
                    host: try .init("example.com"),
                    port: .init(443)
                )
            )
        )

        try request.validate() // Should not throw
    }

    @Test("Request validation - CONNECT with wrong target form")
    func validationConnectWrongTarget() async throws {
        let request = HTTP.Request(
            method: .connect,
            target: .origin(path: try .init("/"), query: nil)
        )

        do {
            try request.validate()
            Issue.record("Should have thrown validation error")
        } catch let error as HTTP.Request.ValidationError {
            if case .invalidMethodForTarget = error {
                // Expected
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    @Test("Request validation - OPTIONS with asterisk-form")
    func validationOptionsAsterisk() async throws {
        let request = HTTP.Request(
            method: .options,
            target: .asterisk
        )

        try request.validate() // Should not throw
    }

    @Test("Request validation - OPTIONS with wrong target form")
    func validationOptionsWrongTarget() async throws {
        let request = HTTP.Request(
            method: .get,
            target: .asterisk
        )

        do {
            try request.validate()
            Issue.record("Should have thrown validation error")
        } catch let error as HTTP.Request.ValidationError {
            if case .invalidMethodForTarget = error {
                // Expected
            } else {
                Issue.record("Wrong error type")
            }
        }
    }

    @Test("Request codable")
    func requestCodable() async throws {
        let request = try HTTP.Request(
            method: .post,
            target: .origin(path: .init("/users"), query: nil),
            headers: [
                .init(name: "Content-Type", value: "application/json")
            ],
            body: Array("test".utf8)
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(request)
        let decoded = try decoder.decode(HTTP.Request.self, from: encoded)

        #expect(decoded == request)
    }

    @Test("Request description")
    func requestDescription() async throws {
        let request = try HTTP.Request(
            method: .get,
            target: .origin(path: .init("/users"), query: .init("page=1")),
            headers: [
                .init(name: "Accept", value: "application/json")
            ]
        )

        let description = request.description
        #expect(description.contains("GET"))
        #expect(description.contains("/users?page=1"))
        #expect(description.contains("Accept: application/json"))
    }
}
