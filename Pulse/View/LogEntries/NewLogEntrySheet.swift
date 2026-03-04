//
//  NewLogEntrySheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 21.02.26.
//

import SwiftUI
import OSLog
import SwiftData

struct NewLogEntrySheet: View {
    @State private var newEntry: DailyLogEntry = DailyLogEntry(timestamp: .now, log: "", score: 0)
    @Binding var entry: DailyLogEntry
    @Binding var isEntryNew: Bool
    @State private var isNew = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var saveEntry: (DailyLogEntry) -> Void
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "NewLogEntrySheet")

    var body: some View {
        Form {
            VStack(alignment: .leading) {
                TextField("What's going on?", text: $newEntry.log, axis: .vertical)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5...Int.max)
                
                Text("Please capture your moment here.")
                    .font(.caption)
                    .foregroundStyle(!isNew && newEntry.log.isEmpty ? .red : .clear)
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("How are you feeling?")
                    Text("Capture your mood on a scale from -2 (bad) to 2 (good)")
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                Spacer()
                VStack {
                    ScoreLabelView(score: newEntry.score, size: 72, radius: 12)
                        .font(.title).bold()
                    Stepper("", value: $newEntry.score, in: -2...2, step: 1)
                    .labelsHidden()
                    .padding(.top, 4)
                }
                .padding(.leading)
            }
            Section {
                HStack {
                    Spacer()
                    if !isEntryNew {
                        Button("Delete Entry", role: .destructive) {
                            context.delete(entry)
                            try? context.save()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .task {
            newEntry = DailyLogEntry(timestamp: .now, log: entry.log, score: entry.score)
        }
        .onChange(of: newEntry.score) {
            isNew = false
        }
        .navigationTitle(isEntryNew ? "New Moment" : "Edit Moment")
        .toolbar {
            ToolbarItem (placement: .confirmationAction) {
                if #available(iOS 26, *) {
                    Button(role: .confirm) {
                        saveEntry(newEntry)
                        dismiss()
                    }
                    .disabled(newEntry.log.isEmpty)
                } else {
                    Button("Save") {
                        saveEntry(newEntry)
                        dismiss()
                    }
                    .disabled(newEntry.log.isEmpty)
                }
            }
            ToolbarItem (placement: .cancellationAction) {
                if #available(iOS 26, *) {
                    Button(role: .close) {
                        dismiss()
                    }
                } else {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }

        }
    }
}

#Preview {
    NavigationStack {
        NewLogEntrySheet(entry: .constant(DailyLogEntry(timestamp: .now, log: "", score: 0)), isEntryNew: .constant(true), saveEntry: { entry in })
    }
}
