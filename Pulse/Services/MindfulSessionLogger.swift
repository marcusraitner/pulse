//
//  MindfulSessionLogger.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.10.26.
//

import OSLog
import Foundation
import HealthKit

/// Writes reflection sessions to Apple Health as Mindful Minutes.
///
/// Write-only. Every qualifying session is its own sample with no sync identifier: replacing a
/// day's session would let a short later edit overwrite a longer real one, and Pulse cannot read
/// Health to keep the longer of the two. The minimum duration keeps quick fixes out.
struct MindfulSessionLogger {
    private static let logger = Logger(subsystem: "de.raitner.pulse", category: "MindfulSessionLogger")
    private static let mindfulType = HKCategoryType(.mindfulSession)

    /// Shorter sessions are not logged; they are quick fixes rather than reflection.
    static let minimumDuration: TimeInterval = 60
    /// Longer sessions are capped so a forgotten sheet cannot produce implausible data.
    static let maximumDuration: TimeInterval = 30 * 60

    /// The duration to log for a session, or `nil` if it is too short to count.
    static func duration(for foregroundDuration: TimeInterval) -> TimeInterval? {
        guard foregroundDuration >= minimumDuration else { return nil }
        return min(foregroundDuration, maximumDuration)
    }

    /// Builds the Mindful Minutes sample for a session that ended at `end`.
    ///
    /// HealthKit only knows one continuous interval, so background gaps are not represented:
    /// the sample spans `duration` back from `end`.
    static func sample(duration: TimeInterval, endingAt end: Date) -> HKCategorySample {
        HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: end.addingTimeInterval(-duration),
            end: end
        )
    }

    /// `true` if this device has a Health store (e.g. not on iPad without Health).
    static var isAvailable: Bool {
        HealthAccess.isAvailable
    }

    /// `true` if the user denied write access. HealthKit shows its dialog only once, so access
    /// can then only be granted in Settings.
    static var isAccessDenied: Bool {
        HealthAccess.isDenied(mindfulType)
    }

    /// Asks for permission to write Mindful Minutes. No read access is requested.
    /// - Returns: `true` if writing is allowed afterwards.
    static func requestAuthorization() async -> Bool {
        await HealthAccess.requestWriteAccess(to: mindfulType)
    }

    /// `true` if the user enabled the setting on this device and granted write access.
    private static var canWrite: Bool {
        HealthAccess.canWrite(mindfulType, enabledBy: AppStorageKeys.mindfulMinutesLogging)
    }

    /// Writes a session ending now, if it is long enough to count.
    /// Runs asynchronously inside a `Task`; the caller does not need to `await`.
    static func log(foregroundDuration: TimeInterval) {
        guard canWrite, let duration = duration(for: foregroundDuration) else { return }
        let sample = sample(duration: duration, endingAt: .now)
        Task {
            do {
                try await HealthAccess.store.save(sample)
            } catch {
                logger.error("Failed to save Mindful Minutes sample: \(String(describing: error))")
            }
        }
    }
}
