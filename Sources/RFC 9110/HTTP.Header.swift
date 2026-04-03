// HTTP.Header.swift
// swift-rfc-9110
//
// RFC 9110 Section 6.3: Header Fields
// https://www.rfc-editor.org/rfc/rfc9110.html#section-6.3
//
// HTTP header fields are key-value pairs that convey information about the
// message, its content, or the connection itself.

extension RFC_9110 {
    /// HTTP Header namespace (RFC 9110 Section 6.3)
    ///
    /// Header fields are sent and received in both HTTP requests and responses.
    /// They provide information about the request, response, or about the object
    /// sent in the message body.
    public enum Header {}
}
