//
//  HTTP.Parse.Parameter.Error.swift
//  swift-rfc-9110
//
//  Error type for HTTP parameter parser.
//

extension HTTP.Parse.Parameter {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedToken
        case expectedEquals
        case expectedValue
        case invalidQuotedString(HTTP.Parse.QuotedString<Input>.Error)
    }
}
