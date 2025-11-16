// HTTP.Date.Tests.swift
// swift-rfc-9110

import Testing
import Foundation
@testable import RFC_9110

@Suite("HTTP.Date Tests")
struct HTTPDateTests {

    @Test("Date creation")
    func dateCreation() async throws {
        let date = Date(timeIntervalSince1970: 784111777) // Sun, 06 Nov 1994 08:49:37 GMT
        let httpDate = HTTP.Date(date)

        #expect(httpDate.date == date)
    }

    @Test("Header value format - IMF-fixdate")
    func headerValueFormat() async throws {
        let date = Date(timeIntervalSince1970: 784111777) // Sun, 06 Nov 1994 08:49:37 GMT
        let httpDate = HTTP.Date(date)

        let headerValue = httpDate.headerValue

        // Should be in IMF-fixdate format
        #expect(headerValue.contains("Sun"))
        #expect(headerValue.contains("06 Nov 1994"))
        #expect(headerValue.contains("08:49:37"))
        #expect(headerValue.contains("GMT"))
    }

    @Test("Parse IMF-fixdate format")
    func parseIMFFixdate() async throws {
        let parsed = HTTP.Date.parse("Sun, 06 Nov 1994 08:49:37 GMT")

        #expect(parsed != nil)

        let expectedDate = Date(timeIntervalSince1970: 784111777)
        let diff = abs(parsed!.date.timeIntervalSince(expectedDate))
        #expect(diff < 1.0) // Within 1 second
    }

    @Test("Parse RFC 850 format (obsolete)")
    func parseRFC850() async throws {
        let parsed = HTTP.Date.parse("Sunday, 06-Nov-94 08:49:37 GMT")

        #expect(parsed != nil)
    }

    @Test("Parse asctime format (obsolete)")
    func parseAsctime() async throws {
        let parsed = HTTP.Date.parse("Sun Nov  6 08:49:37 1994")

        #expect(parsed != nil)
    }

    @Test("Parse invalid date")
    func parseInvalidDate() async throws {
        #expect(HTTP.Date.parse("invalid") == nil)
        #expect(HTTP.Date.parse("") == nil)
        #expect(HTTP.Date.parse("2024-11-16") == nil) // Wrong format
    }

    @Test("Equality")
    func equality() async throws {
        let date1 = HTTP.Date(Date(timeIntervalSince1970: 784111777))
        let date2 = HTTP.Date(Date(timeIntervalSince1970: 784111777))
        let date3 = HTTP.Date(Date(timeIntervalSince1970: 784111778))

        #expect(date1 == date2)
        #expect(date1 != date3)
    }

    @Test("Hashable")
    func hashable() async throws {
        var set: Set<HTTP.Date> = []
        let date = Date(timeIntervalSince1970: 784111777)

        set.insert(HTTP.Date(date))
        set.insert(HTTP.Date(date)) // Duplicate
        set.insert(HTTP.Date(Date(timeIntervalSince1970: 784111778)))

        #expect(set.count == 2)
    }

    @Test("Comparable")
    func comparable() async throws {
        let earlier = HTTP.Date(Date(timeIntervalSince1970: 1000))
        let later = HTTP.Date(Date(timeIntervalSince1970: 2000))

        #expect(earlier < later)
        #expect(later > earlier)
    }

    @Test("Codable")
    func codable() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let httpDate = HTTP.Date(Date(timeIntervalSince1970: 784111777))
        let encoded = try encoder.encode(httpDate)
        let decoded = try decoder.decode(HTTP.Date.self, from: encoded)

        let diff = abs(decoded.date.timeIntervalSince(httpDate.date))
        #expect(diff < 1.0) // Within 1 second
    }

    @Test("Description")
    func description() async throws {
        let date = Date(timeIntervalSince1970: 784111777)
        let httpDate = HTTP.Date(date)

        let description = httpDate.description

        #expect(description.contains("Sun"))
        #expect(description.contains("GMT"))
    }

    @Test("Round trip - format and parse")
    func roundTrip() async throws {
        let original = Date(timeIntervalSince1970: 784111777)
        let httpDate = HTTP.Date(original)

        let headerValue = httpDate.headerValue
        let parsed = HTTP.Date.parse(headerValue)

        #expect(parsed != nil)
        let diff = abs(parsed!.date.timeIntervalSince(original))
        #expect(diff < 1.0) // Within 1 second
    }
}
