// HTTP.Headers.Iterator.swift
// swift-rfc-9110
//
// RFC 9110 Section 6.3: Header Fields
// https://www.rfc-editor.org/rfc/rfc9110.html#section-6.3
//
// Iterator for HTTP headers collection

// MARK: - Iterator

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

        init(
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
