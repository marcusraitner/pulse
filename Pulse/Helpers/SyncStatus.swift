//
//  SyncStatus.swift
//  Pulse
//
//  Created by Marcus Raitner on 05.10.26.
//

import CloudKit
import CoreData

// Pure state for the iCloud sync status row. No framework objects are kept, so every rule
// here can be unit tested. `ICloudSyncMonitor` feeds it with what CloudKit reports.
// The types are `nonisolated` because they are plain values, not UI state.

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

/// One import, export or setup task of the sync container, as reported by CloudKit.
/// Every task is reported twice: when it starts and when it ends.
nonisolated struct SyncEventInfo: Equatable, Sendable {
    enum Kind: Hashable, Sendable { case setup, `import`, export }

    enum Status: Equatable, Sendable {
        case running
        case succeeded(ended: Date)
        case failed(SyncFailure)
        /// Ended without success and without an error, e.g. the app was suspended.
        case cancelled
    }

    let id: UUID
    let kind: Kind
    let status: Status
}

nonisolated extension SyncEventInfo {
    /// `nil` for event types this app doesn't know.
    init?(_ event: NSPersistentCloudKitContainer.Event) {
        let kind: Kind
        switch event.type {
        case .setup: kind = .setup
        case .import: kind = .import
        case .export: kind = .export
        @unknown default: return nil
        }

        let status: Status
        if let ended = event.endDate {
            if event.succeeded {
                status = .succeeded(ended: ended)
            } else if let error = event.error {
                status = .failed(SyncFailure(error: error))
            } else {
                status = .cancelled
            }
        } else {
            status = .running
        }

        self.init(id: event.identifier, kind: kind, status: status)
    }
}

/// What the sync status row shows.
nonisolated struct SyncStatusModel: Equatable {
    enum Account: Equatable, Sendable {
        /// Not read yet, or iCloud can't say right now. Never treated as a problem.
        case unknown
        case available
        case unavailable

        init(_ status: CKAccountStatus) {
            switch status {
            case .available: self = .available
            case .noAccount, .restricted: self = .unavailable
            case .couldNotDetermine, .temporarilyUnavailable: self = .unknown
            @unknown default: self = .unknown
            }
        }
    }

    enum Summary: Equatable {
        case noAccount
        /// A failure that needs the user: full storage or an unknown error.
        case problem(SyncFailure)
        case syncing
        case offline
        case busy
        case synced(Date)
        /// No sync has been observed yet.
        case waiting
    }

    /// Events that have started but not ended. Several can overlap.
    private(set) var running: Set<UUID> = []
    /// End of the latest successful import or export.
    private(set) var lastSuccess: Date?
    /// The latest failure per kind, until a task of that kind succeeds again.
    private(set) var failures: [SyncEventInfo.Kind: SyncFailure] = [:]
    private(set) var account: Account = .unknown

    init(lastSuccess: Date? = nil) {
        self.lastSuccess = lastSuccess
    }

    mutating func apply(_ event: SyncEventInfo) {
        switch event.status {
        case .running:
            running.insert(event.id)
        case .succeeded(let ended):
            running.remove(event.id)
            failures[event.kind] = nil
            // setup only starts the container, no data has moved yet
            if event.kind != .setup, lastSuccess.map({ ended > $0 }) ?? true {
                lastSuccess = ended
            }
        case .failed(let failure):
            running.remove(event.id)
            failures[event.kind] = failure
        case .cancelled:
            running.remove(event.id)
        }
    }

    mutating func setAccount(_ account: Account) {
        self.account = account
    }

    var summary: Summary {
        if account == .unavailable { return .noAccount }

        let kinds: [SyncEventInfo.Kind] = [.setup, .export, .import]  // setup and export hurt most
        let pending = kinds.compactMap { failures[$0] }

        if pending.contains(.noAccount) { return .noAccount }
        if let problem = pending.first(where: { !$0.isTransient }) { return .problem(problem) }
        if !running.isEmpty { return .syncing }
        if pending.contains(.offline) { return .offline }
        if pending.contains(.busy) { return .busy }
        if let lastSuccess { return .synced(lastSuccess) }
        return .waiting
    }
}
