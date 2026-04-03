// HTTP.Header.Field.Error.swift
// swift-rfc-9110

extension RFC_9110.Header.Field {
    /// Errors that occur during header field validation
    public enum Error: Swift.Error, Sendable {
        /// The header field value is invalid
        case invalidFieldValue(value: String, reason: String)
    }
}
