//
//  HTTP.Parse.ParameterList.swift
//  swift-rfc-9110
//
//  Semicolon-separated parameter list: *( OWS ";" OWS parameter )
//

import Parser_Primitives

extension HTTP.Parse {
    /// Parses a semicolon-separated list of parameters.
    ///
    /// `*( OWS ";" OWS parameter )`
    ///
    /// Used by media-type, content-type, and content-disposition headers.
    public struct ParameterList<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension HTTP.Parse.ParameterList: Parser.`Protocol` {
    public typealias ParseOutput = [(name: Input, value: [UInt8])]
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> [(name: Input, value: [UInt8])] {
        var results: [(name: Input, value: [UInt8])] = []

        while true {
            // Save position before attempting separator + parameter
            let saved = input

            // OWS ";" OWS
            HTTP.Parse.OWS<Input>().parse(&input)
            guard input.startIndex < input.endIndex, input[input.startIndex] == 0x3B else {
                input = saved
                break
            }
            input = input[input.index(after: input.startIndex)...]
            HTTP.Parse.OWS<Input>().parse(&input)

            // parameter
            guard let param = try? HTTP.Parse.Parameter<Input>().parse(&input) else {
                input = saved
                break
            }
            results.append(param)
        }

        return results
    }
}
