//
//  ReflectionSession.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.10.26.
//

import Foundation

/// Measures how long the reflection sheet is open while the app is in the foreground.
///
/// Time in the background is not counted, so a sheet left open overnight does not turn into
/// hours of Mindful Minutes. Only the total is kept; the gaps are not needed.
struct ReflectionSession {
    private var accumulated: TimeInterval = 0
    private var resumedAt: Date?

    /// Starts counting from zero.
    mutating func start(at date: Date) {
        accumulated = 0
        resumedAt = date
    }

    /// Stops counting until `resume(at:)`. Calling it again while paused does nothing.
    mutating func pause(at date: Date) {
        guard let resumedAt else { return }
        accumulated += max(0, date.timeIntervalSince(resumedAt))
        self.resumedAt = nil
    }

    /// Continues counting after `pause(at:)`. Calling it while running does nothing.
    mutating func resume(at date: Date) {
        guard resumedAt == nil else { return }
        resumedAt = date
    }

    /// Foreground time up to `date`, including the running stretch if not paused.
    func foregroundDuration(at date: Date) -> TimeInterval {
        let running = resumedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0
        return accumulated + running
    }

    /// `true` if the morning forecast or the evening reflection changed.
    /// Metric values are deliberately ignored: entering a number is not reflecting.
    static func hasReflectionChanges(morning: String, summary: String,
                                     originalMorning: String, originalSummary: String) -> Bool {
        morning != originalMorning || summary != originalSummary
    }
}
