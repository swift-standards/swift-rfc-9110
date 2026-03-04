//
//  HTTP.Parse.swift
//  swift-rfc-9110
//
//  Namespace for HTTP parser combinators per RFC 9110 grammar.
//

import Parser_Primitives
import Parser_ASCII_Integer_Primitives

extension HTTP {
    public enum Parse {}
}

// MARK: - Byte-Level Parsing Helpers

extension HTTP.Parse {
    /// RFC 9110 Section 5.6.2: token character (tchar).
    @usableFromInline
    static func _isTchar(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x21, 0x23, 0x24, 0x25, 0x26, 0x27, 0x2A, 0x2B,
            0x2D, 0x2E, 0x5E, 0x5F, 0x60, 0x7C, 0x7E:
            true
        case 0x30...0x39: true
        case 0x41...0x5A: true
        case 0x61...0x7A: true
        default: false
        }
    }

    /// Skip optional whitespace (SP / HTAB).
    @usableFromInline
    static func _skipOWS(_ bytes: [UInt8], _ i: inout Int) {
        while i < bytes.count && (bytes[i] == 0x20 || bytes[i] == 0x09) {
            i &+= 1
        }
    }

    /// Parse a token, advancing index past it.
    @usableFromInline
    static func _token(_ bytes: [UInt8], _ i: inout Int) -> String? {
        let start = i
        while i < bytes.count && _isTchar(bytes[i]) { i &+= 1 }
        guard i > start else { return nil }
        return String(decoding: bytes[start..<i], as: UTF8.self)
    }

    /// Parse a quoted-string per RFC 9110 Section 5.6.4, advancing index past closing quote.
    @usableFromInline
    static func _quotedString(_ bytes: [UInt8], _ i: inout Int) -> String? {
        guard i < bytes.count, bytes[i] == 0x22 else { return nil }
        i &+= 1
        var result: [UInt8] = []
        while i < bytes.count {
            if bytes[i] == 0x22 { i &+= 1; return String(decoding: result, as: UTF8.self) }
            if bytes[i] == 0x5C, i &+ 1 < bytes.count {
                i &+= 1
                result.append(bytes[i])
            } else {
                result.append(bytes[i])
            }
            i &+= 1
        }
        return nil
    }

    /// Parse a token or quoted-string value.
    @usableFromInline
    static func _tokenOrQuotedString(_ bytes: [UInt8], _ i: inout Int) -> String? {
        if i < bytes.count, bytes[i] == 0x22 {
            return _quotedString(bytes, &i)
        }
        return _token(bytes, &i)
    }

    /// Split bytes on commas, respecting quoted strings. Returns ranges into the byte array.
    @usableFromInline
    static func _splitOnComma(_ bytes: [UInt8]) -> [Range<Int>] {
        var ranges: [Range<Int>] = []
        var j = 0
        var start = 0
        while j < bytes.count {
            if bytes[j] == 0x22 {
                j &+= 1
                while j < bytes.count, bytes[j] != 0x22 {
                    if bytes[j] == 0x5C, j &+ 1 < bytes.count { j &+= 1 }
                    j &+= 1
                }
                if j < bytes.count { j &+= 1 }
            } else if bytes[j] == 0x2C {
                ranges.append(start..<j)
                j &+= 1
                start = j
            } else {
                j &+= 1
            }
        }
        ranges.append(start..<bytes.count)
        return ranges
    }

    /// Trim leading and trailing OWS from a byte range. Returns trimmed range.
    @usableFromInline
    static func _trimOWS(_ bytes: [UInt8], _ range: Range<Int>) -> Range<Int> {
        var lo = range.lowerBound
        var hi = range.upperBound
        while lo < hi && (bytes[lo] == 0x20 || bytes[lo] == 0x09) { lo &+= 1 }
        while hi > lo && (bytes[hi &- 1] == 0x20 || bytes[hi &- 1] == 0x09) { hi &-= 1 }
        return lo..<hi
    }

    /// Parse ";q=N.NNN" quality value. Advances index past the quality parameter if found.
    /// Returns nil if no quality parameter present (leaves index unchanged).
    @usableFromInline
    static func _quality(_ bytes: [UInt8], _ i: inout Int) -> Double? {
        let saved = i
        _skipOWS(bytes, &i)
        guard i < bytes.count, bytes[i] == 0x3B else { i = saved; return nil }
        i &+= 1
        _skipOWS(bytes, &i)
        guard i < bytes.count, bytes[i] == 0x71 || bytes[i] == 0x51 else { i = saved; return nil }
        i &+= 1
        guard i < bytes.count, bytes[i] == 0x3D else { i = saved; return nil }
        i &+= 1
        let numStart = i
        while i < bytes.count && ((bytes[i] >= 0x30 && bytes[i] <= 0x39) || bytes[i] == 0x2E) {
            i &+= 1
        }
        guard i > numStart else { i = saved; return nil }
        return Double(String(decoding: bytes[numStart..<i], as: UTF8.self))
    }
}
