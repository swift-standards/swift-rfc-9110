//
//  HTTP.Parse.Parameter.swift
//  swift-rfc-9110
//
//  HTTP parameter: token "=" ( token / quoted-string )
//

import Parser_Primitives

extension HTTP.Parse {
    /// Parses a single HTTP parameter per RFC 9110.
    ///
    /// `parameter = parameter-name "=" parameter-value`
    /// `parameter-name = token`
    /// `parameter-value = ( token / quoted-string )`
    ///
    /// Returns the parameter name (as a byte slice) and value (as bytes).
    public struct Parameter<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension HTTP.Parse.Parameter {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedToken
        case expectedEquals
        case expectedValue
        case invalidQuotedString(HTTP.Parse.QuotedString<Input>.Error)
    }
}

extension HTTP.Parse.Parameter: Parser.`Protocol` {
    public typealias ParseOutput = (name: Input, value: [UInt8])
    public typealias Failure = HTTP.Parse.Parameter<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> (name: Input, value: [UInt8]) {
        // Parse parameter name (token)
        let name: Input
        do {
            name = try HTTP.Parse.Token<Input>().parse(&input)
        } catch {
            throw .expectedToken
        }

        // Expect "="
        guard input.startIndex < input.endIndex, input[input.startIndex] == 0x3D else {
            throw .expectedEquals
        }
        input = input[input.index(after: input.startIndex)...]

        // Parse value: quoted-string or token
        if input.startIndex < input.endIndex, input[input.startIndex] == 0x22 {
            // Quoted string
            let value: [UInt8]
            do {
                value = try HTTP.Parse.QuotedString<Input>().parse(&input)
            } catch {
                throw .invalidQuotedString(error)
            }
            return (name: name, value: value)
        } else {
            // Token value
            let tokenValue: Input
            do {
                tokenValue = try HTTP.Parse.Token<Input>().parse(&input)
            } catch {
                throw .expectedValue
            }
            return (name: name, value: Array(tokenValue))
        }
    }
}
