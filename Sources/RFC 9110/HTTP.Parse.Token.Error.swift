//
//  HTTP.Parse.Token.Error.swift
//  swift-rfc-9110
//
//  Error type for HTTP token parser.
//

extension HTTP.Parse.Token {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedToken
    }
}
