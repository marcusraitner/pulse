//
//  DailyReflectionSheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 05.03.26.
//

import SwiftUI
import _SwiftData_SwiftUI

struct DailyReflectionSheet: View {
    @Binding var day: DailyEntry
    @State private var reflection: String = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags
    
    var body: some View {
        List {
            TextField("Your reflection of this day?", text: $reflection, axis: .vertical)
                .multilineTextAlignment(.leading)
                .lineLimit(5...Int.max)
            Section("Your Moments") {
                ForEach(day.logEntries?.sorted(by: { $0.timestamp < $1.timestamp } ) ?? []) { logEntry in
                    LogEntryText(logEntry: logEntry)
                        .padding(.vertical, featureFlags.iOS26 ? 0 : 5)
                }
            }
        }
        .navigationTitle("Reflect Your Day")
        .toolbar {
            ToolbarItem (placement: .confirmationAction) {
                if #available(iOS 26, *) {
                    Button(role: .confirm) {
                        day.summary = reflection
                        dismiss()
                    }
                } else {
                    Button("Save") {
                        day.summary = reflection
                        dismiss()
                    }
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
        .task {
            reflection = day.summary
        }
    }
}


struct DailyReflectionSheetPreviewContainer: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries:
        [DailyEntry]

    var body: some View {
        if let entry = entries.first {
            DailyReflectionSheet(day: .constant(entry))
        } else {
            Text("No sample data available")
                .padding()
        }
    }
}

#Preview {
    NavigationStack {
        DailyReflectionSheetPreviewContainer()
            .modelContainer(SampleData.shared.modelContainer)
    }
}
