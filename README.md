# swift-rfc-9110

Swift implementation of RFC 9110: HTTP Semantics

## Overview

This package implements [RFC 9110 - HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html), which obsoletes RFC 7230, 7231, 7232, 7233, 7234, and 7235 (June 2022).

RFC 9110 consolidates and updates the core HTTP specifications, providing a unified foundation for HTTP semantics across all HTTP versions.

## Status

**Alpha** - Week 1 & 2 implementation complete

### Implemented (Week 1)

- ✅ `HTTP.Method` - HTTP methods with properties (Section 9)
  - All standard methods: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, CONNECT, TRACE
  - Properties: `isSafe`, `isIdempotent`, `isCacheable`
  - Full conformances: Sendable, Equatable, Hashable, Codable, RawRepresentable

- ✅ `HTTP.Status` - HTTP status codes (Section 15)
  - All standard status codes (1xx through 5xx)
  - Category checks: `isInformational`, `isSuccessful`, `isRedirection`, `isClientError`, `isServerError`
  - Full conformances: Sendable, Equatable, Hashable, Codable

### Implemented (Week 2)

- ✅ `HTTP.Header.Field` - HTTP header fields (Section 6.3)
  - Name (case-insensitive) and Value (validated for security)
  - CRLF injection prevention
  - 40+ standard header name constants

- ✅ `HTTP.Headers` - Header field collection
  - Case-insensitive subscript access
  - Multiple values per header name
  - Preserves insertion order

- ✅ `HTTP.Request.Target` - Request target forms (Section 7.1)
  - origin-form (most common)
  - absolute-form (for proxies)
  - authority-form (for CONNECT)
  - asterisk-form (for OPTIONS *)

- ✅ `HTTP.Request.Message` - Complete HTTP request
  - Method + Target + Headers + Body
  - Request validation
  - Convenience constructors

- ✅ `HTTP.Response.Message` - Complete HTTP response
  - Status + Headers + Body
  - Convenience constructors (ok, created, notFound, etc.)
  - Helper methods

### Planned

- 📋 Week 3: `HTTP.MediaType`, `HTTP.ContentNegotiation`, `HTTP.Authentication`
- 📋 Future: Additional semantics as needed

## Usage

```swift
import RFC_9110

// Methods with properties
let method = HTTP.Method.get
method.isSafe        // true
method.isIdempotent  // true
method.isCacheable   // true

// Status codes with category checks
let status = HTTP.Status.ok
status.code           // 200
status.isSuccessful   // true
status.description    // "200 OK"

// Headers
let headers = try HTTP.Headers([
    .init(name: "Content-Type", value: "application/json"),
    .init(name: "Accept", value: "application/json")
])

// Request
let request = try HTTP.Request.Message(
    method: .post,
    target: .origin(path: .init("/api/users"), query: nil),
    headers: headers,
    body: Data(#"{"name":"John"}"#.utf8)
)

// Response with convenience constructor
let response = try HTTP.Response.Message.created(
    location: "/api/users/123",
    body: Data(#"{"id":123,"name":"John"}"#.utf8)
)
```

## Requirements

- Swift 6.0+
- macOS 14.0+, iOS 17.0+, tvOS 17.0+, watchOS 10.0+

## Dependencies

- [swift-collections](https://github.com/apple/swift-collections) - OrderedCollections
- [swift-rfc-3986](https://github.com/coenttb/swift-rfc-3986) - URI types

## Installation

```swift
dependencies: [
    .package(path: "../swift-rfc-9110")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "RFC 9110", package: "swift-rfc-9110")
        ]
    )
]
```

## Relationship to Other RFCs

- **RFC 9110** (this package) - HTTP Semantics
- **RFC 9111** - HTTP Caching (planned: swift-rfc-9111)
- **RFC 9112** - HTTP/1.1 Message Syntax (planned: swift-rfc-9112)

Together, these three RFCs replace the obsolete RFC 7230-7235 series.

## Design Principles

Following the established patterns from swift-rfc-7230/7231:

- ✅ Namespace with underscore: `RFC_9110`
- ✅ Convenience typealias: `HTTP = RFC_9110`
- ✅ Comprehensive conformances: Sendable, Equatable, Hashable, Codable
- ✅ Static properties for standard values
- ✅ Full documentation with RFC section references
- ✅ Swift 6.2 strict concurrency enabled

## Testing

```bash
swift test
```

Current test coverage: 75 tests, all passing

## License

[Apache 2.0](LICENSE)

## References

- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html)
- [RFC 9110 Section 9: Methods](https://www.rfc-editor.org/rfc/rfc9110.html#section-9)
- [RFC 9110 Section 15: Status Codes](https://www.rfc-editor.org/rfc/rfc9110.html#section-15)
