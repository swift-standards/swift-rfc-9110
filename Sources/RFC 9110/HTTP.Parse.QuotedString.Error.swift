//
//  HTTP.Parse.QuotedString.Error.swift
//  swift-rfc-9110
//
//  Error type for HTTP quoted-string parser.
//

extension HTTP.Parse.QuotedString {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedOpenQuote
        case unexpectedEndOfInput
        case invalidEscapeSequence
    }
}
