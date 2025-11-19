// HTTP.Authentication.Tests.swift
// swift-rfc-9110

import Testing
@testable import RFC_9110

@Suite("HTTP.Authentication Tests")
struct HTTPAuthenticationTests {

    // MARK: - Scheme Tests

    @Test("Authentication scheme creation")
    func authenticationSchemeCreation() async throws {
        let basic = HTTP.Authentication.Scheme("Basic")
        #expect(basic.name == "Basic")

        let custom = HTTP.Authentication.Scheme("CustomScheme")
        #expect(custom.name == "CustomScheme")
    }

    @Test("Standard authentication schemes")
    func standardAuthenticationSchemes() async throws {
        #expect(HTTP.Authentication.Scheme.basic.name == "Basic")
        #expect(HTTP.Authentication.Scheme.bearer.name == "Bearer")
        #expect(HTTP.Authentication.Scheme.digest.name == "Digest")
        #expect(HTTP.Authentication.Scheme.negotiate.name == "Negotiate")
        #expect(HTTP.Authentication.Scheme.oauth.name == "OAuth")
    }

    @Test("Scheme equality (case-insensitive)")
    func schemeEquality() async throws {
        let basic1 = HTTP.Authentication.Scheme("Basic")
        let basic2 = HTTP.Authentication.Scheme("basic")
        let basic3 = HTTP.Authentication.Scheme("BASIC")

        #expect(basic1 == basic2)
        #expect(basic2 == basic3)
        #expect(basic1 == basic3)
    }

    @Test("Scheme hashable (case-insensitive)")
    func schemeHashable() async throws {
        var set: Set<HTTP.Authentication.Scheme> = []
        set.insert("Basic")
        set.insert("basic") // Should be same as Basic
        set.insert("Bearer")

        #expect(set.count == 2)
    }

    // MARK: - Challenge Tests

