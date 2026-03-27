//
//  DateFormatter.swift
//  Pulse
//
//  Created by Marcus Raitner on 23.02.26.
//

import Foundation

/// Utility for formatting dates as ISO 8601 strings.
/// Used to expose date values to UI tests via accessibility values.
struct DateFormatHelper {
    private static let isoFormatter: ISO8601DateFormatter = ISO8601DateFormatter()

    /// Formats a date as an ISO 8601 string (e.g. `"2026-03-27T10:00:00Z"`).
    /// Returns an empty string if `date` is `nil`.
    static func formatDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoFormatter.string(from: date)
    }
}
