//
//  Constants.swift
//  Pulse
//
//  Created by Marcus Raitner on 27.03.26.
//

import Foundation

/// Keys for values persisted in `UserDefaults` / `@AppStorage`.
/// Centralised here to prevent typos and make future renaming safe.
enum AppStorageKeys {
    // MARK: - Notifications
    static let notificationsEnabled = "notificationsEnabled"
    static let notificationTimes = "notificationTimes"
    static let reflectionReminder = "reflectionReminder"
    static let reflectionReminderTime = "reflectionReminderTime"

    // MARK: - Display
    static let freezeHistory = "freezeHistory"
    static let showStats = "showStats"
    static let theme = "theme"
    static let backgroundImageData = "backgroundImageData"
    static let backgroundImageName = "backgroundImageName"

    // MARK: - KPI
    static let pinnedKPITemplateIDs = "pinnedKPITemplateIDs"

    // MARK: - Review
    static let lastReviewRequest = "lastReviewRequest"
    static let numberOfRequests = "numberOfRequests"
}
