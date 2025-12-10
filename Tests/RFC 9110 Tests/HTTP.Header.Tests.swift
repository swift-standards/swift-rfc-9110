// HTTP.Header.Tests.swift
// swift-rfc-9110

import Testing

@testable import RFC_9110

@Suite
struct `HTTP.Header.Field Tests` {

    @Test
    func `Field name case insensitivity`() async throws {
        let name1 = HTTP.Header.Field.Name("Content-Type")
        let name2 = HTTP.Header.Field.Name("content-type")
        let name3 = HTTP.Header.Field.Name("CONTENT-TYPE")

        #expect(name1 == name2)
        #expect(name2 == name3)
        #expect(name1 == name3)
    }

    @Test
    func `Field name hashable with case insensitivity`() async throws {
        var set: Set<HTTP.Header.Field.Name> = []
        set.insert("Content-Type")
        set.insert("content-type")  // Same as above
        set.insert("Accept")

        #expect(set.count == 2)
    }

    @Test
    func `Field value validation - valid values`() async throws {
        // Valid values should not throw
        _ = try HTTP.Header.Field.Value("application/json")
        _ = try HTTP.Header.Field.Value("text/html; charset=utf-8")
        _ = try HTTP.Header.Field.Value("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        _ = try HTTP.Header.Field.Value("")
    }

    @Test
    func `Field value validation - reject CR`() async throws {
        do {
            _ = try HTTP.Header.Field.Value("value\rtest")
            Issue.record("Should have thrown for CR character")
        } catch let error as HTTP.Header.Field.ValidationError {
            if case .invalidFieldValue(let value, let reason) = error {
                #expect(value == "value\rtest")
                #expect(reason.contains("CR"))
            } else {
                Issue.record("Wrong error case")
            }
        }
    }

    @Test
    func `Field value validation - reject LF`() async throws {
        do {
            _ = try HTTP.Header.Field.Value("value\ntest")
            Issue.record("Should have thrown for LF character")
        } catch let error as HTTP.Header.Field.ValidationError {
            if case .invalidFieldValue(let value, let reason) = error {
                #expect(value == "value\ntest")
                #expect(reason.contains("LF"))
            } else {
                Issue.record("Wrong error case")
            }
        }
    }

    @Test
    func `Field value validation - reject CRLF injection`() async throws {
        do {
            _ = try HTTP.Header.Field.Value("value\r\nX-Injected: malicious")
            Issue.record("Should have thrown for CRLF injection")
        } catch {
            // Expected to throw
        }
    }

    @Test
    func `Field value unchecked init`() async throws {
        // Unchecked init should not validate
        let value = HTTP.Header.Field.Value(unchecked: "value\r\ntest")
        #expect(value.rawValue == "value\r\ntest")
    }

    @Test
    func `Field creation`() async throws {
        let field = try HTTP.Header.Field(
            name: "Content-Type",
            value: "application/json"
        )

        #expect(field.name.rawValue == "Content-Type")
        #expect(field.value.rawValue == "application/json")
    }

    @Test
    func `Field description`() async throws {
        let field = try HTTP.Header.Field(
            name: "Content-Type",
            value: "application/json"
        )

        #expect(field.description == "Content-Type: application/json")
    }

    @Test
    func `Field codable`() async throws {
        let field = try HTTP.Header.Field(
            name: "Content-Type",
            value: "application/json"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(field)
        let decoded = try decoder.decode(HTTP.Header.Field.self, from: encoded)

        #expect(decoded == field)
    }

    @Test
    func `Standard header names`() async throws {
        #expect(HTTP.Header.Field.Name.contentType.rawValue == "Content-Type")
        #expect(HTTP.Header.Field.Name.accept.rawValue == "Accept")
        #expect(HTTP.Header.Field.Name.authorization.rawValue == "Authorization")
        #expect(HTTP.Header.Field.Name.userAgent.rawValue == "User-Agent")
        #expect(HTTP.Header.Field.Name.host.rawValue == "Host")
    }
}

@Suite
struct `HTTP.Headers Tests` {

    @Test
    func `Headers initialization`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Content-Type", value: "application/json"),
            .init(name: "Accept", value: "application/json"),
        ])

        #expect(headers.count == 2)
        #expect(!headers.isEmpty)
    }

    @Test
    func `Headers subscript access (case-insensitive)`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Content-Type", value: "application/json")
        ])

        #expect(headers["Content-Type"]?.first?.rawValue == "application/json")
        #expect(headers["content-type"]?.first?.rawValue == "application/json")
        #expect(headers["CONTENT-TYPE"]?.first?.rawValue == "application/json")
        #expect(headers["Accept"] == nil)
    }

    @Test
    func `Headers with multiple values`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Accept", value: "application/json"),
            .init(name: "Accept", value: "text/html"),
        ])

        let acceptValues = headers["Accept"]
        #expect(acceptValues?.count == 2)
        #expect(acceptValues?[0].rawValue == "application/json")
        #expect(acceptValues?[1].rawValue == "text/html")
    }

    @Test
    func `Headers append`() async throws {
        var headers = try HTTP.Headers([
            .init(name: "Content-Type", value: "application/json")
        ])

        headers.append(try .init(name: "Accept", value: "application/json"))
        #expect(headers.count == 2)

        // Append to existing header
        headers.append(try .init(name: "Accept", value: "text/html"))
        #expect(headers.count == 2)  // Still 2 unique names
        #expect(headers["Accept"]?.count == 2)
    }

    @Test
    func `Headers removeAll`() async throws {
        var headers = try HTTP.Headers([
            .init(name: "Content-Type", value: "application/json"),
            .init(name: "Accept", value: "application/json"),
        ])

        headers.removeAll(named: "Content-Type")
        #expect(headers.count == 1)
        #expect(headers["Content-Type"] == nil)
        #expect(headers["Accept"] != nil)
    }

    @Test
    func `Headers sequence`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Content-Type", value: "application/json"),
            .init(name: "Accept", value: "text/html"),
            .init(name: "Accept", value: "application/json"),
        ])

        let fields = Array(headers)
        #expect(fields.count == 3)

        // Check that multiple Accept values are expanded
        let acceptFields = fields.filter { $0.name.rawValue.lowercased() == "accept" }
        #expect(acceptFields.count == 2)
    }

    @Test
    func `Headers contains`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Content-Type", value: "application/json")
        ])

        #expect(headers.contains("Content-Type"))
        #expect(headers.contains("content-type"))  // Case insensitive
        #expect(!headers.contains("Accept"))
    }

    @Test
    func `Headers first`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Accept", value: "application/json"),
            .init(name: "Accept", value: "text/html"),
        ])

        #expect(headers.first("Accept")?.rawValue == "application/json")
        #expect(headers.first("Content-Type") == nil)
    }

    @Test
    func `Headers values`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Accept", value: "application/json"),
            .init(name: "Accept", value: "text/html"),
        ])

        let values = headers.values("Accept")
        #expect(values.count == 2)

        let emptyValues = headers.values("Content-Type")
        #expect(emptyValues.isEmpty)
    }

    @Test
    func `Headers codable`() async throws {
        let headers = try HTTP.Headers([
            .init(name: "Content-Type", value: "application/json"),
            .init(name: "Accept", value: "text/html"),
        ])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(headers)
        let decoded = try decoder.decode(HTTP.Headers.self, from: encoded)

        #expect(decoded == headers)
    }
}
