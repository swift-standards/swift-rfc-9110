// HTTP.Authentication.Tests.swift
// swift-rfc-9110

import Testing
@testable import RFC_9110

@Suite
struct `HTTP.Authentication Tests` {

    // MARK: - Scheme Tests

    @Test
    func `Authentication scheme creation`() async throws {
        let basic = HTTP.Authentication.Scheme("Basic")
        #expect(basic.name == "Basic")

        let custom = HTTP.Authentication.Scheme("CustomScheme")
        #expect(custom.name == "CustomScheme")
    }

    @Test
    func `Standard authentication schemes`() async throws {
        #expect(HTTP.Authentication.Scheme.basic.name == "Basic")
        #expect(HTTP.Authentication.Scheme.bearer.name == "Bearer")
        #expect(HTTP.Authentication.Scheme.digest.name == "Digest")
        #expect(HTTP.Authentication.Scheme.negotiate.name == "Negotiate")
        #expect(HTTP.Authentication.Scheme.oauth.name == "OAuth")
    }

    @Test
    func `Scheme equality (case-insensitive)`() async throws {
        let basic1 = HTTP.Authentication.Scheme("Basic")
        let basic2 = HTTP.Authentication.Scheme("basic")
        let basic3 = HTTP.Authentication.Scheme("BASIC")

        #expect(basic1 == basic2)
        #expect(basic2 == basic3)
        #expect(basic1 == basic3)
    }

    @Test
    func `Scheme hashable (case-insensitive)`() async throws {
        var set: Set<HTTP.Authentication.Scheme> = []
        set.insert("Basic")
        set.insert("basic") // Should be same as Basic
        set.insert("Bearer")

        #expect(set.count == 2)
    }

    // MARK: - Challenge Tests

    @Test
    func `Challenge creation - simple`() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic)

        #expect(challenge.scheme == .basic)
        #expect(challenge.parameters.isEmpty)
        #expect(challenge.realm == nil)
    }

    @Test
    func `Challenge creation - with realm`() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API Access")

        #expect(challenge.scheme == .basic)
        #expect(challenge.realm == "API Access")
    }

    @Test
    func `Challenge creation - with parameters`() async throws {
        let challenge = HTTP.Authentication.Challenge(
            scheme: .bearer,
            parameters: ["realm": "example", "scope": "read write"]
        )

        #expect(challenge.scheme == .bearer)
        #expect(challenge.parameters["realm"] == "example")
        #expect(challenge.parameters["scope"] == "read write")
    }

    @Test
    func `Challenge header value - no parameters`() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic)

        #expect(challenge.headerValue == "Basic")
    }

    @Test
    func `Challenge header value - with realm`() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API Access")

        let headerValue = challenge.headerValue
        #expect(headerValue.contains("Basic"))
        #expect(headerValue.contains("realm="))
        #expect(headerValue.contains("API Access"))
    }

    @Test
    func `Challenge header value - multiple parameters`() async throws {
        let challenge = HTTP.Authentication.Challenge(
            scheme: .bearer,
            parameters: ["realm": "example", "scope": "read"]
        )

        let headerValue = challenge.headerValue
        #expect(headerValue.contains("Bearer"))
        #expect(headerValue.contains("realm="))
        #expect(headerValue.contains("scope="))
    }

    @Test
    func `Challenge parsing - scheme only`() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Basic")

        #expect(challenge?.scheme == .basic)
        #expect(challenge?.parameters.isEmpty == true)
    }

    @Test
    func `Challenge parsing - with parameters`() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Basic realm=\"API Access\"")

        #expect(challenge?.scheme == .basic)
        #expect(challenge?.parameters["realm"] == "API Access")
    }

    @Test
    func `Challenge parsing - multiple parameters`() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Bearer realm=\"example\", scope=\"read write\"")

        #expect(challenge?.scheme == .bearer)
        #expect(challenge?.parameters["realm"] == "example")
        #expect(challenge?.parameters["scope"] == "read write")
    }

    // MARK: - Credentials Tests

    @Test
    func `Credentials creation`() async throws {
        let creds = HTTP.Authentication.Credentials(scheme: .bearer, token: "abc123")

        #expect(creds.scheme == .bearer)
        #expect(creds.token == "abc123")
    }

    @Test
    func `Credentials - basic authentication`() async throws {
        let creds = HTTP.Authentication.Credentials.basic(username: "user", password: "pass")

        #expect(creds.scheme == .basic)

        // Verify it's base64 encoded
        let decoded = Data(base64Encoded: creds.token)
        #expect(decoded != nil)

        let decodedString = String(data: decoded!, encoding: .utf8)
        #expect(decodedString == "user:pass")
    }

    @Test
    func `Credentials - bearer token`() async throws {
        let creds = HTTP.Authentication.Credentials.bearer("token123")

        #expect(creds.scheme == .bearer)
        #expect(creds.token == "token123")
    }

    @Test
    func `Credentials header value`() async throws {
        let basic = HTTP.Authentication.Credentials.basic(username: "user", password: "pass")
        #expect(basic.headerValue.hasPrefix("Basic "))

        let bearer = HTTP.Authentication.Credentials.bearer("token123")
        #expect(bearer.headerValue == "Bearer token123")
    }

    @Test
    func `Credentials parsing`() async throws {
        let creds = HTTP.Authentication.Credentials.parse("Bearer abc123")

        #expect(creds?.scheme == .bearer)
        #expect(creds?.token == "abc123")
    }

    @Test
    func `Credentials parsing - with whitespace`() async throws {
        let creds = HTTP.Authentication.Credentials.parse("  Bearer   abc123  ")

        #expect(creds?.scheme == .bearer)
        #expect(creds?.token == "abc123")
    }

    @Test
    func `Credentials parsing - invalid`() async throws {
        let invalid = HTTP.Authentication.Credentials.parse("InvalidFormat")

        #expect(invalid == nil)
    }

    // MARK: - Codable Tests

    @Test
    func `Scheme codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(HTTP.Authentication.Scheme.basic)
        let decoded = try decoder.decode(HTTP.Authentication.Scheme.self, from: encoded)

        #expect(decoded == .basic)
    }

    @Test
    func `Challenge codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API")
        let encoded = try encoder.encode(challenge)
        let decoded = try decoder.decode(HTTP.Authentication.Challenge.self, from: encoded)

        #expect(decoded == challenge)
    }

    @Test
    func `Credentials codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let creds = HTTP.Authentication.Credentials.bearer("token123")
        let encoded = try encoder.encode(creds)
        let decoded = try decoder.decode(HTTP.Authentication.Credentials.self, from: encoded)

        #expect(decoded == creds)
    }

    // MARK: - Description Tests

    @Test
    func `Scheme description`() async throws {
        #expect(HTTP.Authentication.Scheme.basic.description == "Basic")
        #expect(HTTP.Authentication.Scheme.bearer.description == "Bearer")
    }

    @Test
    func `Challenge description`() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API")
        let description = challenge.description

        #expect(description.contains("Basic"))
        #expect(description.contains("realm"))
    }

    @Test
    func `Credentials description`() async throws {
        let creds = HTTP.Authentication.Credentials.bearer("token123")
        #expect(creds.description == "Bearer token123")
    }

    // MARK: - String Literal Tests

    @Test
    func `Scheme string literal`() async throws {
        let scheme: HTTP.Authentication.Scheme = "Basic"
        #expect(scheme == .basic)
    }
}
