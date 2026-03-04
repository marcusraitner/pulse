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
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "LogEntriesView")

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
//                if isToday || !freezeHistory {
//                    if #available(iOS 26.0, *) {
//                        Button(action: { isEntryNew = true; isPresenting = true } ) {
//                            Image(systemName: "plus")
//                                .font(.largeTitle)
//                                .padding()
//                                .glassEffect(.regular, in: Circle())
//                        }
//                        .buttonStyle(.plain)
//                        .padding(.bottom)
//                    } else {
//                        Button(action: { isEntryNew = true; isPresenting = true } ) {
//                            Image(systemName: "plus")
//                                .font(.largeTitle)
//                                .padding()
//                                .background(.regularMaterial, in: Circle())
//                        }
//                        .buttonStyle(.plain)
//                        .padding(.bottom)
//                    }
//                }
                
                let logEntries = day.logEntries?.sorted(by: {
                    $0.timestamp < $1.timestamp
                }) ?? []
                    
                ForEach(logEntries) { entry in
                    LogEntryText(logEntry: entry)
                        .padding()
                        .background(ScoreStyleHelper.color(for: entry.score)
                            .opacity(0.85))
                        .onTapGesture {
                            if (isToday || !freezeHistory) {
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

