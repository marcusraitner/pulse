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
import OSLog
import PhotosUI

struct SettingsView: View {
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @AppStorage("showStats") private var showStats: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reflectionReminder") private var reflectionReminder: Bool = true
    @AppStorage("reflectionReminderTime") private var reflectionReminderTime: Date =
        Calendar.current.date(bySetting: .hour, value: 20, of: .now) ?? Date.now
    @AppStorage("notificationTime") private var notificationTime: Date = .now
    @AppStorage("backgroundImageData") private var backgroundImageData: Data?
    
    @State private var backgroundImageSelection: PhotosPickerItem?
    @State private var notificationTimes: [Date] = []
    @State private var notificationsAuthorized: Bool = true
    
    @Binding var isPresented: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "SettingsView")

    private let imageFrame: CGFloat = 55
    private let imageSize: CGFloat = 32

    private var backgroundImage: Image? {
        guard let data = backgroundImageData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
    
    var body: some View {
        Form {
            NavigationLink() {
                AboutView()
                    .confirmationToolbarItem($isPresented)
            } label: {
                Label {
                    Text("About")
                } icon: {
                    Image(systemName: "questionmark.circle")
                        .listLabelIcon(.accent)
                }
            }
            
            NavigationLink() {
                Form {
                    Section {
                        VStack(alignment: .leading) {
                            Image(systemName: "gear")
                                .titleLabelIcon(.gray)
                            Text("General")
                                .font(.title2.bold())
                                .padding(.top, 4)
                            Text("Adjust general settings here.")
                                .foregroundStyle(.secondary)
                            
                        }
                        Toggle(isOn: $showStats) {
                            Text("Show Statistics")
                                .font(.headline)
                            Text("Show number of days and entries")
                        }
                        
                        if featureFlags.editHistory {
                            Toggle(isOn: $freezeHistory) {
                                Text("Freeze History")
                                Text("If enabled, entries in the past cannot be modified")
                            }
                        }
                    }
                }
                .confirmationToolbarItem($isPresented)
            } label: {
                Label {
                    Text("General")
                } icon: {
                    Image(systemName: "gear")
                        .listLabelIcon(.gray)
                }
            }
            
            NavigationLink() {
                Form {
                    Section {
                        VStack(alignment: .leading) {
                            Image(systemName: "paintbrush.fill")
                                .titleLabelIcon(.blue)
                            Text("Appearance")
                                .font(.title2.bold())
                                .padding(.top, 4)
                            Text("Customize the overall appearance here.")
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Background Image")
                                .font(.headline)
                            Text("Select a custom background image. Darker backgrounds work best.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            PhotosPicker(selection: $backgroundImageSelection, matching: .images, photoLibrary: .shared()) {
                                if let backgroundImage {
                                    backgroundImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay(alignment: .topTrailing) {
                                            Button(role: .destructive) {
                                                backgroundImageData = nil
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .imageScale(.large)
                                                    .symbolRenderingMode(.hierarchical)
                                                    .foregroundStyle(.white, .blue)
                                                    .shadow(radius: 2)
                                            }
                                            .padding(8)
                                        }
                                } else {
                                    Image("mountain")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay {
                                                Image(systemName: "photo")
                                                    .imageScale(.large)
                                                    .symbolRenderingMode(.hierarchical)
                                                    .foregroundStyle(.white)
                                                    .shadow(radius: 2)
                                        }
                                }
                            }
                        }
                    }
                }
                .confirmationToolbarItem($isPresented)
                
            } label: {
                Label {
                    Text("Appearance")
                } icon: {
                    Image(systemName: "paintbrush.fill")
                        .listLabelIcon(.blue)
                }
            }
            
            NavigationLink() {
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
                                .padding(.vertical, featureFlags.iOS26 ? 0 : 5)
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
                .confirmationToolbarItem($isPresented)
                
            } label: {
                Label {
                    Text("Reminders")
                } icon: {
                    Image(systemName: "bell.badge.fill")
                        .listLabelIcon(.red)
                }

            }
            
            if featureFlags.adminEnabled {
                Section {
                    Text("Danger Zone")
                        .foregroundStyle(Color.red)
                    Button("Seed Samples") {
                        for entry in SampleData.shared.previewSampleData {
                            context.insert(entry)
                        }
                            do {
                                try context.save()
                            } catch {
                                logger.error("Failed saving mock data: \(String(describing: error))")
                            }
                    }
                }
            }
        }
        .onChange(of: backgroundImageSelection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    backgroundImageData = data
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


struct ConfirmButtonModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            isPresented = false
                        }
                    } else {
                        Button("Close") {
                            isPresented = false
                        }
                    }
                }
            }
    }
}
                                    
struct ListLabelIcon: ViewModifier {
    let color: Color
    let iconFrame: CGFloat
    let iconSize: CGFloat
    let cornerRadius: CGFloat
    
    init(color: Color, iconFrame: CGFloat, iconSize: CGFloat, cornerRaduis: CGFloat) {
        self.color = color
        self.iconFrame = iconFrame
        self.iconSize = iconSize
        self.cornerRadius = cornerRaduis
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: iconSize))
            .frame(width: iconFrame, height: iconFrame)
            .foregroundStyle(.white)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func listLabelIcon(_ color: Color) -> some View {
        modifier(ListLabelIcon(color: color, iconFrame: 30, iconSize: 12, cornerRaduis: 8))
    }
    
    func titleLabelIcon(_ color: Color) -> some View {
        modifier(ListLabelIcon(color: color, iconFrame: 55, iconSize: 32, cornerRaduis: 16))
    }
    
    func confirmationToolbarItem(_ isPresented: Binding<Bool>) -> some View {
        modifier(ConfirmButtonModifier(isPresented: isPresented))
    }
}

#Preview {
    NavigationStack {
        SettingsView(isPresented: .constant(true))
    }
}

