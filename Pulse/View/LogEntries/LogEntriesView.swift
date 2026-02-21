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
    @State private var newLogEntry = DailyLogEntry(timestamp: .now, log: "", score: 0)
    @State private var isPresenting: Bool = false
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @Environment(\.featureFlags) private var featureFlags

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    private func saveNewLog() {
        if !newLogEntry.log.isEmpty {
            newLogEntry.timestamp = .now
            day.logEntries?.append(newLogEntry)
            newLogEntry = DailyLogEntry(timestamp: .now, log: "", score: 0)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isToday || !freezeHistory {
                    if #available(iOS 26.0, *) {
                        Button(action: { isPresenting = true } ) {
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .padding()
                                .glassEffect(.regular, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom)
                    } else {
                        Button(action: { isPresenting = true } ) {
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .padding()
                                .background(.regularMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom)
                    }
                }
                
                List {
                    let logEntries = day.logEntries?.sorted(by: {
                        $0.timestamp < $1.timestamp
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
            .sheet(isPresented: $isPresenting, onDismiss: saveNewLog) {
                NavigationStack {
                    NewLogEntrySheet(newEntry: $newLogEntry)
                        .toolbar {
                            ToolbarItem (placement: .confirmationAction) {
                                if #available(iOS 26, *) {
                                    Button(role: .confirm) {
                                        isPresenting = false
                                    }
                                    .disabled(newLogEntry.log.isEmpty)
                                } else {
                                    Button("Save") {
                                        isPresenting = false
                                    }
                                }
                            }
                            ToolbarItem (placement: .cancellationAction) {
                                if #available(iOS 26, *) {
                                    Button(role: .close) {
                                        isPresenting = false
                                    }
                                } else {
                                    Button("Cancel", role: .cancel) {
                                        isPresenting = false
                                    }
                                }
                            }

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

