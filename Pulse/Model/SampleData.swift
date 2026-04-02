//
//  SampleData.swift
//  collins score
//
//  Created by Marcus Raitner on 14.05.25.
//

import Foundation
import SwiftData

/// In-memory SwiftData container pre-populated with sample entries for SwiftUI previews.
/// Do not use in production code.
@MainActor
class SampleData {
    /// Shared singleton instance.
    static let shared = SampleData()

    /// The in-memory `ModelContainer` holding the sample data.
    let modelContainer: ModelContainer

    /// Creates fresh, unmanaged `DailyEntry` objects suitable for insertion into any context.
    static func makeSeedEntries() -> [DailyEntry] {
        [
            .init(
                date: .now,
                summary: "Strong start to the week; a bit of context switching in the afternoon.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: Date(timeIntervalSinceNow: -5000),
                        log: "Good start; got distracted after an hour",
                        score: 2,
                        latitude: 37.3349,
                        longitude: -122.0090,
                        address: "Apple Park, Cupertino, CA"
                    ),
                    DailyLogEntry(
                        timestamp: Date(timeIntervalSinceNow: -5000),
                        log: "Got distracted after an hour",
                        score: 1,
                        latitude: 37.3349,
                        longitude: -122.0090,
                        address: "Apple Park, Cupertino, CA"
                    )
                ]
            ),
            .init(
                date: Date(timeIntervalSinceNow: -86400 * 2),
                summary: "Low-energy day with minimal progress; prioritized rest.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!,
                        log: "Empty day, just resting",
                        score: -2,
                        latitude: 37.7749,
                        longitude: -122.4194,
                        address: "Home"
                    ),
                    DailyLogEntry(
                        timestamp: Date.now,
                        log: "Nothing",
                        score: -2,
                        latitude: 37.7749,
                        longitude: -122.4194,
                        address: "Home"
                    )
                ]
            ),
            .init(
                date: Date(timeIntervalSinceNow: -86400 * 3),
                summary: "Mixed focus: meaningful deep work tempered by distractions.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: Date(timeIntervalSinceNow: -5000),
                        log: "got some deep work done but also some distractions. And this is a very long sentence to make sure the summary is longer than the intent and to see what happens in the UI",
                        score: 0,
                        latitude: 37.7765,
                        longitude: -122.4172,
                        address: "Downtown Cafe"
                    ),
                    DailyLogEntry(
                        timestamp: Date(timeIntervalSinceNow: -5000 * 2),
                        log: "Good start; got distracted after an hour",
                        score: 1,
                        latitude: 37.3317,
                        longitude: -122.0301,
                        address: "Office"
                    ),
                ]
            ),
            .init(
                date: Date(timeIntervalSinceNow: -86400 * 4),
                summary: "Challenging day; momentum dipped significantly.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: Date(timeIntervalSinceNow: -5000 * 5),
                        log: "Total waste of time",
                        score: 1,
                        latitude: 37.7793,
                        longitude: -122.4192,
                        address: "Library"
                    )
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -5, to: .now)!,
                summary: "Closed core work and improved stability; solid progress.",
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 1), log: "Wrapped up core features", score: 2, latitude: 37.3317, longitude: -122.0301, address: "Office"),
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 2), log: "Fixed a couple of bugs", score: 1, latitude: 37.3317, longitude: -122.0301, address: "Office")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -6, to: .now)!,
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 3), log: "Sprint goals drafted", score: 1, latitude: 37.7739, longitude: -122.4312, address: "Home Office"),
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 5), log: "Got derailed by unexpected meeting", score: -1, latitude: 37.7739, longitude: -122.4312, address: "Home Office")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
                summary: "Analytics review uncovered onboarding opportunities.",
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -7200), log: "Reviewed retention metrics", score: 0, latitude: 37.3317, longitude: -122.0301, address: "Office"),
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -10800), log: "Identified a drop-off in onboarding", score: 1, latitude: 37.3317, longitude: -122.0301, address: "Office")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -8, to: .now)!,
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -5400), log: "Tweaked copy and animations", score: 1, latitude: 37.7858, longitude: -122.4064, address: "Design Studio")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -9, to: .now)!,
                summary: "Email management partially successful; focus fragmented.",
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -4000), log: "Inbox zero attempt failed", score: -1, latitude: 37.7749, longitude: -122.4194, address: "Home"),
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3000), log: "Flagged important threads", score: 0, latitude: 37.7749, longitude: -122.4194, address: "Home")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -10, to: .now)!,
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -2500), log: "Sketched interaction flow", score: 0, latitude: 37.7858, longitude: -122.4064, address: "Design Studio"),
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -2000), log: "Hit roadblock with data model", score: -1, latitude: 37.7739, longitude: -122.4312, address: "Home Office")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -11, to: .now)!,
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -7200), log: "Optimized rendering pipeline", score: 2, latitude: 37.3317, longitude: -122.0301, address: "Office"),
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 4), log: "Reduced memory usage by 20%", score: 1, latitude: 37.3317, longitude: -122.0301, address: "Office")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -12, to: .now)!,
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -5000), log: "Collected notes on top 3 competitors", score: -1, latitude: 37.7765, longitude: -122.4172, address: "Cafe")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -13, to: .now)!,
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -6000), log: "Split services into modules", score: -2, latitude: 37.7739, longitude: -122.4312, address: "Home Office"),
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -6500), log: "Improved error handling paths", score: -1, latitude: 37.7739, longitude: -122.4312, address: "Home Office")
                ]
            ),
            .init(
                date: Calendar.current.date(byAdding: .day, value: -14, to: .now)!,
                logEntries: [
                    DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -7200), log: "Updated README and API docs", score: 0, latitude: 37.7749, longitude: -122.4194, address: "Home")
                ]
            ),
        ]
    }

    private init() {
        let schema = Schema([
            DailyEntry.self,
            DailyLogEntry.self,
            DailyKPIValue.self,
            KPITemplate.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)

            for entry in SampleData.makeSeedEntries() {
                modelContainer.mainContext.insert(entry)
            }

            for template in SampleData.makeSeedTemplates() {
                modelContainer.mainContext.insert(template)
            }

            try modelContainer.mainContext.save()

        } catch {
            fatalError("Unable to initialize ModelContainer: \(error)")
        }
    }

    /// Creates fresh `KPITemplate` objects for previews and seeding.
    static func makeSeedTemplates() -> [KPITemplate] {
        [
            KPITemplate(title: "Deep Work", note: "How many minutes of focused, uninterrupted work?", unit: "min", sortOrder: 0),
            KPITemplate(title: "Sleep", note: "How many hours did you sleep last night?", unit: "h", sortOrder: 1),
            KPITemplate(title: "Exercise", note: "How many minutes of exercise today?", unit: nil, sortOrder: 2),
            KPITemplate(title: "Running", note: "How many kms today?", unit: "km", sortOrder: 3),
        ]
    }
}
