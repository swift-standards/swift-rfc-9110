//
//  HTTP.Parse.CommaSeparated.swift
//  swift-rfc-9110
//
//  Comma-separated list: #element per RFC 9110 Section 5.6.1.
//

public import Parser_Primitives

extension HTTP.Parse {
    /// Parses a comma-separated list from an HTTP header value.
    ///
    /// RFC 9110 Section 5.6.1 defines the `#rule`:
    /// `#element => [ element ] *( OWS "," OWS [ element ] )`
    ///
    /// Empty elements between commas are silently skipped.
    /// The `transform` closure converts each non-empty trimmed element.
    public struct CommaSeparated<Input: Collection.Slice.`Protocol`, T: Sendable>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @usableFromInline
        let transform: @Sendable (Input) -> T?

        @inlinable
        public init(_ transform: @escaping @Sendable (Input) -> T?) {
            self.transform = transform
        }
    }
}

extension HTTP.Parse.CommaSeparated: Parser.`Protocol` {
    public typealias Output = [T]
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> [T] {
        var results: [T] = []

        // Parse first element (may be empty)
        HTTP.Parse.OWS<Input>().parse(&input)
        if let first = _parseElement(&input) {
            results.append(first)
        }

        // Parse remaining: *( OWS "," OWS [ element ] )
        while input.startIndex < input.endIndex {
            HTTP.Parse.OWS<Input>().parse(&input)
            guard input.startIndex < input.endIndex, input[input.startIndex] == 0x2C else {
                break
            }
            input = input[input.index(after: input.startIndex)...]
            HTTP.Parse.OWS<Input>().parse(&input)

            if let element = _parseElement(&input) {
                results.append(element)
            }
        }

        return results
    }

    @inlinable
    func _parseElement(_ input: inout Input) -> T? {
        // Collect bytes until comma or end
        var index = input.startIndex
        while index < input.endIndex {
            let byte = input[index]
            if byte == 0x2C { break }
            input.formIndex(after: &index)
        }
        let element = input[input.startIndex..<index]
        input = input[index...]

        guard !element.isEmpty else { return nil }

        // Trim trailing OWS from the element
        var lastNonWS = element.startIndex
        var hasContent = false
        var idx = element.startIndex
        while idx < element.endIndex {
            let b = element[idx]
            if b != 0x20 && b != 0x09 {
                lastNonWS = element.index(after: idx)
                hasContent = true
            }
            element.formIndex(after: &idx)
        }

        if !hasContent { return nil }

        let trimmed = element[element.startIndex..<lastNonWS]
        return transform(trimmed)
    }
}
