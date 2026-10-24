//
//  HealthMoodLogger.swift
//  Pulse
//
//  Created by Marcus Raitner on 24.10.26.
//

import OSLog
import Foundation
import HealthKit

/// Writes moments to Apple Health as State of Mind samples.
///
/// Write-only: Pulse never reads from HealthKit. Each `DailyLogEntry` maps to one sample whose
/// `HKMetadataKeySyncIdentifier` is the entry's `id`, so an edit replaces the sample and a delete
/// can find it again — without storing anything new in SwiftData.
struct HealthMoodLogger {
    private static let logger = Logger(subsystem: "de.raitner.pulse", category: "HealthMoodLogger")
    private static let store = HKHealthStore()
    private static let stateOfMindType = HKSampleType.stateOfMindType()

    /// Maps Pulse's −2…+2 score onto HealthKit's continuous −1…+1 valence.
    static func valence(for score: Int) -> Double {
        min(max(Double(score) / 2, -1), 1)
    }

    /// A sync version that grows with every write.
    ///
    /// Milliseconds rather than seconds: HealthKit ignores a sample whose version is not higher
    /// than the stored one, so two edits within the same second would otherwise drop the second.
    static func syncVersion(at date: Date) -> Int {
        Int(date.timeIntervalSince1970 * 1000)
    }

    /// Builds the State of Mind sample for one moment.
    static func sample(id: UUID, timestamp: Date, score: Int, version: Int) -> HKStateOfMind {
        HKStateOfMind(
            date: timestamp,
            kind: .momentaryEmotion,
            valence: valence(for: score),
            labels: [],
            associations: [],
            metadata: [
                HKMetadataKeySyncIdentifier: id.uuidString,
                HKMetadataKeySyncVersion: version
            ]
        )
    }

    /// Asks for permission to write State of Mind samples. No read access is requested.
    /// - Returns: `true` if writing is allowed afterwards.
    static func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: [stateOfMindType], read: [])
        } catch {
            logger.error("Failed to request HealthKit authorization: \(String(describing: error))")
        }
        return store.authorizationStatus(for: stateOfMindType) == .sharingAuthorized
    }

    /// `true` if the user enabled the setting on this device and granted write access.
    private static var canWrite: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.healthMoodLogging)
            && HKHealthStore.isHealthDataAvailable()
            && store.authorizationStatus(for: stateOfMindType) == .sharingAuthorized
    }

    /// Writes the moment to Health, replacing any earlier sample for the same entry.
    /// Runs asynchronously inside a `Task`; the caller does not need to `await`.
    static func save(_ entry: DailyLogEntry) {
        guard canWrite else { return }
        // Copy the values out; the SwiftData model must not cross into the task.
        let sample = sample(id: entry.id, timestamp: entry.timestamp, score: entry.score,
                            version: syncVersion(at: .now))
        Task {
            do {
                try await store.save(sample)
            } catch {
                logger.error("Failed to save State of Mind sample: \(String(describing: error))")
            }
        }
    }

    /// Deletes the sample written for the moment with this `id`, if there is one.
    /// Runs asynchronously inside a `Task`; the caller does not need to `await`.
    static func delete(id: UUID) {
        guard canWrite else { return }
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier,
                                                    allowedValues: [id.uuidString])
        Task {
            do {
                try await store.deleteObjects(of: stateOfMindType, predicate: predicate)
            } catch {
                logger.error("Failed to delete State of Mind sample: \(String(describing: error))")
            }
        }
    }
}
