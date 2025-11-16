// HTTP.ContentNegotiation.Tests.swift
// swift-rfc-9110

import Testing
import Foundation
@testable import RFC_9110

@Suite("HTTP.ContentNegotiation Tests")
struct HTTPContentNegotiationTests {

    @Test("Quality value creation")
    func qualityValueCreation() async throws {
        let q1 = HTTP.ContentNegotiation.QualityValue(1.0)
        #expect(q1.value == 1.0)

        let q0 = HTTP.ContentNegotiation.QualityValue(0.0)
        #expect(q0.value == 0.0)

        let q05 = HTTP.ContentNegotiation.QualityValue(0.5)
        #expect(q05.value == 0.5)
    }

    @Test("Quality value clamping")
    func qualityValueClamping() async throws {
        let high = HTTP.ContentNegotiation.QualityValue(1.5)
        #expect(high.value == 1.0)

        let low = HTTP.ContentNegotiation.QualityValue(-0.5)
        #expect(low.value == 0.0)
    }

    @Test("Quality value parsing")
    func qualityValueParsing() async throws {
        let q1 = HTTP.ContentNegotiation.QualityValue.parse("1.0")
        #expect(q1?.value == 1.0)

        let q05 = HTTP.ContentNegotiation.QualityValue.parse("0.5")
        #expect(q05?.value == 0.5)

        let invalid = HTTP.ContentNegotiation.QualityValue.parse("invalid")
        #expect(invalid == nil)
    }

    @Test("Quality value comparison")
    func qualityValueComparison() async throws {
        let q1 = HTTP.ContentNegotiation.QualityValue(1.0)
        let q05 = HTTP.ContentNegotiation.QualityValue(0.5)
        let q0 = HTTP.ContentNegotiation.QualityValue(0.0)

        #expect(q1 > q05)
        #expect(q05 > q0)
        #expect(q0 < q1)
    }

    @Test("Media type preference creation")
    func mediaTypePreferenceCreation() async throws {
        let pref = HTTP.ContentNegotiation.MediaTypePreference(
            mediaType: .json,
            quality: HTTP.ContentNegotiation.QualityValue(0.9)
        )

        #expect(pref.mediaType == .json)
        #expect(pref.quality.value == 0.9)
    }

    @Test("Media type preference default quality")
    func mediaTypePreferenceDefaultQuality() async throws {
        let pref = HTTP.ContentNegotiation.MediaTypePreference(mediaType: .json)

        #expect(pref.quality == .default)
        #expect(pref.quality.value == 1.0)
    }

    @Test("Media type preference parsing - simple")
    func mediaTypePreferenceParsingSimple() async throws {
        let prefs = HTTP.ContentNegotiation.MediaTypePreference.parse("application/json")

        #expect(prefs.count == 1)
        #expect(prefs[0].mediaType == .json)
        #expect(prefs[0].quality.value == 1.0)
    }

    @Test("Media type preference parsing - with quality")
    func mediaTypePreferenceParsingWithQuality() async throws {
        let prefs = HTTP.ContentNegotiation.MediaTypePreference.parse("application/json;q=0.9")

        #expect(prefs.count == 1)
        #expect(prefs[0].mediaType == .json)
        #expect(prefs[0].quality.value == 0.9)
    }

    @Test("Media type preference parsing - multiple")
    func mediaTypePreferenceParsingMultiple() async throws {
        let prefs = HTTP.ContentNegotiation.MediaTypePreference.parse(
            "text/html, application/json;q=0.9, */*;q=0.1"
        )

        #expect(prefs.count == 3)

        // Should be sorted by quality (descending)
        #expect(prefs[0].mediaType == .html)
        #expect(prefs[0].quality.value == 1.0)

        #expect(prefs[1].mediaType == .json)
        #expect(prefs[1].quality.value == 0.9)

        #expect(prefs[2].mediaType.type == "*")
        #expect(prefs[2].quality.value == 0.1)
    }

    @Test("Media type preference parsing - specificity")
    func mediaTypePreferenceParsingSpecificity() async throws {
        // When quality is the same, more specific types should come first
        let prefs = HTTP.ContentNegotiation.MediaTypePreference.parse(
            "*/*;q=0.5, application/*;q=0.5, application/json;q=0.5"
        )

        #expect(prefs.count == 3)

        // More specific should come first
        #expect(prefs[0].mediaType == .json)
        #expect(prefs[1].mediaType.type == "application")
        #expect(prefs[1].mediaType.subtype == "*")
        #expect(prefs[2].mediaType.type == "*")
    }

