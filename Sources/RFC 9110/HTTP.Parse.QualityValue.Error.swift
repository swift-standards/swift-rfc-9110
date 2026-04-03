//
//  HTTP.Parse.QualityValue.Error.swift
//  swift-rfc-9110
//
//  Error type for HTTP quality value parser.
//

extension HTTP.Parse.QualityValue {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedSemicolon
        case expectedQ
        case invalidQValue
    }
}
