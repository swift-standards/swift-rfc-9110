// HTTP.Request.Error.swift
// swift-rfc-9110
//
// RFC 9110 Section 7: Request Semantics
// https://www.rfc-editor.org/rfc/rfc9110.html#section-7
//
// Validation errors for HTTP request messages

// MARK: - Validation Error

extension RFC_9110.Request {
    /// Errors that occur during request validation
    public enum Error: Swift.Error, Sendable {
        /// Invalid method for the request-target form
        case invalidMethodForTarget(
            method: RFC_9110.Method,
            target: Target,
            reason: String
        )
    }
}