    @Test("Select media type - exact match")
    func selectMediaTypeExactMatch() async throws {
        let available = [HTTP.MediaType.json, HTTP.MediaType.xml]
        let selected = HTTP.ContentNegotiation.selectMediaType(
            from: available,
            acceptHeader: "application/json"
        )

        #expect(selected == .json)
    }

    @Test("Select media type - quality preference")
    func selectMediaTypeQualityPreference() async throws {
        let available = [HTTP.MediaType.json, HTTP.MediaType.xml]
        let selected = HTTP.ContentNegotiation.selectMediaType(
            from: available,
            acceptHeader: "application/xml;q=0.9, application/json;q=1.0"
        )

        #expect(selected == .json)
    }

    @Test("Select media type - wildcard")
    func selectMediaTypeWildcard() async throws {
        let available = [HTTP.MediaType.json, HTTP.MediaType.html]
        let selected = HTTP.ContentNegotiation.selectMediaType(
            from: available,
            acceptHeader: "text/*"
        )

        #expect(selected == .html)
    }

    @Test("Select media type - wildcard all")
    func selectMediaTypeWildcardAll() async throws {
        let available = [HTTP.MediaType.json, HTTP.MediaType.html]
        let selected = HTTP.ContentNegotiation.selectMediaType(
            from: available,
            acceptHeader: "*/*"
        )

        // Should return first available
        #expect(selected == .json)
    }

    @Test("Select media type - no match")
    func selectMediaTypeNoMatch() async throws {
        let available = [HTTP.MediaType.json]
        let selected = HTTP.ContentNegotiation.selectMediaType(
            from: available,
            acceptHeader: "text/html"
        )

        #expect(selected == nil)
    }

    @Test("Select media types - multiple")
    func selectMediaTypesMultiple() async throws {
        let available = [HTTP.MediaType.json, HTTP.MediaType.xml_app, HTTP.MediaType.html]
        let selected = HTTP.ContentNegotiation.selectMediaTypes(
            from: available,
            acceptHeader: "application/json;q=1.0, application/xml;q=0.9, text/html;q=0.5"
        )

        #expect(selected.count == 3)
        #expect(selected[0] == .json)
        #expect(selected[1] == .xml_app)
        #expect(selected[2] == .html)
    }

    @Test("Select media types - wildcard")
    func selectMediaTypesWildcard() async throws {
        let available = [HTTP.MediaType.json, HTTP.MediaType.xml, HTTP.MediaType.html]
        let selected = HTTP.ContentNegotiation.selectMediaTypes(
            from: available,
            acceptHeader: "application/*;q=1.0, */*;q=0.1"
        )

        #expect(selected.count == 3)
        // JSON and XML should have higher quality (application/*)
        #expect(selected[0] == .json || selected[0] == .xml)
    }

    @Test("Select media types - zero quality excluded")
    func selectMediaTypesZeroQuality() async throws {
        let available = [HTTP.MediaType.json, HTTP.MediaType.html]
        let selected = HTTP.ContentNegotiation.selectMediaTypes(
            from: available,
            acceptHeader: "application/json;q=1.0, text/html;q=0"
        )

        #expect(selected.count == 1)
        #expect(selected[0] == .json)
    }

    @Test("Quality value description")
    func qualityValueDescription() async throws {
        let q1 = HTTP.ContentNegotiation.QualityValue(1.0)
        #expect(q1.description == "1")

        let q09 = HTTP.ContentNegotiation.QualityValue(0.9)
        #expect(q09.description == "0.9")

        let q0 = HTTP.ContentNegotiation.QualityValue(0.0)
        #expect(q0.description == "0")
    }

    @Test("Media type preference description")
    func mediaTypePreferenceDescription() async throws {
        let pref1 = HTTP.ContentNegotiation.MediaTypePreference(mediaType: .json)
        #expect(pref1.description == "application/json")

        let pref2 = HTTP.ContentNegotiation.MediaTypePreference(
            mediaType: .json,
            quality: HTTP.ContentNegotiation.QualityValue(0.9)
        )
        #expect(pref2.description.contains("application/json"))
        #expect(pref2.description.contains("q=0.9"))
    }
}
