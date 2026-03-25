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
@Generable
struct PatternInsights {
    @Guide(description: "Short bullet points describing patterns or themes that characterise great moments (score +1 or +2). Each item is one concise sentence grounded in the journal entries.")
    var greatMoments: [String]

    @Guide(description: "Short bullet points describing patterns or themes that characterise poor moments (score -1 or -2). Each item is one concise sentence grounded in the journal entries.")
    var poorMoments: [String]

    @Guide(description: "Short, actionable tips the person can apply to have more great moments and fewer poor ones. Each item is one concise sentence.")
    var actionableTips: [String]
}

@available(iOS 26.0, *)
struct InsightsView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @State private var insights: PatternInsights.PartiallyGenerated?
    @State private var isAnalyzing: Bool = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private var allLogEntries: [DailyLogEntry] {
        allEntries.flatMap { $0.logEntries ?? [] }.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        List {
            if isAnalyzing {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Analyzing your entries…")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            } else if let insights {
                insightsSection(title: "What makes a great moment", items: insights.greatMoments ?? [], systemImage: "sun.max.fill", tint: .orange)
                insightsSection(title: "What makes a poor moment", items: insights.poorMoments ?? [], systemImage: "cloud.rain.fill", tint: .blue)
                insightsSection(title: "Actionable tips", items: insights.actionableTips ?? [], systemImage: "lightbulb.fill", tint: .yellow)
            } else {
                Section {
                    Text("Tap **Analyze** to discover what drives your best and worst moments.")
                        .foregroundStyle(.secondary)
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
        if let insights, !isAnalyzing {
            Text("Based on \(allLogEntries.count) log entries across \(allEntries.count) days")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func insightsSection(title: String, items: [String], systemImage: String, tint: Color) -> some View {
        Section {
            if items.isEmpty {
                Text("No patterns identified yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Label {
                        Text(item)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(tint)
                            .padding(.top, 5)
                    }
                }
            }
        } header: {
            Label(title, systemImage: systemImage)
                .foregroundStyle(tint)
        }
    }

    private func analyze() async {
        isAnalyzing = true
        errorMessage = nil
        insights = nil

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
        Below are personal journal entries with mood scores from -2 (very bad) to +2 (very good). \
        Each line starts with the score in brackets.

        \(formatted)

        Analyse these entries and populate the three fields: patterns behind great moments (+1/+2), \
        patterns behind poor moments (-1/-2), and actionable tips. \
        Be concise and specific, grounding each point in the actual entries.
        """

        do {
            let session = LanguageModelSession()
            let stream = session.streamResponse(to: prompt, generating: PatternInsights.self)
            for try await partial in stream {
                insights = partial.content
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
