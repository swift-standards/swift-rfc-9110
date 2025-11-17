// HTTP.Headers.swift
// swift-rfc-9110
//
// RFC 9110 Section 6.3: Header Fields
// https://www.rfc-editor.org/rfc/rfc9110.html#section-6.3
//
// A collection of HTTP header fields with convenient access

import Foundation

// MARK: - Headers Collection

extension RFC_9110 {
    /// A collection of HTTP header fields per RFC 9110 Section 6.3
    ///
    /// Provides efficient access to header fields with case-insensitive lookup.
    /// Maintains insertion order for iteration.
    ///
    /// ## Example
    /// ```swift
    /// let headers: HTTP.Headers = try [
    ///     .init(name: "Content-Type", value: "application/json"),
    ///     .init(name: "Authorization", value: "Bearer token")
    /// ]
    ///
    /// // Subscript access (case-insensitive, O(1))
    /// let contentType = headers["content-type"]?.first
    ///
    /// // Collection access (preserves insertion order)
    /// for header in headers {
    ///     print("\(header.name): \(header.value)")
    /// }
    /// ```
    ///
    /// ## Multiple Values
    ///
    /// Per RFC 9110 Section 5.2, multiple header fields with the same name
    /// can be present in a message. Their values can be combined with commas.
    ///
    /// This collection preserves all values for headers with the same name.
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 6.3: Header Fields](https://www.rfc-editor.org/rfc/rfc9110.html#section-6.3)
    /// - [RFC 9110 Section 5.2: Field Order](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.2)
    public struct Headers: Sendable, Equatable, Hashable, Codable {
        // Internal storage: maps header name -> list of values
        private var storage: [Header.Field.Name: [Header.Field.Value]]

        // Ordered list of names to preserve insertion order
        private var orderedNames: [Header.Field.Name]

        /// Creates a headers collection from an array of fields
        ///
        /// - Parameter fields: The header fields
        public init(_ fields: [Header.Field] = []) {
            var storage: [Header.Field.Name: [Header.Field.Value]] = [:]
            var orderedNames: [Header.Field.Name] = []

            for field in fields {
                if storage[field.name] == nil {
                    orderedNames.append(field.name)
                    storage[field.name] = [field.value]
                } else {
                    storage[field.name]?.append(field.value)
                }
            }

            self.storage = storage
            self.orderedNames = orderedNames
        }

        /// Subscript access to header values by name (case-insensitive, O(1))
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: An array of values for that header field, or nil if not present
        ///
        /// ## Example
        /// ```swift
        /// let contentType = headers["content-type"]?.first
        /// let cookies = headers["Set-Cookie"] // All Set-Cookie values
        /// ```
        ///
        /// ## Reference
        ///
        /// Per RFC 9110 Section 5.1, field names are case-insensitive.
        public subscript(_ name: String) -> [Header.Field.Value]? {
            storage[Header.Field.Name(name)]
        }

        /// Returns true if the headers collection is empty
        public var isEmpty: Bool {
            storage.isEmpty
        }

        /// The number of unique header names
        public var count: Int {
            storage.count
        }

        /// Appends a header field to the collection
        ///
        /// - Parameter field: The header field to append
        ///
        /// If a header with the same name already exists, the new value
        /// is appended to the list of values for that header name.
        public mutating func append(_ field: Header.Field) {
            if storage[field.name] == nil {
                orderedNames.append(field.name)
                storage[field.name] = [field.value]
            } else {
                storage[field.name]?.append(field.value)
            }
        }

        /// Removes all header fields with the given name
        ///
        /// - Parameter name: The header field name to remove (case-insensitive)
        public mutating func removeAll(named name: String) {
            let fieldName = Header.Field.Name(name)
            storage.removeValue(forKey: fieldName)
            orderedNames.removeAll { $0 == fieldName }
        }

        /// Gets the first value for a header field name
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: The first value, or nil if not present
        ///
        /// This is a convenience accessor for the common case where you only
        /// need the first value of a header field.
        public func first(_ name: String) -> Header.Field.Value? {
            self[name]?.first
        }

        /// Gets all values for a header field name
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: An array of values, or empty array if not present
        public func values(_ name: String) -> [Header.Field.Value] {
            self[name] ?? []
        }

        /// Returns true if a header field with the given name exists
        ///
        /// - Parameter name: The header field name (case-insensitive)
        /// - Returns: True if the header exists
        public func contains(_ name: String) -> Bool {
            storage[Header.Field.Name(name)] != nil
        }
    }
}

