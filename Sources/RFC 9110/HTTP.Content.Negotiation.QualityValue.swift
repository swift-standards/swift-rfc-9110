// HTTP.Content.Negotiation.QualityValue.swift
// swift-rfc-9110
//
// RFC 9110 Section 12.4.2: Quality Values
// https://www.rfc-editor.org/rfc/rfc9110.html#section-12.4.2
//
// Quality value for content negotiation preferences

// MARK: - Quality Value

extension RFC_9110.Content.Negotiation {
    /// Quality value (qvalue) per RFC 9110 Section 12.4.2
    ///
    /// Quality values indicate relative preference, ranging from 0 (not acceptable)
    /// to 1 (most preferred).
    ///
    /// ## Example
    ///
    /// ```
    /// Accept: text/html;q=1.0, text/plain;q=0.8, */*;q=0.1
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.4.2: Quality Values](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.4.2)
    public struct QualityValue: Sendable, Equatable, Hashable, Comparable {
        /// The quality value (0.0 to 1.0)
        public let value: Double

        /// Creates a quality value
        ///
        /// - Parameter value: The quality value (clamped to 0.0...1.0)
        public init(_ value: Double) {
            self.value = min(max(value, 0.0), 1.0)
        }

        /// Parses a quality value from a string
        ///
        /// - Parameter string: The quality value string (e.g., "0.8", "1.0")
        /// - Returns: A QualityValue if parsing succeeds, nil otherwise
        public static func parse(_ string: String) -> QualityValue? {
            guard let doubleValue = Double(string) else { return nil }
            return QualityValue(doubleValue)
        }

        /// Default quality value (1.0)
        public static let `default` = QualityValue(1.0)

        /// Zero quality value (not acceptable)
        public static let zero = QualityValue(0.0)

        // MARK: - Comparable

        public static func < (lhs: QualityValue, rhs: QualityValue) -> Bool {
            lhs.value < rhs.value
        }
    }
}

// MARK: - QualityValue Numeric Literals

extension RFC_9110.Content.Negotiation.QualityValue: ExpressibleByFloatLiteral {
    /// Creates a quality value from a floating-point literal
    ///
    /// - Parameter value: The floating-point literal (0.0 to 1.0)
    ///
    /// # Example
    ///
    /// ```swift
    /// let q: HTTP.Content.Negotiation.QualityValue = 0.8
    /// ```
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension RFC_9110.Content.Negotiation.QualityValue: ExpressibleByIntegerLiteral {
    /// Creates a quality value from an integer literal
    ///
    /// - Parameter value: The integer literal (typically 0 or 1)
    ///
    /// # Example
    ///
    /// ```swift
    /// let full: HTTP.Content.Negotiation.QualityValue = 1
    /// let none: HTTP.Content.Negotiation.QualityValue = 0
    /// ```
    public init(integerLiteral value: Int) {
        self.init(Double(value))
    }
}

// MARK: - CustomStringConvertible

extension RFC_9110.Content.Negotiation.QualityValue: CustomStringConvertible {
    public var description: String {
        // Convert to string with 3 decimal places
        let rounded = (value * 1000).rounded() / 1000
        var result = "\(rounded)"

        // If no decimal point, we're done
        guard result.contains(".") else { return result }

        // Remove trailing zeros and decimal point if needed
        result = result.replacing(/\.?0+$/, with: "")

        return result
    }
}
