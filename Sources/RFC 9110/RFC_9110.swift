// RFC_9110.swift
// swift-rfc-9110
//
// RFC 9110: HTTP Semantics
// https://www.rfc-editor.org/rfc/rfc9110.html
//
// This package implements the HTTP Semantics specification (RFC 9110)
// which obsoletes RFC 7230, 7231, 7232, 7233, 7234, and 7235 (June 2022).
//
// Key types:
// - HTTP.Method - HTTP methods (GET, POST, etc.)
// - HTTP.Status - HTTP status codes
// - HTTP.Header - HTTP header fields
// - HTTP.Request - HTTP request message
// - HTTP.Response - HTTP response message
// - HTTP.MediaType - Media type handling
// - HTTP.ContentNegotiation - Content negotiation

import RFC_3986

/// HTTP Semantics namespace (RFC 9110)
///
/// This namespace contains types representing HTTP semantics as defined
/// in RFC 9110, which consolidates and updates the core HTTP specifications.
public enum RFC_9110 {}

/// Convenience namespace for HTTP types
///
/// Allows writing `HTTP.Method` instead of `RFC_9110.Method`
public typealias HTTP = RFC_9110
