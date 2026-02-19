//
//  LogEntriesView.swift
//  collins score
//
//  Created by Marcus Raitner on 09.01.26.
//

import SwiftData
import SwiftUI

struct LogEntriesView: View {
    @Bindable var day: DailyEntry
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @Environment(\.featureFlags) private var featureFlags

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack {
            let logs = Binding(
                get: { day.logEntries ?? [] },
                set: { newValue in day.logEntries = newValue }
            )
            
            if isToday || !freezeHistory {
                if #available(iOS 26.0, *) {
                    NewLogEntryView(logEntries: logs)
                        .glassEffect(.regular, in: Rectangle())
                } else {
                    NewLogEntryView(logEntries: logs)
                        .background(.regularMaterial, in: Rectangle())
                }
            }

            List {
                let logEntries = day.logEntries?.sorted(by: {
                    $0.timestamp > $1.timestamp
                }) ?? []
                
                ForEach(logEntries) { entry in
                    LogEntryText(logEntry: entry)
                        .padding(.vertical, featureFlags.iOS26 ? 0 : 5)
                        .listRowBackground(
                            ScoreStyleHelper.color(for: entry.score)
                                .opacity(0.85)
                        )
                        .swipeActions(edge: .trailing) {
                            if isToday || !freezeHistory {
                                Button(role: .destructive) {
                                    day.logEntries?.removeAll(where: {
                                        $0 == entry
                                    })
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .defaultScrollAnchor(.top)
            .listRowSpacing(5)
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

