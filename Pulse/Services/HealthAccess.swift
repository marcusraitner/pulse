//
//  HealthAccess.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.10.26.
//

import OSLog
import Foundation
import HealthKit

/// Shared HealthKit store and write-only authorization for all Health features.
///
/// HealthKit grants access per data type, so every check takes the type it is about.
/// Pulse never requests read access.
struct HealthAccess {
    private static let logger = Logger(subsystem: "de.raitner.pulse", category: "HealthAccess")

    /// The one store the app uses; Apple recommends a single long-lived instance.
    static let store = HKHealthStore()

    /// `true` if this device has a Health store (e.g. not on iPad without Health).
    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// `true` if the user denied write access to `type`. HealthKit shows its dialog only once,
    /// so access can then only be granted in Settings.
    static func isDenied(_ type: HKObjectType) -> Bool {
        isAvailable && store.authorizationStatus(for: type) == .sharingDenied
    }

    /// Asks for permission to write `type`. No read access is requested.
    /// - Returns: `true` if writing is allowed afterwards.
    static func requestWriteAccess(to type: HKSampleType) async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [type], read: [])
        } catch {
            logger.error("Failed to request HealthKit authorization: \(String(describing: error))")
        }
        return store.authorizationStatus(for: type) == .sharingAuthorized
    }

    /// `true` if the setting stored under `key` is on for this device and writing `type` is allowed.
    static func canWrite(_ type: HKObjectType, enabledBy key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
            && isAvailable
            && store.authorizationStatus(for: type) == .sharingAuthorized
    }
}
