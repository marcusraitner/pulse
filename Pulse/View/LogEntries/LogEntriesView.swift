//
//  LogEntriesView.swift
//  collins score
//
//  Created by Marcus Raitner on 09.01.26.
//

import SwiftData
import SwiftUI
import OSLog

struct LogEntriesView: View {
    @Bindable var day: DailyEntry
    @State private var logEntry = DailyLogEntry(timestamp: .now, log: "", score: 0)
    @State private var isPresenting: Bool = false
    @State private var isEntryNew: Bool = true
    @StateObject private var themeStore: ThemeStore = .init()
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "LogEntriesView")
    
    var body: some View {
        NavigationStack {
            VStack {
                
                let logEntries = day.logEntries?.sorted(by: {
                    $0.timestamp < $1.timestamp
                }) ?? []
                    
                ForEach(logEntries) { entry in
                    if #available(iOS 26.0, *) {
                        LogEntryText(logEntry: entry)
                            .padding(.vertical, 15)
                            .padding(.horizontal)
                            .glassEffect(.clear.tint(ScoreStyleHelper.color(for: entry.score, store: themeStore)).interactive(), in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                logEntry = entry
                                isEntryNew = false
                                isPresenting = true
                            }
                    } else {
                        LogEntryText(logEntry: entry)
                            .padding(.vertical, 15)
                            .padding(.horizontal)
                            .background(ScoreStyleHelper.color(for: entry.score, store: themeStore)
                                .opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                logEntry = entry
                                isEntryNew = false
                                isPresenting = true
                            }
                    }
                }
            }
            .sheet(isPresented: $isPresenting) {
                NavigationStack {
                    LogEntrySheet(entry: $logEntry, isEntryNew: $isEntryNew) { editedEntry in
                        // Only commit changes here when the user taps Submit in the sheet
                        if isEntryNew {
                            // Append to the day's entries if creating new
                            if day.logEntries == nil {
                                day.logEntries = []
                            }
                            day.logEntries?.append(editedEntry)
                        } else {
                            logEntry.log = editedEntry.log
                            logEntry.score = editedEntry.score
                        }
                        do {
                            try context.save()
                        } catch {
                            logger.error("Failed saving edited entry: \(String(describing: error))")
                        }
                        isPresenting = false
                    }
                }
                
            }
        }
    }
}

struct LogEntriesViewPreview: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries:
        [DailyEntry]

    var body: some View {
        if let entry = entries.first {
            LogEntriesView(day: entry)
        } else {
            Text("No sample data available")
                .padding()
        }
    }
}

#Preview {
    LogEntriesViewPreview()
        .modelContainer(SampleData.shared.modelContainer)
}

