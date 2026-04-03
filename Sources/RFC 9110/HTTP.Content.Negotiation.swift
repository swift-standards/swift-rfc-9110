// HTTP.Content.Negotiation.swift
// swift-rfc-9110
//
// RFC 9110 Section 12: Content Negotiation
// https://www.rfc-editor.org/rfc/rfc9110.html#section-12
//
// Proactive content negotiation mechanisms

extension RFC_9110.Content {
    /// HTTP Content Negotiation (RFC 9110 Section 12)
    ///
    /// Content negotiation allows servers to select the most appropriate representation
    /// of a resource based on client preferences expressed in request headers.
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12: Content Negotiation](https://www.rfc-editor.org/rfc/rfc9110.html#section-12)
    public enum Negotiation {}
}

// MARK: - Content Negotiation Algorithm

extension RFC_9110.Content.Negotiation {
    /// Selects the best media type from available options based on Accept header
    ///
    /// - Parameters:
    ///   - available: The available media types that can be served
    ///   - acceptHeader: The Accept header value from the request
    /// - Returns: The best matching media type, or nil if none is acceptable
    ///
    /// ## Example
    ///
    /// ```swift
    /// let available = [HTTP.MediaType.json, HTTP.MediaType.xml]
    /// let selected = HTTP.Content.Negotiation.selectMediaType(
    ///     from: available,
    ///     acceptHeader: "application/json, application/xml;q=0.9"
    /// )
    /// // Returns .json (highest quality match)
    /// ```
    ///
    /// ## Reference
    ///
    /// - [RFC 9110 Section 12.1: Proactive Negotiation](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.1)
    public static func selectMediaType(
        from available: [RFC_9110.MediaType],
        acceptHeader: String
    ) -> RFC_9110.MediaType? {
        let preferences = MediaTypePreference.parse(acceptHeader)

        // Try each preference in order (already sorted by quality)
        for preference in preferences {
            // Find first available type that matches this preference
            for availableType in available {
                if availableType.matches(preference.mediaType) {
                    return availableType
                }
            }
        }

        return nil
    }

    /// Selects the best media types from available options based on Accept header
    ///
    /// Returns all acceptable media types sorted by preference.
    ///
    /// - Parameters:
    ///   - available: The available media types that can be served
    ///   - acceptHeader: The Accept header value from the request
    /// - Returns: Array of acceptable media types sorted by quality (best first)
    public static func selectMediaTypes(
        from available: [RFC_9110.MediaType],
        acceptHeader: String
    ) -> [RFC_9110.MediaType] {
        let preferences = MediaTypePreference.parse(acceptHeader)
        var results: [(RFC_9110.MediaType, QualityValue)] = []

        for availableType in available {
            // Find the best matching preference for this available type
            var bestQuality: QualityValue?

            for preference in preferences {
                if availableType.matches(preference.mediaType) {
                    if bestQuality == nil || preference.quality > bestQuality! {
                        bestQuality = preference.quality
                    }
                }
            }

            if let quality = bestQuality, quality.value > 0.0 {
                results.append((availableType, quality))
            }
        }

        // Sort by quality (descending)
        return
            results
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}
