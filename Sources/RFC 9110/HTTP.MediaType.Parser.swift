//
//  HTTP.MediaType.Parser.swift
//  swift-rfc-9110
//
//  Media-type parser per RFC 9110 Section 8.3.1.
//

public import Parser_Primitives

extension HTTP.MediaType {
    /// Parses a media-type per RFC 9110 Section 8.3.1.
    ///
    /// ```
    /// media-type = type "/" subtype parameters
    /// type       = token
    /// subtype    = token
    /// parameters = *( OWS ";" OWS [ parameter ] )
    /// ```
    ///
    /// Composes `HTTP.Parse.Token`, `HTTP.Parse.OWS`,
    /// `HTTP.Parse.ParameterList` — zero inline byte logic.
    public struct Parser<Input: Collection.Slice.`Protocol` & Swift.Collection>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension HTTP.MediaType.Parser {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedType
        case expectedSlash
        case expectedSubtype
    }
}

extension HTTP.MediaType.Parser: Parser_Primitives.Parser.`Protocol` {
    public typealias ParseOutput = HTTP.MediaType
    public typealias Failure = HTTP.MediaType.Parser<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> HTTP.MediaType {
        // OWS
        HTTP.Parse.OWS<Input>().parse(&input)

        // type = token
        let typeSlice: Input
        do { typeSlice = try HTTP.Parse.Token<Input>().parse(&input) }
        catch { throw .expectedType }

        // "/"
        guard input.startIndex < input.endIndex,
              input[input.startIndex] == 0x2F
        else { throw .expectedSlash }
        input = input[input.index(after: input.startIndex)...]

        // subtype = token
        let subtypeSlice: Input
        do { subtypeSlice = try HTTP.Parse.Token<Input>().parse(&input) }
        catch { throw .expectedSubtype }

        // parameters = *( OWS ";" OWS parameter )
        let params = HTTP.Parse.ParameterList<Input>().parse(&input)

        // Assemble
        let type = String(decoding: typeSlice, as: UTF8.self).lowercased()
        let subtype = String(decoding: subtypeSlice, as: UTF8.self).lowercased()
        var parameters: [String: String] = [:]
        for p in params {
            let name = String(decoding: p.name, as: UTF8.self).lowercased()
            let value = String(decoding: p.value, as: UTF8.self)
            parameters[name] = value
        }
        return HTTP.MediaType(type, subtype, parameters: parameters)
    }
}
