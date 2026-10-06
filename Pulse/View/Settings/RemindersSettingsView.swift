//
//  RemindersSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct RemindersSettingsView: View {

    @AppStorage(AppStorageKeys.notificationsEnabled) private var notificationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminder) private var reflectionReminder: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminderTime) private var reflectionReminderTime: Date =
        Calendar.current.date(bySetting: .hour, value: 20, of: .now) ?? Date.now

    @State private var reminders: [ReminderTime] = []
    @State private var notificationsAuthorized: Bool = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Image(systemName: "bell.badge.fill")
                        .titleLabelIcon(.red)
                    Text("Reminders")
                        .font(.title2.bold())
                        .padding(.top, 4)
                    Text("Set multiple daily reminders to log what's happening and how you feel about it.")
                        .foregroundStyle(.secondary)
                }
                if notificationsAuthorized {
                    Toggle(isOn: $notificationsEnabled) {
                        Text("Enable reminders")
                    }
                } else {
                    Text("Notifications are currently disabled. Please open settings to enable them.")
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Button("Open Settings") {
                            UIApplication.shared.open(url)
                            // turn notifications on here, such that they are enabled when user returns
                            notificationsEnabled = true
                            dismiss()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            if notificationsAuthorized && notificationsEnabled {
                Section("Daily Reflection Reminder") {
                    Toggle(isOn: $reflectionReminder) {
                        Text("Get a reminder every evening to reflect on your day")
                    }
                    if reflectionReminder {
                        DatePicker("Reminder for daily reflection",
                                   selection: $reflectionReminderTime,
                                   displayedComponents: [.hourAndMinute])
                    }
                }
                Section("Your Reminders") {
                    ForEach($reminders) { $reminder in
                        DatePicker("Every day at",
                                   selection: $reminder.time,
                                   displayedComponents: [.hourAndMinute])
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                reminders.removeAll { $0.id == reminder.id }
                            }
                            .labelStyle(.iconOnly)
                        }
                    }

                    Button("Add reminder") {
                        reminders.append(ReminderTime(time: .now))
                    }
                }
            }
        }
        .onChange(of: reminders) {
            UserDefaults.standard.set(reminders.map(\.time), forKey: AppStorageKeys.notificationTimes)
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsAuthorized = settings.authorizationStatus == .authorized
            let times = UserDefaults.standard.array(forKey: AppStorageKeys.notificationTimes) as? [Date] ?? []
            reminders = times.map { ReminderTime(time: $0) }
        }
    }
}

#Preview {
    NavigationStack {
        RemindersSettingsView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
