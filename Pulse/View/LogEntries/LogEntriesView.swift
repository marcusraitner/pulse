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
    @AppStorage(AppStorageKeys.sortAscending) private var sortAscending: Bool = true
    @Environment(FilterState.self) private var filterState
    
    var filteredAndSortedEntries: [DailyLogEntry] {
        if filterState.isFilterActive, let selectedTag = filterState.selectedTag {
            return day.logEntries?.filter( { $0.tagsRaw.contains(selectedTag) } )
                .sorted(by: {
                    sortAscending ? $0.timestamp < $1.timestamp
                    : $0.timestamp > $1.timestamp
                } ) ?? []
        } else {
            return day.logEntries?.sorted(by: {
                sortAscending ? $0.timestamp < $1.timestamp
                : $0.timestamp > $1.timestamp
            } ) ?? []
        }
    }
    
    var body: some View {
        ForEach(filteredAndSortedEntries) { entry in
            LogEntryText(logEntry: entry)
                .padding(.vertical, 15)
                .padding(.horizontal)
                .glassEffect(.regular.tint(Theme.named(themeName).color(for: entry.score).mix(with: .black, by: 0.35).opacity(0.5)).interactive(), in: RoundedRectangle(cornerRadius: 10))
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

