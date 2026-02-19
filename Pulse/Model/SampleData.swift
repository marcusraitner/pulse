//
//  SampleData.swift
//  collins score
//
//  Created by Marcus Raitner on 14.05.25.
//

import Foundation
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
        
    let previewSampleData: [DailyEntry] = [
        .init(
            date: .now,
            logEntries: [
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000),
                    log: "Good start; got distracted after an hour",
                    score: 2)
            ],
        ),
        .init(
            date: Date(timeIntervalSinceNow: -86400 * 2),
            logEntries: [
                DailyLogEntry(
                    timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!,
                    log: "Empty day, just resting",
                    score: -2),
                DailyLogEntry(
                    timestamp: Date.now,
                    log: "Nothing",
                    score: -2)
            ],
        ),
        .init(
            date: Date(timeIntervalSinceNow: -86400 * 3),
            logEntries: [
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000),
                    log:
                        "got some deep work done but also some distractions. And this is a very long sentence to make sure the summary is longer than the intent and to see what happens in the UI",
                    score: 0
                ),
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000 * 2),
                    log: "Good start; got distracted after an hour",
                    score: 1
                ),
            ],
        ),
        .init(
            date: Date(timeIntervalSinceNow: -86400 * 4),
            logEntries: [
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000*5),
                    log: "Total waste of time",
                    score: 1
                )
            ],
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -5, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 1), log: "Wrapped up core features", score: 2),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 2), log: "Fixed a couple of bugs", score: 1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -6, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 3), log: "Sprint goals drafted", score: 1),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 5), log: "Got derailed by unexpected meeting", score: -1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -7200), log: "Reviewed retention metrics", score: 0),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -10800), log: "Identified a drop-off in onboarding", score: 1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -8, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -5400), log: "Tweaked copy and animations", score: 1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -9, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -4000), log: "Inbox zero attempt failed", score: -1),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3000), log: "Flagged important threads", score: 0)
            ]
        )
    ]
    
    private let sampleData: [DailyEntry] = [
        .init(
            date: .now,
            logEntries: [
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000),
                    log: "Good start; got distracted after an hour",
                    score: 2
                )
            ],
        ),
        .init(
            date: Date(timeIntervalSinceNow: -86400 * 2),
            logEntries: [
                DailyLogEntry(
                    timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!,
                    log: "Empty day, just resting",
                    score: -2),
                DailyLogEntry(
                    timestamp: Date.now,
                    log: "Nothing",
                    score: -2)
            ],
        ),
        .init(
            date: Date(timeIntervalSinceNow: -86400 * 3),
            logEntries: [
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000),
                    log:
                        "got some deep work done but also some distractions. And this is a very long sentence to make sure the summary is longer than the intent and to see what happens in the UI",
                    score: 0
                ),
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000 * 2),
                    log: "Good start; got distracted after an hour",
                    score: 1
                ),
            ],
        ),
        .init(
            date: Date(timeIntervalSinceNow: -86400 * 4),
            logEntries: [
                DailyLogEntry(
                    timestamp: Date(timeIntervalSinceNow: -5000*5),
                    log: "Total waste of time",
                    score: 1
                )
            ],
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -5, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 1), log: "Wrapped up core features", score: 2),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 2), log: "Fixed a couple of bugs", score: 1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -6, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 3), log: "Sprint goals drafted", score: 1),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 5), log: "Got derailed by unexpected meeting", score: -1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -7200), log: "Reviewed retention metrics", score: 0),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -10800), log: "Identified a drop-off in onboarding", score: 1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -8, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -5400), log: "Tweaked copy and animations", score: 1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -9, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -4000), log: "Inbox zero attempt failed", score: -1),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3000), log: "Flagged important threads", score: 0)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -10, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -2500), log: "Sketched interaction flow", score: 0),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -2000), log: "Hit roadblock with data model", score: -1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -11, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -7200), log: "Optimized rendering pipeline", score: 2),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -3600 * 4), log: "Reduced memory usage by 20%", score: 1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -12, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -5000), log: "Collected notes on top 3 competitors", score: -1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -13, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -6000), log: "Split services into modules", score: -2),
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -6500), log: "Improved error handling paths", score: -1)
            ]
        ),
        .init(
            date: Calendar.current.date(byAdding: .day, value: -14, to: .now)!,
            logEntries: [
                DailyLogEntry(timestamp: Date(timeIntervalSinceNow: -7200), log: "Updated README and API docs", score: 0)
            ]
        ),
    ]
    
    private init() {
        let schema = Schema([
            DailyEntry.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
           
            for entry in sampleData {
                modelContainer.mainContext.insert(entry)
            }

            try modelContainer.mainContext.save()
            
        } catch {
            fatalError("Unable to initialize ModelContainer: \(error)")
        }
    }
}

