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
    @AppStorage("theme") var themeName: String = "default"

    var onEntryTapped: (DailyLogEntry) -> Void

    var body: some View {
        let logEntries = day.logEntries?.sorted(by: {
            $0.timestamp < $1.timestamp
        }) ?? []
        
        ForEach(logEntries) { entry in
            LogEntryText(logEntry: entry)
                .padding(.vertical, 15)
                .padding(.horizontal)
                .glassTintedCard(color: ScoreStyleHelper.color(for: entry.score, themeName: themeName))
                .contentShape(Rectangle())
                .onTapGesture {
                    onEntryTapped(entry)
                }
        }
    }
}

struct LogEntriesViewPreview: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries:
        [DailyEntry]

    var body: some View {
        if let entry = entries.first {
            LogEntriesView(day: entry) { _ in }
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

