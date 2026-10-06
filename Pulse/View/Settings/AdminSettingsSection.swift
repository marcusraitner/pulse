//
//  AdminSettingsSection.swift
//  Pulse
//
//  Created by Marcus Raitner on 06.10.26.
//

import SwiftUI
import SwiftData
import OSLog

/// Developer-only section of the settings. Kept in its own view so that its queries, which load
/// all data, only run when the admin flag is on and this view is actually created.
struct AdminSettingsSection: View {

    @Environment(\.modelContext) private var context

    @Query private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]
    @Query private var allKPIValues: [DailyKPIValue]
    @Query private var allTags: [Tag]
    @Query private var allKPIs: [KPITemplate]

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "AdminSettingsSection")

    var body: some View {
        Section {
            Text("Danger Zone")
                .foregroundStyle(Color.red)
            Button("Seed Samples", action: seedSamples)
        }
    }

    /// Replaces all data with generated sample data.
    private func seedSamples() {
        for log in allLogs {
            context.delete(log)
        }
        for value in allKPIValues {
            context.delete(value)
        }
        for entry in allEntries {
            context.delete(entry)
        }
        for template in allKPIs {
            context.delete(template)
        }
        for tag in allTags {
            context.delete(tag)
        }
        context.saveOrLog("Failed to clear existing data before seeding mock data", logger: logger)

        let seedLanguage = SampleData.SeedLanguage.current
        let templates = SampleData.makeSeedTemplates(language: seedLanguage)

        for template in templates {
            context.insert(template)
        }

        for tag in SampleData.makeSeedTags(language: seedLanguage) {
            context.insert(tag)
        }

        let days = SampleData.makeSeedDays(templates: templates, language: seedLanguage)
        for day in days {
            context.insert(day)
        }
        for logEntry in SampleData.makeSeedLogEntries(for: days, language: seedLanguage) {
            context.insert(logEntry)
        }

        context.saveOrLog("Failed to save mock data", logger: logger)
    }
}

#Preview {
    Form {
        AdminSettingsSection()
    }
    .modelContainer(SampleData.shared.modelContainer)
    .preferredColorScheme(.dark)
}
