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

private struct CachedInsights: Codable {
    var greatMoments: [String]
    var poorMoments: [String]
    var actionableTips: [String]
    var createdAt: Date
    var windowDays: Int = 0 // 0 = all time; default preserves backward compatibility
}

private let cachedInsightsKey = "patternInsightsCache"

@available(iOS 26.0, *)
struct InsightsView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @State private var insights: PatternInsights.PartiallyGenerated?
    @State private var cachedInsights: CachedInsights?
    @State private var isAnalyzing: Bool = false
    @State private var errorMessage: String?
    @State private var selectedDays: Int = 30
    @Environment(\.dismiss) private var dismiss

    private var allLogEntries: [DailyLogEntry] {
        allEntries.flatMap { $0.logEntries ?? [] }.sorted { $0.timestamp < $1.timestamp }
    }

    private var filteredLogEntries: [DailyLogEntry] {
        guard selectedDays > 0 else { return allLogEntries }
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDays, to: .now) ?? .now
        return allLogEntries.filter { $0.timestamp >= cutoff }
    }

    private var displayInsights: (greatMoments: [String], poorMoments: [String], actionableTips: [String])? {
        if let live = insights {
            return (live.greatMoments ?? [], live.poorMoments ?? [], live.actionableTips ?? [])
        }
        if let cached = cachedInsights {
            return (cached.greatMoments, cached.poorMoments, cached.actionableTips)
        }
        return nil
    }

    private func windowLabel(_ days: Int) -> String {
        days > 0 ? String(localized: "Last \(days) days") : String(localized: "All time")
    }

    var body: some View {
        List {
            Section {
                Picker("Time range", selection: $selectedDays) {
                    Text("Last 7 days").tag(7)
                    Text("Last 14 days").tag(14)
                    Text("Last 30 days").tag(30)
                    Text("Last 90 days").tag(90)
                    Text("All time").tag(0)
                }
                .disabled(isAnalyzing)

                HStack {
                    Spacer()
                    if isAnalyzing {
                        ProgressView("Analyzing your entries…")
                    } else {
                        Button {
                            Task { await analyze() }
                        } label: {
                            Label("Analyze", systemImage: "sparkles")
                        }
                        .disabled(filteredLogEntries.isEmpty)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            } else if let display = displayInsights {
                insightsSection(title: "What makes a great moment", items: display.greatMoments, systemImage: "sun.max.fill", tint: .orange)
                insightsSection(title: "What makes a poor moment", items: display.poorMoments, systemImage: "cloud.rain.fill", tint: .blue)
                insightsSection(title: "Actionable tips", items: display.actionableTips, systemImage: "lightbulb.fill", tint: .yellow)
            }
        }
        .navigationTitle("Insights")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { dismiss() }
            }
            if displayInsights != nil, !isAnalyzing {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .destructive) {
                        clearInsights()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
        }
        .onAppear {
            if let data = UserDefaults.standard.data(forKey: cachedInsightsKey),
               let decoded = try? JSONDecoder().decode(CachedInsights.self, from: data) {
                cachedInsights = decoded
                selectedDays = decoded.windowDays
            }
        }
        if let createdAt = cachedInsights?.createdAt, insights == nil, !isAnalyzing {
            VStack(spacing: 2) {
                Text("\(filteredLogEntries.count) entries · \(windowLabel(cachedInsights?.windowDays ?? selectedDays))")
                Text("Generated \(createdAt.formatted(date: .abbreviated, time: .shortened))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
        } else if insights != nil, !isAnalyzing {
            Text("\(filteredLogEntries.count) entries · \(windowLabel(selectedDays))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func insightsSection(title: LocalizedStringKey, items: [String], systemImage: String, tint: Color) -> some View {
        Section {
            if items.isEmpty {
                Text("No patterns identified yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
            }
        } header: {
            Label(title, systemImage: systemImage)
                .foregroundStyle(tint)
        }
    }

    private func clearInsights() {
        insights = nil
        cachedInsights = nil
        UserDefaults.standard.removeObject(forKey: cachedInsightsKey)
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

        let formatted = filteredLogEntries.map { entry in
            let scoreLabel = entry.score > 0 ? "+\(entry.score)" : "\(entry.score)"
            return "[\(scoreLabel)] \(entry.log)"
        }.joined(separator: "\n")

        let template = String(localized: "insights.analysisPrompt", bundle: .main)
        let prompt = String(format: template, formatted)

        do {
            let instructions = String(localized: "insights.sessionInstructions", bundle: .main)
            let session = LanguageModelSession(instructions: instructions)
            let stream = session.streamResponse(to: prompt, generating: PatternInsights.self)
            for try await partial in stream {
                insights = partial.content
            }
            if let final = insights {
                let cached = CachedInsights(
                    greatMoments: final.greatMoments ?? [],
                    poorMoments: final.poorMoments ?? [],
                    actionableTips: final.actionableTips ?? [],
                    createdAt: Date(),
                    windowDays: selectedDays
                )
                if let data = try? JSONEncoder().encode(cached) {
                    UserDefaults.standard.set(data, forKey: cachedInsightsKey)
                }
                cachedInsights = cached
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
