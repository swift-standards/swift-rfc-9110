// HTTP.Request.Target.Form.swift
// swift-rfc-9110
//
// Nested accessor for request-target form queries per RFC 9110 Section 7.1

extension RFC_9110.Request.Target {
    /// Accessor for querying which of the four request-target forms this value represents.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let target: HTTP.Request.Target = .asterisk
    /// target.form.isAsterisk  // true
    /// target.form.isOrigin    // false
    /// ```
    public struct Form: Sendable {
        let target: RFC_9110.Request.Target

        /// Returns true if this is origin-form
        public var isOrigin: Bool {
            if case .origin = target { return true }
            return false
        }

        /// Returns true if this is absolute-form
        public var isAbsolute: Bool {
            if case .absolute = target { return true }
            return false
        }

        /// Returns true if this is authority-form
        public var isAuthority: Bool {
            if case .authority = target { return true }
            return false
        }

        /// Returns true if this is asterisk-form
        public var isAsterisk: Bool {
            if case .asterisk = target { return true }
            return false
        }
    }

    /// Accessor for querying the request-target form
    public var form: Form { Form(target: self) }
}
