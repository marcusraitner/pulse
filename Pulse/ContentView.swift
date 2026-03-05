//
//  ContentView.swift
//  collins score
//
//  Created by Marcus Raitner on 20.04.25.
//

import OSLog
import SwiftData
import SwiftUI
import StoreKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.requestReview) private var requestReview
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @AppStorage("showStats") private var showStats: Bool = true
    @AppStorage("lastReviewRequest") private var lastReviewRequest: Int = 0
    @AppStorage("numberOfRequests") private var numberOfRequests: Int = 0
    
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var today: DailyEntry = DailyEntry(date: .now)
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingAbout: Bool = false
    @State private var isPresentingNewEntry: Bool = false
    @State private var isPresentingReflection: Bool = false
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "ContentView")

    private var countDays: Int {
        var descriptor = FetchDescriptor<DailyEntry>(predicate: #Predicate { _ in true })
        descriptor.includePendingChanges = true
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    private var countLog: Int {
        var descriptor = FetchDescriptor<DailyLogEntry>(predicate: #Predicate { _ in true })
        descriptor.includePendingChanges = true
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack {
                        dateView
                        
                        TimeLineView(selectedEntry: $selectedEntry)
                            .padding(.vertical)
                            .padding(.bottom, 10)
                        
                        if selectedEntry.summary.isEmpty {
                            if #available(iOS 26.0, *) {
                                Button(action: { isPresentingReflection = true }) {
                                    Text("Reflect Your Day")
                                        .foregroundStyle(.white)
                                        .font(.title3)
                                        .padding()
                                        .glassEffect(.clear, in: Capsule())

                                }
                                .padding(.vertical)
                                .buttonStyle(.plain)

                            } else {
                                Button(action: { isPresentingReflection = true }) {
                                    Text("Reflect Your Day")
                                        .padding(10)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical)
                            }
                        } else {
                            if #available(iOS 26.0, *) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Reflection")
                                            .font(.title3)
                                            .padding(.bottom, 5)
                                        Text(selectedEntry.summary)
                                        
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    Spacer()
                                }
                                .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 5)
                                .contentShape(Rectangle())
                                .onTapGesture(perform: { isPresentingReflection = true } )
                            } else {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Reflection")
                                            .font(.title3)
                                            .padding(.bottom, 5)
                                        Text(selectedEntry.summary)
                                        
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    Spacer()
                                }
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 5)
                                .contentShape(Rectangle())
                                .onTapGesture(perform: { isPresentingReflection = true } )
                            }
                        }
                        

                        LogEntriesView(day: selectedEntry)
                            .padding(.horizontal, 5)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea(.keyboard)
                .sheet(isPresented: $isPresentingAbout) {
                    aboutSheetStack
                }
                .sheet(
                    isPresented: $isPresentingSettings,
                    onDismiss: setNotifications
                ) {
                    settingsSheetStack
                }
                .sheet(isPresented: $isPresentingNewEntry) {
                    NavigationStack {
                        LogEntrySheet() { editedEntry in
                                
                            if selectedEntry.logEntries == nil {
                                selectedEntry.logEntries = []
                            }
                            selectedEntry.logEntries?.append(editedEntry)
                            
                            do {
                                try context.save()
                            } catch {
                                logger.error("Failed saving edited entry: \(String(describing: error))")
                            }
                            
                            isPresentingNewEntry = false
                        }
                    }
                }
                .sheet(isPresented: $isPresentingReflection, onDismiss: { isPresentingReflection = false } ) {
                    NavigationStack {
                        DailyReflectionSheet(day: $selectedEntry)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape.fill") {
                            isPresentingSettings = true
                        }
                        .tint(.white)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("About", systemImage: "line.3.horizontal") {
                            isPresentingAbout = true
                        }
                        .tint(.white)
                    }
                    ToolbarItem(placement: .principal) {
                        if showStats {
                            HStack {
                                VStack {
                                    Image(systemName: "calendar")
                                    Text("\(countDays)")
                                }
                                VStack {
                                    Image(systemName: "list.bullet.rectangle")
                                    Text("\(countLog)")
                                }
                                .padding(.leading, 4)
                            }
                            .font(.footnote)
                            .foregroundStyle(.white)
                        }
                    }
                    if featureFlags.adminEnabled {
                        ToolbarItem(placement: .bottomBar) {
                            Button("Delete Entry", systemImage: "trash") {
                                context.delete(selectedEntry)
                                do {
                                    try context.save()
                                } catch {
                                    logger.error("Failed saving deleted entry: \(String(describing: error))")
                                }
                            }
                            .tint(.white)
                        }
                    }
                }
                .task {
                    await initApplication()
                }
                .onChange(of: countLog) { old, new in
                    if new > old && numberOfRequests < 3 && countLog > lastReviewRequest + (5 * (numberOfRequests + 1)) {
                        presentReview()
                        numberOfRequests += 1
                        lastReviewRequest = countLog
                    }
                }
               
                // The Add Button
                if Calendar.current.isDateInToday(selectedEntry.date) || !freezeHistory {
                    if #available(iOS 26.0, *) {
                        Button(action: { isPresentingNewEntry = true } ) {
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .padding()
                                .glassEffect(.clear, in: Circle())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                    } else {
                        Button(action: { isPresentingNewEntry = true } ) {
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .padding()
                                .background(.regularMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background {
                GeometryReader { geo in
                    Image(colorScheme == .dark ? "mountain-dark" : "mountain")
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .brightness(colorScheme == .dark ? 0.0 : -0.1)
                        .ignoresSafeArea(.all)
                }
            }
#if DEBUG
            // Expose an accessibility identifier
            .accessibilityIdentifier("dateView")
            // and a values containing the selectedEntry for UI Tests
            .accessibilityValue(
                Text("selectedEntry:\(DateFormatHelper.formatDate(selectedEntry.date))")
            )
#endif  // DEBUG only for UI Tests
        }
        
    }

    private func initApplication() async {

        #if DEBUG
            let args = ProcessInfo.processInfo.arguments

            if args.contains("--disable-animations") {
                UIView.setAnimationsEnabled(false)
            }
        #endif  // DEBUG only for testing

        if !featureFlags.editHistory {
            // make sure, that history is frozen if feature is disabled
            freezeHistory = true
        }
        
        // Request authorization for notifications
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound])
        } catch {
            logger.error("Error NotificationCenter: \(error.localizedDescription)")
        }
    }

    private func setNotifications() {
        // Remove all pending notifications
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()

        // Set new notifications based on user's choice
        if notificationsEnabled {
            let defaults = UserDefaults.standard
            let notificationTimes =
                defaults.value(forKey: "notificationTimes") as? [Date] ?? []

            for time in notificationTimes {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "What's going on?")
                content.body = String(
                    localized: "It's time to log your activities and feelings!"
                )
                content.sound = .default

                let components = Calendar.current.dateComponents(
                    [.hour, .minute],
                    from: time
                )
                let dateTrigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: dateTrigger
                )

                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func presentReview() {
        Task {
            // Delay for two seconds to avoid interrupting the person using the app.
            try await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
    
    private var dateView: some View {
        HStack {
            VStack(alignment: .center) {
                Text(selectedEntry.date.formatted(.dateTime.weekday(.wide)))
                Text(
                    selectedEntry.date.formatted(
                        .dateTime.day().month(.wide).year()
                    )
                )
            }
            .font(.system(.title, design: .serif).bold())
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical)
    }
    
    private var aboutSheetStack: some View {
        NavigationStack {
            AboutView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
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
    
    private var settingsSheetStack: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
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
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
