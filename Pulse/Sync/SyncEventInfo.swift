//
//  SyncEventInfo.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import CoreData

// A plain value, `nonisolated` like the other sync status types; see SyncStatusModel.swift.

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
