//
//  HTTP.Parse.QualityValue.swift
//  swift-rfc-9110
//
//  Quality value weight: OWS ";" OWS "q=" qvalue
//

extension HTTP.Parse {
    /// Parses an HTTP quality value (weight) per RFC 9110 Section 12.4.2.
    ///
    /// `weight = OWS ";" OWS "q=" qvalue`
    /// `qvalue = ( "0" [ "." *3DIGIT ] ) / ( "1" [ "." *3"0" ] )`
    ///
    /// Returns a value between 0 and 1000 (q=1.000 → 1000, q=0.5 → 500).
    /// Using integer representation avoids floating-point imprecision.
    public struct QualityValue<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension HTTP.Parse.QualityValue {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedSemicolon
        case expectedQ
        case invalidQValue
    }
}

extension HTTP.Parse.QualityValue: Parser.`Protocol` {
    public typealias ParseOutput = Int
    public typealias Failure = HTTP.Parse.QualityValue<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Int {
        // OWS ";" OWS
        HTTP.Parse.OWS<Input>().parse(&input)
        guard input.startIndex < input.endIndex, input[input.startIndex] == 0x3B else {
            throw .expectedSemicolon
        }
        input = input[input.index(after: input.startIndex)...]
        HTTP.Parse.OWS<Input>().parse(&input)

        // "q=" (case-insensitive for q)
        guard input.startIndex < input.endIndex else { throw .expectedQ }
        let q = input[input.startIndex]
        guard q == 0x71 || q == 0x51 else { throw .expectedQ } // 'q' or 'Q'
        input = input[input.index(after: input.startIndex)...]

        guard input.startIndex < input.endIndex, input[input.startIndex] == 0x3D else {
            throw .expectedQ
        }
        input = input[input.index(after: input.startIndex)...]

        // qvalue: digit before decimal
        guard input.startIndex < input.endIndex else { throw .invalidQValue }
        let intPart = input[input.startIndex]
        guard intPart == 0x30 || intPart == 0x31 else { throw .invalidQValue } // '0' or '1'
        input = input[input.index(after: input.startIndex)...]

        // Optional decimal part
        if input.startIndex < input.endIndex, input[input.startIndex] == 0x2E {
            input = input[input.index(after: input.startIndex)...]

            var frac = 0
            var digits = 0
            while digits < 3, input.startIndex < input.endIndex {
                let byte = input[input.startIndex]
                guard byte >= 0x30, byte <= 0x39 else { break }
                frac = frac * 10 + Int(byte - 0x30)
                digits += 1
                input = input[input.index(after: input.startIndex)...]
            }

            // Pad to 3 digits: "0.5" → 500, "0.05" → 50
            while digits < 3 {
                frac *= 10
                digits += 1
            }

            if intPart == 0x31 {
                // q=1.xxx — only 1.000 is valid
                return frac == 0 ? 1000 : { throw .invalidQValue }()
            }
            return frac
        }

        return intPart == 0x31 ? 1000 : 0
    }
}
