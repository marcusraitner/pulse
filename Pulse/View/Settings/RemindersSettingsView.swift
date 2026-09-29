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

    @State private var notificationTimes: [Date] = []
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
                    List(notificationTimes.indices, id: \.self) { index in
                        DatePicker("Every day at",
                                   selection: $notificationTimes[index],
                                   displayedComponents: [.hourAndMinute])
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                notificationTimes.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }

                    Button("Add reminder") {
                        notificationTimes.append(.now)
                    }
                }
            }
        }
        .onChange(of: notificationTimes) {
            UserDefaults.standard.set(notificationTimes, forKey: AppStorageKeys.notificationTimes)
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsAuthorized = settings.authorizationStatus == .authorized
            notificationTimes = UserDefaults.standard.array(forKey: AppStorageKeys.notificationTimes) as? [Date] ?? []
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