// MARK: - Sequence

extension RFC_9110.Headers: Sequence {
    /// Iterator for Headers collection
    ///
    /// Iterates over all header fields, expanding headers with multiple
    /// values into separate Field instances while preserving order.
    public struct Iterator: IteratorProtocol {
        private var nameIndex = 0
        private var valueIndex = 0
        private let orderedNames: [RFC_9110.Header.Field.Name]
        private let storage: [RFC_9110.Header.Field.Name: [RFC_9110.Header.Field.Value]]

        fileprivate init(
            orderedNames: [RFC_9110.Header.Field.Name],
            storage: [RFC_9110.Header.Field.Name: [RFC_9110.Header.Field.Value]]
        ) {
            self.orderedNames = orderedNames
            self.storage = storage
        }

        public mutating func next() -> RFC_9110.Header.Field? {
            guard nameIndex < orderedNames.count else { return nil }

            let name = orderedNames[nameIndex]
            let values = storage[name]!

            guard valueIndex < values.count else {
                nameIndex += 1
                valueIndex = 0
                return next()
            }

            let value = values[valueIndex]
            valueIndex += 1

            return RFC_9110.Header.Field(name: name, value: value)
        }
    }

    /// Iterates over all header fields (expanding headers with multiple values)
    ///
    /// ## Example
    /// ```swift
    /// for header in headers {
    ///     print("\(header.name): \(header.value)")
    /// }
    /// ```
    public func makeIterator() -> Iterator {
        Iterator(orderedNames: orderedNames, storage: storage)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension RFC_9110.Headers: ExpressibleByArrayLiteral {
    /// Creates a headers collection from an array literal
    ///
    /// ## Example
    /// ```swift
    /// let headers: HTTP.Headers = try [
    ///     .init(name: "Content-Type", value: "application/json"),
    ///     .init(name: "Accept", value: "application/json")
    /// ]
    /// ```
    public init(arrayLiteral elements: RFC_9110.Header.Field...) {
        self.init(elements)
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Headers: CustomStringConvertible {
    /// Returns a string representation of all headers
    ///
    /// Each header field is formatted as "Name: Value" on a separate line.
    public var description: String {
        map(\.description).joined(separator: "\n")
    }
}

// MARK: - Codable

extension RFC_9110.Headers {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let fields = try container.decode([RFC_9110.Header.Field].self)
        self.init(fields)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        // Encode as array of fields for compatibility
        try container.encode(Array(self))
    }
}

// MARK: - CustomDebugStringConvertible

extension RFC_9110.Headers: CustomDebugStringConvertible {
    /// Returns a detailed debug description of the headers collection
    ///
    /// Provides a structured view showing the count and all header fields.
    ///
    /// ## Example Output
    ///
    /// ```
    /// HTTP.Headers(3 fields):
    ///   Content-Type: application/json
    ///   Accept: application/json
    ///   User-Agent: MyApp/1.0
    /// ```
    public var debugDescription: String {
        let headerLines = map { "  \($0.name.rawValue): \($0.value.rawValue)" }
            .joined(separator: "\n")

        if isEmpty {
            return "HTTP.Headers(0 fields)"
        } else {
            return """
            HTTP.Headers(\(count) field\(count == 1 ? "" : "s")):
            \(headerLines)
            """
        }
    }
}