    @Test("Challenge creation - simple")
    func challengeCreationSimple() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic)

        #expect(challenge.scheme == .basic)
        #expect(challenge.parameters.isEmpty)
        #expect(challenge.realm == nil)
    }

    @Test("Challenge creation - with realm")
    func challengeCreationWithRealm() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API Access")

        #expect(challenge.scheme == .basic)
        #expect(challenge.realm == "API Access")
    }

    @Test("Challenge creation - with parameters")
    func challengeCreationWithParameters() async throws {
        let challenge = HTTP.Authentication.Challenge(
            scheme: .bearer,
            parameters: ["realm": "example", "scope": "read write"]
        )

        #expect(challenge.scheme == .bearer)
        #expect(challenge.parameters["realm"] == "example")
        #expect(challenge.parameters["scope"] == "read write")
    }

    @Test("Challenge header value - no parameters")
    func challengeHeaderValueNoParameters() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic)

        #expect(challenge.headerValue == "Basic")
    }

    @Test("Challenge header value - with realm")
    func challengeHeaderValueWithRealm() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API Access")

        let headerValue = challenge.headerValue
        #expect(headerValue.contains("Basic"))
        #expect(headerValue.contains("realm="))
        #expect(headerValue.contains("API Access"))
    }

    @Test("Challenge header value - multiple parameters")
    func challengeHeaderValueMultipleParameters() async throws {
        let challenge = HTTP.Authentication.Challenge(
            scheme: .bearer,
            parameters: ["realm": "example", "scope": "read"]
        )

        let headerValue = challenge.headerValue
        #expect(headerValue.contains("Bearer"))
        #expect(headerValue.contains("realm="))
        #expect(headerValue.contains("scope="))
    }

    @Test("Challenge parsing - scheme only")
    func challengeParsingSchemeOnly() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Basic")

        #expect(challenge?.scheme == .basic)
        #expect(challenge?.parameters.isEmpty == true)
    }

    @Test("Challenge parsing - with parameters")
    func challengeParsingWithParameters() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Basic realm=\"API Access\"")

        #expect(challenge?.scheme == .basic)
        #expect(challenge?.parameters["realm"] == "API Access")
    }

    @Test("Challenge parsing - multiple parameters")
    func challengeParsingMultipleParameters() async throws {
        let challenge = HTTP.Authentication.Challenge.parse("Bearer realm=\"example\", scope=\"read write\"")

        #expect(challenge?.scheme == .bearer)
        #expect(challenge?.parameters["realm"] == "example")
        #expect(challenge?.parameters["scope"] == "read write")
    }

    // MARK: - Credentials Tests

    @Test("Credentials creation")
    func credentialsCreation() async throws {
        let creds = HTTP.Authentication.Credentials(scheme: .bearer, token: "abc123")

        #expect(creds.scheme == .bearer)
        #expect(creds.token == "abc123")
    }

    @Test("Credentials - basic authentication")
    func credentialsBasic() async throws {
        let creds = HTTP.Authentication.Credentials.basic(username: "user", password: "pass")

        #expect(creds.scheme == .basic)

        // Verify it's base64 encoded
        let decoded = Data(base64Encoded: creds.token)
        #expect(decoded != nil)

        let decodedString = String(data: decoded!, encoding: .utf8)
        #expect(decodedString == "user:pass")
    }

    @Test("Credentials - bearer token")
    func credentialsBearer() async throws {
        let creds = HTTP.Authentication.Credentials.bearer("token123")

        #expect(creds.scheme == .bearer)
        #expect(creds.token == "token123")
    }

    @Test("Credentials header value")
    func credentialsHeaderValue() async throws {
        let basic = HTTP.Authentication.Credentials.basic(username: "user", password: "pass")
        #expect(basic.headerValue.hasPrefix("Basic "))

        let bearer = HTTP.Authentication.Credentials.bearer("token123")
        #expect(bearer.headerValue == "Bearer token123")
    }

    @Test("Credentials parsing")
    func credentialsParsing() async throws {
        let creds = HTTP.Authentication.Credentials.parse("Bearer abc123")

        #expect(creds?.scheme == .bearer)
        #expect(creds?.token == "abc123")
    }

    @Test("Credentials parsing - with whitespace")
    func credentialsParsingWhitespace() async throws {
        let creds = HTTP.Authentication.Credentials.parse("  Bearer   abc123  ")

        #expect(creds?.scheme == .bearer)
        #expect(creds?.token == "abc123")
    }

    @Test("Credentials parsing - invalid")
    func credentialsParsingInvalid() async throws {
        let invalid = HTTP.Authentication.Credentials.parse("InvalidFormat")

        #expect(invalid == nil)
    }

    // MARK: - Codable Tests

    @Test("Scheme codable")
    func schemeCodable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(HTTP.Authentication.Scheme.basic)
        let decoded = try decoder.decode(HTTP.Authentication.Scheme.self, from: encoded)

        #expect(decoded == .basic)
    }

    @Test("Challenge codable")
    func challengeCodable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API")
        let encoded = try encoder.encode(challenge)
        let decoded = try decoder.decode(HTTP.Authentication.Challenge.self, from: encoded)

        #expect(decoded == challenge)
    }

    @Test("Credentials codable")
    func credentialsCodable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let creds = HTTP.Authentication.Credentials.bearer("token123")
        let encoded = try encoder.encode(creds)
        let decoded = try decoder.decode(HTTP.Authentication.Credentials.self, from: encoded)

        #expect(decoded == creds)
    }

    // MARK: - Description Tests

    @Test("Scheme description")
    func schemeDescription() async throws {
        #expect(HTTP.Authentication.Scheme.basic.description == "Basic")
        #expect(HTTP.Authentication.Scheme.bearer.description == "Bearer")
    }

    @Test("Challenge description")
    func challengeDescription() async throws {
        let challenge = HTTP.Authentication.Challenge(scheme: .basic, realm: "API")
        let description = challenge.description

        #expect(description.contains("Basic"))
        #expect(description.contains("realm"))
    }

    @Test("Credentials description")
    func credentialsDescription() async throws {
        let creds = HTTP.Authentication.Credentials.bearer("token123")
        #expect(creds.description == "Bearer token123")
    }

    // MARK: - String Literal Tests

    @Test("Scheme string literal")
    func schemeStringLiteral() async throws {
        let scheme: HTTP.Authentication.Scheme = "Basic"
        #expect(scheme == .basic)
    }
}
