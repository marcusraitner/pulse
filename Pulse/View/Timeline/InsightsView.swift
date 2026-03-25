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
    @Guide(description: "Up to 3 synthesised insights — NOT a list of entries — explaining what underlying theme or condition made high-scoring moments (+1/+2) great. Each item names a recurring pattern and briefly explains why it mattered, e.g. 'Physical activity consistently lifts mood: workouts and walks appear in nearly all +2 entries.'")
    var greatMoments: [String]

    @Guide(description: "Up to 3 synthesised insights — NOT a list of entries — explaining what underlying theme or condition drove low-scoring moments (-1/-2). Each item names a recurring pattern and briefly explains the impact, e.g. 'Lack of sleep amplifies stress: most -2 entries mention tiredness combined with a demanding task.'")
    var poorMoments: [String]

    @Guide(description: "Up to 3 concrete, personalised actions derived from the patterns above. Each tip is directly actionable and specific to the data, e.g. 'Schedule at least one outdoor activity on days with back-to-back meetings to counteract the recurring stress pattern.'")
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
        You are a personal wellbeing analyst. Below are journal entries scored from -2 (very bad) \
        to +2 (very good). Each line: [score] text.

        \(formatted)

        Your task is to synthesise — not list — up to 3 insights per section:

        greatMoments: What recurring themes, contexts, or conditions appear across the high-scoring \
        entries (+1, +2)? Identify the underlying pattern, not individual entries.

        poorMoments: What recurring themes, contexts, or conditions appear across the low-scoring \
        entries (-1, -2)? Identify the underlying pattern, not individual entries.

        actionableTips: Based on the patterns above, what are up to 3 specific, personalised actions \
        this person could take to have more great moments and fewer poor ones?

        Each insight must be one sentence that names the pattern and explains why it matters. \
        Do not simply restate or quote individual entries.
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
