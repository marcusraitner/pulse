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
                AdminSettingsSection()
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
