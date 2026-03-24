//
//  InsightsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 24.03.26.
//

import SwiftUI
import SwiftData
import FoundationModels

@available(iOS 26.0, *)
struct InsightsView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @State private var result: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private var allLogEntries: [DailyLogEntry] {
        allEntries.flatMap { $0.logEntries ?? [] }.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        List {
            Section {
                if isAnalyzing {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Analyzing your entries…")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                } else if result.isEmpty {
                    Text("Tap **Analyze** to discover what drives your best and worst moments.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(result)
                }
            } header: {
                Text("Pattern Insights")
            } footer: {
                if !result.isEmpty {
                    Text("Based on \(allLogEntries.count) log entries across \(allEntries.count) days")
                }
            }
        }
        .navigationTitle("Insights")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { dismiss() }
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    Task { await analyze() }
                } label: {
                    Label("Analyze", systemImage: "sparkles")
                }
                .disabled(isAnalyzing || allLogEntries.isEmpty)
            }
        }
    }

    private func analyze() async {
        isAnalyzing = true
        errorMessage = nil
        result = ""

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            errorMessage = "Apple Intelligence is not available on this device or region."
            isAnalyzing = false
            return
        }

        let formatted = allLogEntries.map { entry in
            let scoreLabel = entry.score > 0 ? "+\(entry.score)" : "\(entry.score)"
            return "[\(scoreLabel)] \(entry.log)"
        }.joined(separator: "\n")

        let prompt = """
        Below are personal journal entries with mood scores ranging from -2 (very bad) to +2 (very good). \
        Each line starts with the score in brackets.

        \(formatted)

        Based on these entries, identify:
        1. What patterns or themes characterise the great moments (score +2 or +1)?
        2. What patterns or themes characterise the poor moments (score -2 or -1)?
        3. Any actionable insight the person could use to have more great moments and fewer poor ones.

        Be concise, specific, and ground your points in examples from the entries.
        """

        do {
            let session = LanguageModelSession()
            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                result = partial.content
            }
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }
}

@available(iOS 26.0, *)
struct InsightsViewPreviewContainer: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]

    var body: some View {
        if entries.isEmpty {
            Text("No sample data available").padding()
        } else {
            InsightsView()
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        NavigationStack {
            InsightsViewPreviewContainer()
                .modelContainer(SampleData.shared.modelContainer)
        }
    }
}
