//
//  ContentView.swift
//  collins score
//
//  Created by Marcus Raitner on 20.04.25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingAbout: Bool = false
    
    private var today: DailyEntry {
        // create today's entry if missing
        updateToday()
        // allEntries now contains at least today's entry
        return allEntries.last!
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("mountain")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .brightness(-0.1)
                
                VStack {
                    dateView
                    
                    TimeLineView(allEntries: allEntries, selectedEntry: $selectedEntry)
                        .padding(.vertical)
                        .padding(.bottom, 10)
                    
                    LogEntriesView(day: selectedEntry)
                }
            }
            .sheet(isPresented: $isPresentingAbout) {
                NavigationStack {
                    AboutView()
                        .toolbar {
                            ToolbarItem (placement: .topBarLeading) {
                                if #available(iOS 26, *) {
                                    Button(role: .confirm) {
                                        isPresentingAbout = false
                                    }
                                } else {
                                    Button("Close") {
                                        isPresentingAbout = false
                                    }
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $isPresentingSettings, onDismiss: setNotifications) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem (placement: .confirmationAction) {
                                if #available(iOS 26, *) {
                                    Button(role: .confirm) {
                                        isPresentingSettings = false
                                    }
                                } else {
                                    Button("Close") {
                                        isPresentingSettings = false
                                    }
                                }
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings", systemImage: "gearshape.fill") {
                        isPresentingSettings = true
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button("About", systemImage: "line.3.horizontal") {
                        isPresentingAbout = true
                    }
                }
            }
            .task {
                // Request authorization for notifications
                do {
                    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                } catch {
                    print(error.localizedDescription)
                }
            }
            .onChange(of: allEntries, initial: true) {
                // allEntries changes when a new day is added; let's scroll to it
                selectedEntry = today
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    // create today entry if missing
                    updateToday()
                }
            }
        }
    }
    
    private func setNotifications() {
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Set new notifications based on user's choice
        if notificationsEnabled {
            let defaults = UserDefaults.standard
            let notificationTimes = defaults.value(forKey: "notificationTimes") as? [Date] ?? []
            
            for time in notificationTimes {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "What's going on?")
                content.body = String(localized: "It's time to log your activities and feelings!")
                content.sound = .default
                
                let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                let dateTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: dateTrigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func updateToday() {
        if let entry = allEntries.last {
            if Calendar.current.isDateInToday(entry.date) {
                return
            }
        }
        
        // entry for today missing: create and save it
        let today = DailyEntry(date: .now)
        context.insert(today)
        try? context.save()
    }
    
    private var dateView: some View {
        HStack {
            VStack(alignment: .center) {
                Text(
                    selectedEntry.date.formatted(
                        .dateTime.day().month().year().weekday(.wide)
                    )
                )
            }
            .font(.system(.title, design: .serif).bold())
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical)
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
