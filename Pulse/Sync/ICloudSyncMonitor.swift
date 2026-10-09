//
//  ICloudSyncMonitor.swift
//  Pulse
//
//  Created by Marcus Raitner on 05.10.26.
//

import CloudKit
import CoreData
import Observation
import OSLog

/// Watches what CloudKit reports about syncing and feeds `SyncStatusModel`.
///
/// Create and `start()` it before the `ModelContainer`, so setup and the first import at launch
/// are not missed. The time of the last successful sync is kept in `UserDefaults`, so the status
/// is not blank after a restart.
///
/// CloudKit only reports on its own import and export tasks; it can't say whether another
/// device is up to date. That is why the UI shows a time and never claims "in sync".
@Observable
final class ICloudSyncMonitor {
    private(set) var model: SyncStatusModel

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var isStarted = false
    @ObservationIgnored private let logger = Logger(subsystem: "de.raitner.pulse", category: "ICloudSyncMonitor")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        model = SyncStatusModel(lastSuccess: defaults.object(forKey: AppStorageKeys.lastSuccessfulSync) as? Date)
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event
            guard let info = event.flatMap({ SyncEventInfo($0) }) else { return }
            MainActor.assumeIsolated { self?.apply(info) }
        })

        // CKAccountChanged is not posted when nothing changed, so the status is also read once now
        observers.append(center.addObserver(forName: .CKAccountChanged, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.refreshAccountStatus() }
        })
        Task { await refreshAccountStatus() }
    }

    private func apply(_ info: SyncEventInfo) {
        let lastSuccessBefore = model.lastSuccess
        model.apply(info)

        if case .failed(.other(let message)) = info.status {
            logger.error("Unrecognised sync error: \(message, privacy: .public)")
        }
        if model.lastSuccess != lastSuccessBefore {
            defaults.set(model.lastSuccess, forKey: AppStorageKeys.lastSuccessfulSync)
        }
    }

    private func refreshAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            model.setAccount(SyncStatusModel.Account(status))
        } catch {
            logger.error("Could not read the iCloud account status: \(error.localizedDescription, privacy: .public)")
        }
    }
}
