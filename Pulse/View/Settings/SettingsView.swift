//
//  Setting.swift
//  collins score
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import UserNotifications
import SwiftData

struct SettingsView: View {
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationTime") private var notificationTime: Date = .now
    @State private var notificationTimes: [Date] = []
    @State private var notificationsAuthorized: Bool = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context

    private let imageFrame: CGFloat = 55
    private let imageSize: CGFloat = 32
    
    var body: some View {
        Form {
            if featureFlags.adminEnabled {
                Section {
                    Text("Danger Zone")
                        .foregroundStyle(Color.red)
                    Button("Seed Samples") {
                        for entry in SampleData.shared.previewSampleData {
                            context.insert(entry)
                        }
                        try? context.save()
                    }
                }
            }
            if featureFlags.editHistory {
                Section {
                    VStack(alignment: .leading) {
                        Image(systemName: "gear")
                            .font(.system(size: imageSize))
                            .frame(width: imageFrame, height: imageFrame)
                            .foregroundStyle(.white)
                            .background(.secondary, in: RoundedRectangle(cornerRadius: 16))
                        Text("General")
                            .font(.title2.bold())
                            .padding(.top, 4)
                        Text("Adjust general settings here.")
                            .foregroundStyle(.secondary)

                    }
                    Toggle(isOn: $freezeHistory) {
                        Text("Freeze History")
                        Text("If enabled, entries in the past cannot be modified")
                    }
                }
            }
            Section {
                VStack(alignment: .leading) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: imageSize))
                        .frame(width: imageFrame, height: imageFrame)
                        .foregroundStyle(.white)
                        .background(.red, in: RoundedRectangle(cornerRadius: 16))
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
        .navigationTitle("Settings")
        .onChange(of: notificationTimes) {
            // update times in UserDefaults
            let defaults = UserDefaults.standard
            defaults.set(notificationTimes, forKey: "notificationTimes")
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsAuthorized = settings.authorizationStatus == .authorized
            let defaults = UserDefaults.standard
            notificationTimes = defaults.array(forKey: "notificationTimes") as? [Date] ?? []
        }
    }
}

#Preview {
    SettingsView()
}
