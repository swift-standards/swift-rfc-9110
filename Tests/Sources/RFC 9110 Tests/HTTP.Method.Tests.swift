import Foundation
// HTTP.Method.Tests.swift
// swift-rfc-9110

import Testing

@testable import RFC_9110

@Suite
struct `HTTP.Method Tests` {

    @Test
    func `Standard methods have correct properties`() async throws {
        // GET - safe, idempotent, cacheable
        #expect(HTTP.Method.get.isSafe == true)
        #expect(HTTP.Method.get.isIdempotent == true)
        #expect(HTTP.Method.get.isCacheable == true)

        // POST - not safe, not idempotent, cacheable
        #expect(HTTP.Method.post.isSafe == false)
        #expect(HTTP.Method.post.isIdempotent == false)
        #expect(HTTP.Method.post.isCacheable == true)

        // PUT - not safe, idempotent, not cacheable
        #expect(HTTP.Method.put.isSafe == false)
        #expect(HTTP.Method.put.isIdempotent == true)
        #expect(HTTP.Method.put.isCacheable == false)

        // DELETE - not safe, idempotent, not cacheable
        #expect(HTTP.Method.delete.isSafe == false)
        #expect(HTTP.Method.delete.isIdempotent == true)
        #expect(HTTP.Method.delete.isCacheable == false)

        // HEAD - safe, idempotent, cacheable
        #expect(HTTP.Method.head.isSafe == true)
        #expect(HTTP.Method.head.isIdempotent == true)
        #expect(HTTP.Method.head.isCacheable == true)

        // OPTIONS - safe, idempotent, not cacheable
        #expect(HTTP.Method.options.isSafe == true)
        #expect(HTTP.Method.options.isIdempotent == true)
        #expect(HTTP.Method.options.isCacheable == false)

        // TRACE - safe, idempotent, not cacheable
        #expect(HTTP.Method.trace.isSafe == true)
        #expect(HTTP.Method.trace.isIdempotent == true)
        #expect(HTTP.Method.trace.isCacheable == false)

        // CONNECT - not safe, not idempotent, not cacheable
        #expect(HTTP.Method.connect.isSafe == false)
        #expect(HTTP.Method.connect.isIdempotent == false)
        #expect(HTTP.Method.connect.isCacheable == false)

        // PATCH - not safe, not idempotent, not cacheable
        #expect(HTTP.Method.patch.isSafe == false)
        #expect(HTTP.Method.patch.isIdempotent == false)
        #expect(HTTP.Method.patch.isCacheable == false)
    }

    @Test
    func `Method equality based on rawValue`() async throws {
        #expect(
            HTTP.Method.get
                == HTTP.Method("GET", isSafe: true, isIdempotent: true, isCacheable: true)
        )
        #expect(HTTP.Method.post != HTTP.Method.get)
    }

    @Test
    func `Method hashable`() async throws {
        var set: Set<HTTP.Method> = []
        set.insert(.get)
        set.insert(.post)
        set.insert(.get)  // duplicate

        #expect(set.count == 2)
        #expect(set.contains(.get))
        #expect(set.contains(.post))
    }

    @Test
    func `Method codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(HTTP.Method.get)
        let decoded = try decoder.decode(HTTP.Method.self, from: encoded)

        #expect(decoded == .get)
        #expect(decoded.isSafe == true)
    }

    @Test
    func `Custom method`() async throws {
        let custom = HTTP.Method(rawValue: "CUSTOM")
        #expect(custom.rawValue == "CUSTOM")
        #expect(custom.isSafe == false)
        #expect(custom.isIdempotent == false)
        #expect(custom.isCacheable == false)
    }

    @Test
    func `String literal`() async throws {
        let method: HTTP.Method = "CUSTOM"
        #expect(method.rawValue == "CUSTOM")
    }

    @Test
    func `Description`() async throws {
        #expect(HTTP.Method.get.description == "GET")
        #expect(HTTP.Method.post.description == "POST")
    }
}
