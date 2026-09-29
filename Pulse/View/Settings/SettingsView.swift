//
//  SettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import SwiftData
import OSLog

struct SettingsView: View {

    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "SettingsView")

    @Query private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]
    @Query private var allKPIValues: [DailyKPIValue]
    @Query private var allTags: [Tag]
    @Query private var allKPIs: [KPITemplate]

    // MARK: - Body

    var body: some View {
        Form {
            NavigationLink() {
                GeneralSettingsView()
            } label: {
                Label {
                    Text("General")
                } icon: {
                    Image(systemName: "gear")
                        .listLabelIcon(.gray)
                }
            }
            NavigationLink() {
                AppearanceSettingsView()
            } label: {
                Label {
                    Text("Appearance")
                } icon: {
                    Image(systemName: "paintbrush.fill")
                        .listLabelIcon(.blue)
                }
            }
            NavigationLink() {
                KPITemplatesSettingsView()
            } label: {
                Label {
                    Text("Metrics")
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .listLabelIcon(.orange)
                }
            }
            NavigationLink() {
                TagSettingsView()
            } label: {
                Label {
                    Text("Tags")
                } icon: {
                    Image(systemName: "tag.circle.fill")
                        .listLabelIcon(.teal)
                }
            }
            NavigationLink() {
                RemindersSettingsView()
            } label: {
                Label {
                    Text("Reminders")
                } icon: {
                    Image(systemName: "bell.badge.fill")
                        .listLabelIcon(.red)
                }
            }

            // MARK: About & Statistics
            Section {
                NavigationLink() {
                    AboutView()
                } label: {
                    Label {
                        Text("About")
                    } icon: {
                        Image("AppIcon-iOS-Default")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }

                NavigationLink() {
                    StatisticsSettingsView()
                } label: {
                    Label {
                        Text("Statistics")
                    } icon: {
                        Image(systemName: "chart.bar.horizontal.page.fill")
                            .listLabelIcon(.gray)
                    }
                }
            }

            // MARK: Admin
            if featureFlags.adminEnabled {
                Section {
                    Text("Danger Zone")
                        .foregroundStyle(Color.red)
                    Button("Seed Samples") {
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
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
