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
    
    enum SeedLanguage: String, CaseIterable {
        case en
        case de
        
        static var current: SeedLanguage {
            Locale.preferredLanguages.first?.hasPrefix("de") == true ? .de : .en
        }
    }

    /// Creates fresh, unmanaged `DailyEntry` objects suitable for insertion into any context.
    static func makeSeedEntries(language: SeedLanguage = .en) -> [DailyEntry] {
        makeSeedEntries(templates: SampleData.makeSeedTemplates(language: language), language: language)
    }
    
    /// Creates fresh, unmanaged `DailyEntry` objects and links KPI values to the provided templates.
    static func makeSeedEntries(templates: [KPITemplate], language: SeedLanguage = .en) -> [DailyEntry] {
        let cal = Calendar.current
        func time(_ hour: Int, _ minute: Int = 0, on base: Date) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }
        let d: [Date] = (0...14).map { cal.date(byAdding: .day, value: -$0, to: .now)! }

        let entries: [DailyEntry] = [
            .init(
                date: d[0],
                summary: "Strong start with deep work, then momentum dipped after distractions in the afternoon.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: time(9, 0, on: d[0]),
                        log: "Good start; got distracted after an hour. Then the day went totally bogus.",
                        score: 2,
                        latitude: 37.3349,
                        longitude: -122.0090,
                        address: "Apple Park, Cupertino, CA",
                        tagsRaw: "Deep Work,Focus"
                    ),
                    DailyLogEntry(
                        timestamp: time(14, 30, on: d[0]),
                        log: "Got distracted after an hour",
                        score: 1,
                        latitude: 37.3349,
                        longitude: -122.0090,
                        address: "Apple Park, Cupertino, CA",
                        tagsRaw: "Work Stress"
                    )
                ]
            ),
            .init(
                date: d[2],
                summary: "Low-energy day with minimal progress; prioritized rest.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: time(9, 30, on: d[2]),
                        log: "Empty day, just resting",
                        score: -2,
                        latitude: 37.7749,
                        longitude: -122.4194,
                        address: "Home",
                        tagsRaw: "Sleep"
                    ),
                    DailyLogEntry(
                        timestamp: time(15, 0, on: d[2]),
                        log: "Nothing",
                        score: -2,
                        latitude: 37.7749,
                        longitude: -122.4194,
                        address: "Home",
                        tagsRaw: "Sleep,Family"
                    )
                ]
            ),
            .init(
                date: d[3],
                summary: "Mixed focus: meaningful deep work tempered by distractions.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: time(9, 0, on: d[3]),
                        log: "got some deep work done but also some distractions. And this is a very long sentence to make sure the summary is longer than the intent and to see what happens in the UI",
                        score: 0,
                        latitude: 37.7765,
                        longitude: -122.4172,
                        address: "Downtown Cafe",
                        tagsRaw: "Deep Work"
                    ),
                    DailyLogEntry(
                        timestamp: time(14, 0, on: d[3]),
                        log: "Good start; got distracted after an hour",
                        score: 1,
                        latitude: 37.3317,
                        longitude: -122.0301,
                        address: "Office",
                        tagsRaw: "Focus,Work Stress"
                    ),
                ]
            ),
            .init(
                date: d[4],
                summary: "Frustrating library session with very low perceived productivity.",
                logEntries: [
                    DailyLogEntry(
                        timestamp: time(10, 0, on: d[4]),
                        log: "Total waste of time",
                        score: 1,
                        latitude: 37.7793,
                        longitude: -122.4192,
                        address: "Library",
                        tagsRaw: "Work Stress"
                    )
                ]
            ),
            .init(
                date: d[5],
                summary: "Closed core work and improved stability; solid progress.",
                logEntries: [
                    DailyLogEntry(timestamp: time(10, 0, on: d[5]), log: "Wrapped up core features", score: 2, latitude: 37.3317, longitude: -122.0301, address: "Office", tagsRaw: "Deep Work,Focus"),
                    DailyLogEntry(timestamp: time(14, 0, on: d[5]), log: "Fixed a couple of bugs", score: 1, latitude: 37.3317, longitude: -122.0301, address: "Office", tagsRaw: "Focus")
                ]
            ),
            .init(
                date: d[6],
                summary: "Sprint planning went well, but an unexpected meeting disrupted focus.",
                logEntries: [
                    DailyLogEntry(timestamp: time(9, 0, on: d[6]), log: "Sprint goals drafted", score: 1, latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Focus"),
                    DailyLogEntry(timestamp: time(14, 0, on: d[6]), log: "Got derailed by unexpected meeting", score: -1, latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Work Stress")
                ]
            ),
            .init(
                date: d[7],
                summary: "Analytics review uncovered onboarding opportunities.",
                logEntries: [
                    DailyLogEntry(timestamp: time(10, 0, on: d[7]), log: "Reviewed retention metrics", score: 0, latitude: 37.3317, longitude: -122.0301, address: "Office", tagsRaw: "Deep Work,Focus"),
                    DailyLogEntry(timestamp: time(14, 0, on: d[7]), log: "Identified a drop-off in onboarding", score: 1, latitude: 37.3317, longitude: -122.0301, address: "Office", tagsRaw: "Focus")
                ]
            ),
            .init(
                date: d[8],
                summary: "Design polish improved copy clarity and motion quality.",
                logEntries: [
                    DailyLogEntry(timestamp: time(11, 30, on: d[8]), log: "Tweaked copy and animations", score: 1, latitude: 37.7858, longitude: -122.4064, address: "Design Studio", tagsRaw: "Deep Work")
                ]
            ),
            .init(
                date: d[9],
                summary: "Email management partially successful; focus fragmented.",
                logEntries: [
                    DailyLogEntry(timestamp: time(9, 0, on: d[9]), log: "Inbox zero attempt failed", score: -1, latitude: 37.7749, longitude: -122.4194, address: "Home", tagsRaw: "Work Stress"),
                    DailyLogEntry(timestamp: time(15, 0, on: d[9]), log: "Went for a morning run to clear my head", score: 1, latitude: 37.7749, longitude: -122.4194, address: "Home", tagsRaw: "Sport,Outdoor")
                ]
            ),
            .init(
                date: d[10],
                summary: "Solid UX progress early, then blocked by a data model issue.",
                logEntries: [
                    DailyLogEntry(timestamp: time(9, 0, on: d[10]), log: "Sketched interaction flow", score: 0, latitude: 37.7858, longitude: -122.4064, address: "Design Studio", tagsRaw: "Deep Work,Focus"),
                    DailyLogEntry(timestamp: time(15, 0, on: d[10]), log: "Hit roadblock with data model", score: -1, latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Work Stress")
                ]
            ),
            .init(
                date: d[11],
                summary: "Excellent performance work with clear gains in rendering and memory efficiency.",
                logEntries: [
                    DailyLogEntry(timestamp: time(10, 0, on: d[11]), log: "Optimized rendering pipeline", score: 2, latitude: 37.3317, longitude: -122.0301, address: "Office", tagsRaw: "Deep Work,Focus"),
                    DailyLogEntry(timestamp: time(14, 0, on: d[11]), log: "Reduced memory usage by 20%", score: 1, latitude: 37.3317, longitude: -122.0301, address: "Office", tagsRaw: "Deep Work,Focus")
                ]
            ),
            .init(
                date: d[12],
                summary: "Competitor research produced useful notes but felt draining.",
                logEntries: [
                    DailyLogEntry(timestamp: time(10, 0, on: d[12]), log: "Collected notes on top 3 competitors", score: -1, latitude: 37.7765, longitude: -122.4172, address: "Cafe", tagsRaw: "Focus")
                ]
            ),
            .init(
                date: d[13],
                summary: "Architecture work improved modularity and reliability, but stress stayed high.",
                logEntries: [
                    DailyLogEntry(timestamp: time(9, 0, on: d[13]), log: "Split services into modules", score: -2, latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Work Stress"),
                    DailyLogEntry(timestamp: time(14, 30, on: d[13]), log: "Improved error handling paths", score: -1, latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Work Stress")
                ]
            ),
            .init(
                date: d[14],
                summary: "Quiet documentation day that kept project docs up to date.",
                logEntries: [
                    DailyLogEntry(timestamp: time(10, 0, on: d[14]), log: "Updated README and API docs", score: 0, latitude: 37.7749, longitude: -122.4194, address: "Home", tagsRaw: "Deep Work")
                ]
            ),
        ]
        
        applyLocalization(to: entries, language: language)

        let kpiTemplates = Array(templates.sorted(by: { $0.sortOrder < $1.sortOrder }).prefix(3))
        guard kpiTemplates.count == 3 else { return entries }

        let seedKPIValues: [(deepWorkMinutes: Int, sleepHours: Int, exerciseMinutes: Int)] = [
            (150, 7, 25),
            (20, 9, 10),
            (95, 6, 20),
            (30, 6, 15),
            (180, 7, 35),
            (60, 7, 20),
            (110, 8, 15),
            (75, 7, 30),
            (45, 8, 40),
            (90, 6, 20),
            (200, 7, 25),
            (50, 6, 10),
            (80, 6, 15),
            (70, 7, 20),
        ]

        for (index, entry) in entries.enumerated() {
            let values = seedKPIValues[index]
            entry.kpiValues = [
                DailyKPIValue(value: values.deepWorkMinutes, template: kpiTemplates[0], entry: entry),
                DailyKPIValue(value: values.sleepHours, template: kpiTemplates[1], entry: entry),
                DailyKPIValue(value: values.exerciseMinutes, template: kpiTemplates[2], entry: entry),
            ]
        }

        return entries
    }
    
    private static func applyLocalization(to entries: [DailyEntry], language: SeedLanguage) {
        guard language == .de else { return }
        
        for entry in entries {
            if let localizedSummary = germanSummaryByEnglish[entry.summary] {
                entry.summary = localizedSummary
            }
            
            for logEntry in entry.logEntries ?? [] {
                if let localizedLog = germanLogByEnglish[logEntry.log] {
                    logEntry.log = localizedLog
                }
                if let address = logEntry.address, let localizedAddress = germanAddressByEnglish[address] {
                    logEntry.address = localizedAddress
                }
                let localizedTags = logEntry.tags.map { germanTagByEnglish[$0] ?? $0 }
                logEntry.tagsRaw = localizedTags.joined(separator: ",")
            }
        }
    }
    
    private static let germanTagByEnglish: [String: String] = [
        "Deep Work": "Deep Work",
        "Focus": "Fokus",
        "Sleep": "Schlaf",
        "Sport": "Sport",
        "Outdoor": "Draußen",
        "Family": "Familie",
        "Work Stress": "Arbeitsstress",
    ]
    
    private static let germanAddressByEnglish: [String: String] = [
        "Home": "Zuhause",
        "Office": "Büro",
        "Library": "Bibliothek",
        "Home Office": "Homeoffice",
        "Design Studio": "Designstudio",
        "Downtown Cafe": "Innenstadt-Cafe",
        "Cafe": "Cafe",
    ]
    
    private static let germanSummaryByEnglish: [String: String] = [
        "Strong start with deep work, then momentum dipped after distractions in the afternoon.": "Starker Start, dann ließ die Dynamik nach den Ablenkungen am Nachmittag nach.",
        "Low-energy day with minimal progress; prioritized rest.": "Energiearmer Tag mit wenig Fortschritt; Erholung hatte Priorität.",
        "Mixed focus: meaningful deep work tempered by distractions.": "Gemischter Fokus: Deep Work, aber auch Ablenkungen.",
        "Frustrating library session with very low perceived productivity.": "Frustrierende Bibliothekssession mit sehr geringer gefühlter Produktivität.",
        "Closed core work and improved stability; solid progress.": "Kernaufgaben abgeschlossen und Stabilität verbessert; solider Fortschritt.",
        "Sprint planning went well, but an unexpected meeting disrupted focus.": "Sprintplanung lief gut, aber ein unerwartetes Meeting hat den Fokus gestört.",
        "Analytics review uncovered onboarding opportunities.": "Die Analyse zeigte Chancen zur Verbesserung des Onboardings.",
        "Design polish improved copy clarity and motion quality.": "Design-Polishing hat Textklarheit und Motion-Qualität verbessert.",
        "Email management partially successful; focus fragmented.": "E-Mail-Management teils erfolgreich; Fokus blieb zersplittert.",
        "Solid UX progress early, then blocked by a data model issue.": "Guter UX-Fortschritt am Anfang, dann durch ein Datenmodellproblem blockiert.",
        "Excellent performance work with clear gains in rendering and memory efficiency.": "Ausgezeichnete Performance-Arbeit mit klaren Gewinnen bei Rendering und Speicher.",
        "Competitor research produced useful notes but felt draining.": "Wettbewerbsanalyse lieferte nützliche Notizen, war aber anstrengend.",
        "Architecture work improved modularity and reliability, but stress stayed high.": "Architekturarbeit verbesserte Modularität und Robustheit, aber der Stress blieb hoch.",
        "Quiet documentation day that kept project docs up to date.": "Ruhiger Dokumentationstag, der die Projektdoku auf den neuesten Stand brachte.",
    ]
    
    private static let germanLogByEnglish: [String: String] = [
        "Good start; got distracted after an hour. Then the day went totally bogus.": "Guter Start; nach einer Stunde abgelenkt. Danach lief der Tag komplett aus dem Ruder.",
        "Got distracted after an hour": "Nach einer Stunde abgelenkt",
        "Empty day, just resting": "Leerer Tag, nur ausgeruht",
        "Nothing": "Nichts",
        "got some deep work done but also some distractions. And this is a very long sentence to make sure the summary is longer than the intent and to see what happens in the UI": "Etwas Deep Work geschafft, aber auch einige Ablenkungen. Und das ist ein sehr langer Satz, um sicherzustellen, dass die Zusammenfassung langer als der Eintrag ist und um zu sehen, was in der UI passiert.",
        "Total waste of time": "Komplette Zeitverschwendung",
        "Wrapped up core features": "Kernfunktionen abgeschlossen",
        "Fixed a couple of bugs": "Ein paar Bugs behoben",
        "Sprint goals drafted": "Sprintziele ausgearbeitet",
        "Got derailed by unexpected meeting": "Durch ein unerwartetes Meeting ausgebremst",
        "Reviewed retention metrics": "Retention-Metriken überprüft",
        "Identified a drop-off in onboarding": "Einen Abbruchpunkt im Onboarding identifiziert",
        "Tweaked copy and animations": "Texte und Animationen überarbeitet",
        "Inbox zero attempt failed": "Inbox-Zero-Versuch gescheitert",
        "Went for a morning run to clear my head": "Morgens joggen gegangen, um den Kopf frei zu bekommen",
        "Sketched interaction flow": "Interaktionsfluss skizziert",
        "Hit roadblock with data model": "Auf ein Hindernis im Datenmodell gestoßen",
        "Optimized rendering pipeline": "Rendering-Pipeline optimiert",
        "Reduced memory usage by 20%": "Speichernutzung um 20 % reduziert",
        "Collected notes on top 3 competitors": "Notizen zu den drei wichtigsten Wettbewerbern gesammelt",
        "Split services into modules": "Services in Module aufgeteilt",
        "Improved error handling paths": "Fehlerbehandlungspfade verbessert",
        "Updated README and API docs": "README und API-Dokumentation aktualisiert",
    ]

    private init() {
        let schema = Schema([
            DailyEntry.self,
            DailyLogEntry.self,
            DailyKPIValue.self,
            KPITemplate.self,
            Tag.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
            let language = SeedLanguage.current

            let templates = SampleData.makeSeedTemplates(language: language)
            for template in templates {
                modelContainer.mainContext.insert(template)
            }

            for entry in SampleData.makeSeedEntries(templates: templates, language: language) {
                modelContainer.mainContext.insert(entry)
            }

            for tag in SampleData.makeSeedTags(language: language) {
                modelContainer.mainContext.insert(tag)
            }

            try modelContainer.mainContext.save()

        } catch {
            fatalError("Unable to initialize ModelContainer: \(error)")
        }
    }

    /// Creates fresh `Tag` objects for the tag palette used in previews.
    static func makeSeedTags(language: SeedLanguage = .en) -> [Tag] {
        switch language {
        case .en:
            ["Deep Work", "Focus", "Sleep", "Sport", "Outdoor", "Family", "Work Stress"].map { Tag(name: $0) }
        case .de:
            ["Deep Work", "Fokus", "Schlaf", "Sport", "Draußen", "Familie", "Arbeitsstress"].map { Tag(name: $0) }
        }
    }

    /// Creates fresh `KPITemplate` objects for previews and seeding.
    static func makeSeedTemplates(language: SeedLanguage = .en) -> [KPITemplate] {
        switch language {
        case .en:
            [
                KPITemplate(title: "Deep Work", note: "How many minutes of focused, uninterrupted work?", unit: "min", sortOrder: 0),
                KPITemplate(title: "Sleep", note: "How many hours did you sleep last night?", unit: "h", sortOrder: 1),
                KPITemplate(title: "Exercise", note: "How many minutes of exercise today?", unit: "min", sortOrder: 2),
                KPITemplate(title: "Family Time", note: "How much quality time with family?", unit: nil, sortOrder: 3),
            ]
        case .de:
            [
                KPITemplate(title: "Deep Work", note: "Wie viele Minuten fokussierte, ununterbrochene Arbeit?", unit: "min", sortOrder: 0),
                KPITemplate(title: "Schlaf", note: "Wie viele Stunden hast du letzte Nacht geschlafen?", unit: "h", sortOrder: 1),
                KPITemplate(title: "Sport", note: "Wie viele Minuten Sport heute?", unit: "min", sortOrder: 2),
                KPITemplate(title: "Familienzeit", note: "Wie viel qualitative Zeit mit der Familie?", unit: nil, sortOrder: 3),
            ]
        }
    }
}
