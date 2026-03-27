//
//  NotificationScheduler.swift
//  Pulse
//
//  Created by Marcus Raitner on 27.03.26.
//

import OSLog
import Foundation
import UserNotifications

/// Manages scheduling of local notifications for log reminders and the daily reflection reminder.
struct NotificationScheduler {
    private static let logger = Logger(subsystem: "de.raitner.pulse", category: "NotificationScheduler")

    /// Builds and schedules a single repeating daily calendar notification.
    /// - Parameters:
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - url: Deep-link URL string stored in `userInfo["url"]`, used to navigate on tap.
    ///   - time: The time of day at which the notification fires.
    private static func scheduleNotification(title: String, body: String, url: String, at time: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["url": url]
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    /// Clears all pending notifications and reschedules them from the current settings.
    /// Runs asynchronously inside a `Task`; the caller does not need to `await`.
    /// - Parameters:
    ///   - notificationsEnabled: Whether log reminder notifications are enabled.
    ///   - notificationTimes: Times of day at which log reminders should fire.
    ///   - reflectionReminder: Whether the daily reflection reminder is enabled.
    ///   - reflectionReminderTime: Time of day for the reflection reminder, if enabled.
    static func setNotifications(
        notificationsEnabled: Bool,
        notificationTimes: [Date],
        reflectionReminder: Bool,
        reflectionReminderTime: Date?
    ) {
        Task {
            // Remove all pending notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

            // Set new notifications based on user's choice
            if notificationsEnabled {
                for time in notificationTimes {
                    do {
                        try await scheduleNotification(
                            title: String(localized: "What's going on?"),
                            body: String(localized: "It's time to log your activities and feelings!"),
                            url: "pulseapp://log",
                            at: time
                        )
                    } catch {
                        logger.error("Failed to schedule notification: \(String(describing: error))")
                    }
                }

                if reflectionReminder, let reflectionReminderTime {
                    do {
                        try await scheduleNotification(
                            title: String(localized: "Reflection Time"),
                            body: String(localized: "It's time to reflect on your day!"),
                            url: "pulseapp://reflect",
                            at: reflectionReminderTime
                        )
                    } catch {
                        logger.error("Failed to schedule notification: \(String(describing: error))")
                    }
                }
            }
        }
    }

}
