//
//  HTTP.MediaType.Parser.Error.swift
//  swift-rfc-9110
//
//  Error type for media-type parser per RFC 9110 Section 8.3.1.
//

extension HTTP.MediaType.Parser {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedType
        case expectedSlash
        case expectedSubtype
    }
}
