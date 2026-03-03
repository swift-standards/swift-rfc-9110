//
//  HTTP.Parse.QuotedString.swift
//  swift-rfc-9110
//
//  HTTP quoted-string: DQUOTE *( qdtext / quoted-pair ) DQUOTE
//

import Parser_Primitives

extension HTTP.Parse {
    /// Parses an HTTP quoted-string per RFC 9110 Section 5.6.4.
    ///
    /// `quoted-string = DQUOTE *( qdtext / quoted-pair ) DQUOTE`
    /// `qdtext = HTAB / SP / %x21 / %x23-5B / %x5D-7E / obs-text`
    /// `quoted-pair = "\" ( HTAB / SP / VCHAR / obs-text )`
    ///
    /// Returns the unescaped content between the quotes.
    public struct QuotedString<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension HTTP.Parse.QuotedString {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedOpenQuote
        case unexpectedEndOfInput
        case invalidEscapeSequence
    }
}

extension HTTP.Parse.QuotedString: Parser.`Protocol` {
    public typealias ParseOutput = [UInt8]
    public typealias Failure = HTTP.Parse.QuotedString<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> [UInt8] {
        var index = input.startIndex
        guard index < input.endIndex, input[index] == 0x22 else {
            throw .expectedOpenQuote
        }
        input.formIndex(after: &index)

        var result: [UInt8] = []

        while index < input.endIndex {
            let byte = input[index]

            if byte == 0x22 {
                // Closing quote
                input.formIndex(after: &index)
                input = input[index...]
                return result
            }

            if byte == 0x5C {
                // Quoted-pair: consume backslash
                input.formIndex(after: &index)
                guard index < input.endIndex else {
                    throw .unexpectedEndOfInput
                }
                let escaped = input[index]
                // quoted-pair allows HTAB / SP / VCHAR / obs-text
                guard escaped == 0x09 || (escaped >= 0x20 && escaped <= 0x7E) || escaped >= 0x80 else {
                    throw .invalidEscapeSequence
                }
                result.append(escaped)
                input.formIndex(after: &index)
                continue
            }

            // qdtext: HTAB / SP / 0x21 / 0x23-5B / 0x5D-7E / obs-text
            result.append(byte)
            input.formIndex(after: &index)
        }

        throw .unexpectedEndOfInput
    }
}
