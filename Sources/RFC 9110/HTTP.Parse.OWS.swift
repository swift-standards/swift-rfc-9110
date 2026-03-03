//
//  HTTP.Parse.OWS.swift
//  swift-rfc-9110
//
//  Optional whitespace: OWS = *( SP / HTAB )
//

import Parser_Primitives

extension HTTP.Parse {
    /// Consumes zero or more SP (0x20) or HTAB (0x09) bytes.
    ///
    /// RFC 9110 Section 5.6.3: OWS (optional whitespace) is used
    /// between header field components.
    public struct OWS<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension HTTP.Parse.OWS: Parser.`Protocol` {
    public typealias ParseOutput = Void
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) {
        var index = input.startIndex
        while index < input.endIndex {
            let byte = input[index]
            guard byte == 0x20 || byte == 0x09 else { break }
            input.formIndex(after: &index)
        }
        input = input[index...]
    }
}
