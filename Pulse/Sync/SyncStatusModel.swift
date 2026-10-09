//
//  SyncStatusModel.swift
//  Pulse
//
//  Created by Marcus Raitner on 05.10.26.
//

import CloudKit
import Foundation

// Pure state for the iCloud sync status row. No framework objects are kept, so every rule
// here can be unit tested. `ICloudSyncMonitor` feeds it with what CloudKit reports.
// The types are `nonisolated` because they are plain values, not UI state.

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
        /// iCloud storage is full, so changes can't be saved until space is freed.
        case storageFull
        /// An error that isn't recognised, with CloudKit's description of it.
        case problem(String)
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
        switch pending.first(where: { !$0.isTransient }) {
        case .storageFull: return .storageFull
        case .other(let message): return .problem(message)
        case .noAccount, .offline, .busy, nil: break  // handled above, or not a problem
        }
        if !running.isEmpty { return .syncing }
        if pending.contains(.offline) { return .offline }
        if pending.contains(.busy) { return .busy }
        if let lastSuccess { return .synced(lastSuccess) }
        return .waiting
    }
}
