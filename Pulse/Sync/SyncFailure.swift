//
//  SyncFailure.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import CloudKit

// A plain value, `nonisolated` like the other sync status types; see SyncStatusModel.swift.

/// Why a CloudKit import, export or setup failed, reduced to what the user can act on.
nonisolated enum SyncFailure: Equatable, Sendable {
    case noAccount
    case storageFull
    /// No connection. Sync resumes by itself.
    case offline
    /// iCloud is busy, rate limiting or temporarily unavailable. Sync retries by itself.
    case busy
    case other(String)

    /// Failures CloudKit recovers from without the user doing anything.
    var isTransient: Bool { self == .offline || self == .busy }

    /// The failure CloudKit hides in `error`, looking through wrappers and partial failures.
    init(error: Error) {
        self = Self.map(error as NSError, depth: 0)
    }

    private static func map(_ error: NSError, depth: Int) -> SyncFailure {
        if error.domain == NSURLErrorDomain,
           [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost,
            NSURLErrorDataNotAllowed].contains(error.code) {
            return .offline
        }

        if let cloudKitError = (error as Error) as? CKError {
            switch cloudKitError.code {
            case .notAuthenticated:
                return .noAccount
            case .quotaExceeded:
                return .storageFull
            case .networkUnavailable, .networkFailure:
                return .offline
            case .accountTemporarilyUnavailable, .serviceUnavailable, .zoneBusy, .requestRateLimited:
                return .busy
            case .partialFailure:
                let reasons = (cloudKitError.partialErrorsByItemID ?? [:]).values.map {
                    map($0 as NSError, depth: depth + 1)
                }
                // the most serious reason decides
                return reasons.first(where: { !$0.isTransient })
                    ?? reasons.first
                    ?? .other(cloudKitError.localizedDescription)
            default:
                return .other(cloudKitError.localizedDescription)
            }
        }

        // NSPersistentCloudKitContainer often wraps the CloudKit error
        if depth < 4, let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return map(underlying, depth: depth + 1)
        }
        return .other(error.localizedDescription)
    }
}
