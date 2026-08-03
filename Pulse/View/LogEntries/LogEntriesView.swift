//
//  LogEntriesView.swift
//  collins score
//
//  Created by Marcus Raitner on 09.01.26.
//

import SwiftData
import SwiftUI

/// Displays all log entries for a single day as a vertical list of theme-tinted glass cards.
struct LogEntriesView: View {
    let day: DailyEntry
    @State private var entryToEdit: DailyLogEntry? = nil

    @AppStorage(AppStorageKeys.theme) var themeName: String = "traffic"

    var body: some View {
        let logEntries = day.logEntries?.sorted(by: {
            $0.timestamp < $1.timestamp
        }) ?? []
        
        ForEach(logEntries) { entry in
            LogEntryText(logEntry: entry)
                .padding(.vertical, 15)
                .padding(.horizontal)
                .glassTintedCard(color: Theme.named(themeName).color(for: entry.score))
                .contentShape(Rectangle())
                .onTapGesture {
                    entryToEdit = entry
                }
        }
        .sheet(item: $entryToEdit) { entry in
            NavigationStack {
                LogEntrySheet(day: day, entry: entry)
            }
            .presentationDetents([.large])
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
        .preferredColorScheme(.dark)
}

