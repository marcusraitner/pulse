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
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @AppStorage("showStats") private var showStats: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reflectionReminder") private var reflectionReminder: Bool = true
    @AppStorage("reflectionReminderTime") private var reflectionReminderTime: Date =
        Calendar.current.date(bySetting: .hour, value: 20, of: .now) ?? Date.now
    @AppStorage("notificationTime") private var notificationTime: Date = .now
    @AppStorage("backgroundImageData") private var backgroundImageData: Data?
    @AppStorage("storeLocations") private var storeLocations: Bool = false
    
    @State private var backgroundImageSelection: PhotosPickerItem?
    @State private var notificationTimes: [Date] = []
    @State private var notificationsAuthorized: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context
    
    private let localLocationManager = CLLocationManager()
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "SettingsView")

    private let imageFrame: CGFloat = 55
    private let imageSize: CGFloat = 32

    private var backgroundImage: Image? {
        guard let data = backgroundImageData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
    
    private var countDays: Int {
        var descriptor = FetchDescriptor<DailyEntry>(predicate: #Predicate { _ in true })
        descriptor.includePendingChanges = true
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    private var countLogs: Int {
        var descriptor = FetchDescriptor<DailyLogEntry>(predicate: #Predicate { _ in true })
        descriptor.includePendingChanges = true
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    var body: some View {
        Form {
            //General Section
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
                        Toggle(isOn: $storeLocations) {
                            Text("Store Locations")
                            Text("Allow saving your location with entries")
                        }
                        .onChange(of: storeLocations) { oldValue, newValue in
                            if newValue {
                                switch localLocationManager.authorizationStatus {
                                case .notDetermined:
                                    localLocationManager.requestWhenInUseAuthorization()
                                case .denied, .restricted:
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                default:
                                    break
                                }
                            }
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
            // Appearance Section
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
                
            } label: {
                Label {
                    Text("Appearance")
                } icon: {
                    Image(systemName: "paintbrush.fill")
                        .listLabelIcon(.blue)
                }
            }
            // Reminders Section
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
            // Location Section
            NavigationLink() {
                Form {
                    Section {
                        VStack(alignment: .leading) {
                            Image(systemName: "location.fill")
                                .titleLabelIcon(.blue)
                            Text("Location")
                                .font(.title2.bold())
                                .padding(.top, 4)
                            Text("Automatically store location with your entries.")
                                .foregroundStyle(.secondary)
                        }
                        
                        switch localLocationManager.authorizationStatus {
                        case .authorizedAlways, .authorizedWhenInUse:
                            Toggle(isOn: $storeLocations) {
                                Text("Store location")
                                Text("Your current location is stored with your moments.")
                            }
                        case .notDetermined:
                            Button("Enable location access") {
                                localLocationManager.requestWhenInUseAuthorization()
                            }
                        case .denied, .restricted:
                            Text("Location services are disabled. Please open settings to enable location services.")
                            
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                Button("Open Settings") {
                                    UIApplication.shared.open(url)
                                }
                                .listRowSeparator(.hidden)
                            }
                        @unknown default:
                            fatalError()
                        }
                        
                    }
                    
                }
            } label: {
                Label {
                    Text("Location")
                } icon: {
                    Image(systemName: "location.fill")
                        .listLabelIcon(.blue)
                }

            }
            
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
    
//    func confirmationToolbarItem() -> some View {
//        modifier(ConfirmButtonModifier())
//    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

