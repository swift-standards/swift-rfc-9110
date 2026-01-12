import Foundation
// HTTP.Date.Tests.swift
// swift-rfc-9110

import RFC_5322
import Testing

@testable import RFC_9110

@Suite
struct `HTTP.Date Tests` {

    @Test
    func `Date creation`() async throws {
        let timestamp = 784111777.0  // Sun, 06 Nov 1994 08:49:37 GMT
        let httpDate = HTTP.Date(secondsSinceEpoch: timestamp)

        #expect(httpDate.secondsSinceEpoch == timestamp)
    }

    @Test
    func `Header value format - IMF-fixdate`() async throws {
        let httpDate = HTTP.Date(secondsSinceEpoch: 784_111_777)  // Sun, 06 Nov 1994 08:49:37 GMT

        let headerValue = httpDate.httpHeaderValue

        // Should be in IMF-fixdate format
        #expect(headerValue.contains("Sun"))
        #expect(headerValue.contains("06 Nov 1994"))
        #expect(headerValue.contains("08:49:37"))
        #expect(headerValue.contains("0000"))  // GMT offset
    }

    @Test
    func `Parse IMF-fixdate format`() async throws {
        let parsed = HTTP.Date.parseHTTP("Sun, 06 Nov 1994 08:49:37 +0000")

        #expect(parsed != nil)

        let expectedTimestamp = 784111777.0
        let diff = abs(parsed!.secondsSinceEpoch - expectedTimestamp)
        #expect(diff < 1.0)  // Within 1 second
    }

    @Test
    func `Parse RFC 850 format (obsolete)`() async throws {
        // Note: RFC 850 format not yet supported
        let parsed = HTTP.Date.parseHTTP("Sunday, 06-Nov-94 08:49:37 GMT")

        // This will be nil until obsolete formats are implemented
        #expect(parsed == nil)
    }

    @Test
    func `Parse asctime format (obsolete)`() async throws {
        // Note: asctime format not yet supported
        let parsed = HTTP.Date.parseHTTP("Sun Nov  6 08:49:37 1994")

        // This will be nil until obsolete formats are implemented
        #expect(parsed == nil)
    }

    @Test
    func `Parse invalid date`() async throws {
        #expect(HTTP.Date.parseHTTP("invalid") == nil)
        #expect(HTTP.Date.parseHTTP("") == nil)
        #expect(HTTP.Date.parseHTTP("2024-11-16") == nil)  // Wrong format
    }

    @Test
    func `Equality`() async throws {
        let date1 = HTTP.Date(secondsSinceEpoch: 784_111_777)
        let date2 = HTTP.Date(secondsSinceEpoch: 784_111_777)
        let date3 = HTTP.Date(secondsSinceEpoch: 784_111_778)

        #expect(date1 == date2)
        #expect(date1 != date3)
    }

    @Test
    func `Hashable`() async throws {
        var set: Set<HTTP.Date> = []

        set.insert(HTTP.Date(secondsSinceEpoch: 784_111_777))
        set.insert(HTTP.Date(secondsSinceEpoch: 784_111_777))  // Duplicate
        set.insert(HTTP.Date(secondsSinceEpoch: 784_111_778))

        #expect(set.count == 2)
    }

    @Test
    func `Comparable`() async throws {
        let earlier = HTTP.Date(secondsSinceEpoch: 1000)
        let later = HTTP.Date(secondsSinceEpoch: 2000)

        #expect(earlier < later)
        #expect(later > earlier)
    }

    @Test
    func `Codable`() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let httpDate = HTTP.Date(secondsSinceEpoch: 784_111_777)
        let encoded = try encoder.encode(httpDate)
        let decoded = try decoder.decode(HTTP.Date.self, from: encoded)

        let diff = abs(decoded.secondsSinceEpoch - httpDate.secondsSinceEpoch)
        #expect(diff < 1.0)  // Within 1 second
    }

    @Test
    func `Description`() async throws {
        let httpDate = HTTP.Date(secondsSinceEpoch: 784_111_777)

        let description = httpDate.description

        // Description shows the raw timestamp value
        #expect(description.contains("Timestamp"))
        #expect(description.contains("784111777"))
    }

    @Test
    func `Round trip - format and parse`() async throws {
        let original = HTTP.Date(secondsSinceEpoch: 784_111_777)

        let headerValue = original.httpHeaderValue
        let parsed = HTTP.Date.parseHTTP(headerValue)

        #expect(parsed != nil)
        let diff = abs(parsed!.secondsSinceEpoch - original.secondsSinceEpoch)
        #expect(diff < 1.0)  // Within 1 second
    }
}
