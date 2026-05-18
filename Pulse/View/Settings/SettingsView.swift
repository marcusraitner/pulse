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
import UIKit

struct SettingsView: View {
    @AppStorage(AppStorageKeys.enableEditingHistory) private var enableEditingHistory: Bool = false
    @AppStorage(AppStorageKeys.notificationsEnabled) private var notificationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminder) private var reflectionReminder: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminderTime) private var reflectionReminderTime: Date =
        Calendar.current.date(bySetting: .hour, value: 20, of: .now) ?? Date.now
    @AppStorage(AppStorageKeys.backgroundImageData) private var backgroundImageData: Data?
    @AppStorage(AppStorageKeys.backgroundImageName) private var backgroundImageName: String = "mountain"
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"
    
    @State private var backgroundImageSelection: PhotosPickerItem?
    @State private var notificationTimes: [Date] = []
    @State private var notificationsAuthorized: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "SettingsView")

    private var backgroundImage: Image? {
        guard let data = backgroundImageData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
    
    @Query private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]
    @Query private var allKPIValues: [DailyKPIValue]
    @Query private var allTags: [Tag]
    @Query private var allKPIs: [KPITemplate]
    
    private var countDays: Int { allEntries.count }
    private var countLogs: Int { allLogs.count }

    // MARK: - Body

    var body: some View {
        Form {
            // MARK: General
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
                        
                        Toggle(isOn: $enableEditingHistory) {
                            Text("Edit past days and moments")
                            Text("Enable this option to be able to add, delete, or edit moments for past days.")
                            
                        }
                    }
                    .task {
                        // A small migration step to transfer the old `freezeHistory` setting to the new one
                        if let freezeHistory = UserDefaults.standard.value(forKey: AppStorageKeys.freezeHistory) {
                            enableEditingHistory = !(freezeHistory as! Bool)
                            UserDefaults.standard.removeObject(forKey: AppStorageKeys.freezeHistory)
                        }
                    }
                }
            } label: {
                Label {
                    Text("General")
                } icon: {
                    Image(systemName: "gear")
                        .listLabelIcon(.gray)
                }
            }
            // MARK: Appearance
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
                        Picker(selection: $themeName) {
                            ForEach(Theme.builtIn) { theme in
                                ThemePreview(theme)
                                    .tag(theme.id)
                            }
                        } label: {
                            Text("Theme: ")
                        }
                        .pickerStyle(.navigationLink)
                        
                        let columns: [GridItem] = [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Background Image")
                                .font(.headline)
                            Text("Select a custom background image. Darker backgrounds work best.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                        
                            LazyVGrid(columns: columns, spacing: 8) {
                                let presets = ["mountain", "mountain-dark", "clouds", "moon", "stars"]
                                
                                ForEach(presets, id: \.self) { imageName in
                                    Image("\(imageName)-thumb")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()
                                        .contentShape(Rectangle())
                                        .cornerRadius(12)
                                        .onTapGesture {
                                            backgroundImageName = imageName
                                            backgroundImageData = nil
                                        }
                                        .overlay(alignment: .bottomTrailing) {
                                            if imageName == backgroundImageName && backgroundImageData == nil {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.white, .blue)
                                                    .padding(8)
                                            }
                                        }
                                }
                                
                                PhotosPicker(selection: $backgroundImageSelection, matching: .images, photoLibrary: .shared()) {
                                    if let backgroundImage {
                                        backgroundImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 120)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .cornerRadius(12)
                                            .overlay(alignment: .bottomTrailing) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.white, .blue)
                                                    .padding(8)
                                            }
                                    } else {
                                        Image("mountain")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 120)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .cornerRadius(12)
                                            .saturation(0.2)
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
                }
                
            } label: {
                Label {
                    Text("Appearance")
                } icon: {
                    Image(systemName: "paintbrush.fill")
                        .listLabelIcon(.blue)
                }
            }
            // MARK: Metrics
            NavigationLink() {
                KPITemplatesSettingsView()
            } label: {
                Label {
                    Text("Metrics")
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .listLabelIcon(.orange)
                }
            }
            
            // --- MARK: Tags
            NavigationLink() {
                TagSettingsView()
            } label: {
                Label {
                    Text("Tags")
                } icon: {
                    Image(systemName: "tag.circle.fill")
                        .listLabelIcon(.teal)
                }
            }            
            // MARK: Reminders
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
            } label: {
                Label {
                    Text("Reminders")
                } icon: {
                    Image(systemName: "bell.badge.fill")
                        .listLabelIcon(.red)
                }

            }
            
            // MARK: About & Statistics
            Section {
                NavigationLink() {
                    AboutView()
                } label: {
                    Label {
                        Text("About")
                    } icon: {
                        Image("AppIcon-iOS-Default")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
                
                NavigationLink() {
                    List {
                        Section {
                            VStack(alignment: .leading) {
                                Image(systemName: "chart.bar.horizontal.page.fill")
                                    .titleLabelIcon(.gray)
                                Text("Statistics")
                                    .font(.title2.bold())
                                    .padding(.top, 4)
                                Text("See your current statistics here.")
                                    .foregroundStyle(.secondary)
                                
                            }
                        }
                        HStack {
                            Text("Number of days")
                            Spacer()
                            Text("\(countDays)")
                        }
                        HStack {
                            Text("Number of moments")
                            Spacer()
                            Text("\(countLogs)")
                        }
                    }
                } label: {
                    Label {
                        Text("Statistics")
                    } icon: {
                        Image(systemName: "chart.bar.horizontal.page.fill")
                            .listLabelIcon(.gray)
                    }
                }
            }
            
            // MARK: Admin
            if featureFlags.adminEnabled {
                Section {
                    Text("Danger Zone")
                        .foregroundStyle(Color.red)
                    Button("Seed Samples") {
                        for log in allLogs {
                            context.delete(log)
                        }
                        for value in allKPIValues {
                            context.delete(value)
                        }
                        for entry in allEntries {
                            context.delete(entry)
                        }
                        for template in allKPIs {
                            context.delete(template)
                        }
                        for tag in allTags {
                            context.delete(tag)
                        }
                        context.saveOrLog("Failed to clear existing data before seeding mock data", logger: logger)
                        
                        let seedLanguage = SampleData.SeedLanguage.current
                        let templates = SampleData.makeSeedTemplates(language: seedLanguage)
                        
                        for template in templates {
                            context.insert(template)
                        }
                        
                        for tag in SampleData.makeSeedTags(language: seedLanguage) {
                            context.insert(tag)
                        }
                        
                        for entry in SampleData.makeSeedEntries(templates: templates, language: seedLanguage) {
                            context.insert(entry)
                        }
                        
                        context.saveOrLog("Failed to save mock data", logger: logger)
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
            UserDefaults.standard.set(notificationTimes, forKey: AppStorageKeys.notificationTimes)
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsAuthorized = settings.authorizationStatus == .authorized
            notificationTimes = UserDefaults.standard.array(forKey: AppStorageKeys.notificationTimes) as? [Date] ?? []
        }
    }
}
                                    
// MARK: - ListLabelIcon

struct ListLabelIcon: ViewModifier {
    let color: Color
    let iconFrame: CGFloat
    let iconSize: CGFloat
    let cornerRadius: CGFloat
    
    init(color: Color, iconFrame: CGFloat, iconSize: CGFloat, cornerRadius: CGFloat) {
        self.color = color
        self.iconFrame = iconFrame
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
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
        modifier(ListLabelIcon(color: color, iconFrame: 30, iconSize: 12, cornerRadius: 8))
    }
    
    func titleLabelIcon(_ color: Color) -> some View {
        modifier(ListLabelIcon(color: color, iconFrame: 55, iconSize: 32, cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
