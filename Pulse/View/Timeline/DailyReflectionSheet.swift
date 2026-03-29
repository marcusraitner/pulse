//
//  DailyReflectionSheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 05.03.26.
//

import SwiftUI
import _SwiftData_SwiftUI

/// Modal sheet for composing or editing the day's free-text reflection.
/// Shows the existing log entries for context and offers a rotating coaching question
/// when no reflection has been written yet.
struct DailyReflectionSheet: View {
    @Binding var day: DailyEntry
    @State private var reflection: String = ""
    @State private var coachingQuestion: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags

    /// Localization keys for the pool of coaching questions shown below the reflection field.
    private static let questionKeys = [
        "reflection.question.1",
        "reflection.question.2",
        "reflection.question.3",
        "reflection.question.4",
        "reflection.question.5",
        "reflection.question.6",
        "reflection.question.7",
        "reflection.question.8",
        "reflection.question.9",
        "reflection.question.10",
        "reflection.question.11",
        "reflection.question.12",
        "reflection.question.13",
        "reflection.question.14",
        "reflection.question.15",
        "reflection.question.16",
        "reflection.question.17",
        "reflection.question.18",
        "reflection.question.19",
        "reflection.question.20"
    ]

    /// Replaces the current coaching question with a different randomly selected one.
    private func pickAnotherQuestion() {
        let others = Self.questionKeys.filter { $0 != coachingQuestion }
        coachingQuestion = others.randomElement()
    }

    var body: some View {
        List {
            Section {
                TextField("Your reflection of this day", text: $reflection, axis: .vertical)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5...Int.max)
            } header: {
                Text("Reflect Your Day")
            } footer: {
                if let question = coachingQuestion {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(question))
                        HStack {
                            Spacer()
                            Button(action: pickAnotherQuestion) {
                                Label("New question", systemImage: "arrow.clockwise")
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.tint)
                            .padding(.top, 2)

                        }
                    }
                }
            }
            Section {
                if let logEntries = day.logEntries, !logEntries.isEmpty {
                    ForEach(day.logEntries?.sorted(by: { $0.timestamp < $1.timestamp } ) ?? []) { logEntry in
                        LogEntryText(logEntry: logEntry)
                            .padding(.vertical, featureFlags.iOS26 ? 0 : 5)
                    }
                }
            } header: {
                Text("Your Moments")
            } footer: {
                if day.logEntries?.isEmpty ?? true {
                    Text("No moments logged for this day.")
                }
            }
        }
        .navigationTitle("\(day.date.formatted(.dateTime.weekday(.wide).day().month(.defaultDigits).year()))")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Compat.confirmButton(String(localized: "Save")) {
                    day.summary = reflection
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Compat.closeButton { dismiss() }
            }
        }
        .task {
            reflection = day.summary
            if day.summary.isEmpty {
                coachingQuestion = Self.questionKeys.randomElement()
            }
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

#Preview("filled") {
    NavigationStack {
        DailyReflectionSheetPreviewContainer()
            .modelContainer(SampleData.shared.modelContainer)
    }
}

#Preview("empty") {
    NavigationStack {
        DailyReflectionSheet(day: .constant(.init(date: .now)))
    }
}

