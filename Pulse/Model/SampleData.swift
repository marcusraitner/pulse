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
        
        nonisolated static var current: SeedLanguage {
            Locale.preferredLanguages.first?.hasPrefix("de") == true ? .de : .en
        }
    }

    #if DEBUG
    /// Key of the DEBUG launch argument `-sampleData de|en`. Arguments of the form `-key value`
    /// land in the argument domain of `UserDefaults`, so no parsing is needed.
    static let launchArgumentKey = "sampleData"

    /// Seed language requested via `-sampleData de|en` in the Xcode scheme,
    /// or `nil` (argument missing or unknown value) to start with the real data.
    static func launchArgumentLanguage(from defaults: UserDefaults = .standard) -> SeedLanguage? {
        defaults.string(forKey: launchArgumentKey).flatMap(SeedLanguage.init(rawValue:))
    }
    #endif

    /// Number of seeded days, counting back from today (index 0) without gaps.
    static let seedDayCount = 60
    /// The most recent days get a reflection, KPI values and several moments; older days only a single moment.
    static let detailedDayCount = 15

    /// Creates fresh `DailyEntry` objects (without log entries) linked to the provided KPI templates.
    /// `days[i]` is always `i` days before today.
    static func makeSeedDays(templates: [KPITemplate], language: SeedLanguage = .en) -> [DailyEntry] {
        let cal = Calendar.current
        let d: [Date] = (0..<seedDayCount).map { cal.date(byAdding: .day, value: -$0, to: .now)! }

        let summaries: [String] = [
            "Got real work done in the morning, then drowned in email in the afternoon. The walk at lunch helped.",
            "A quiet day off. Long breakfast with the family, a run by the water, early to bed.",
            "Barely slept and felt it all day. Cancelled the evening plans and went to bed at nine.",
            "Mixed day: first draft done in a noisy café, good feedback in the afternoon.",
            "Wanted a focused day, got a scattered one. Tomorrow the phone stays in the bag.",
            "Productive and calm. Proof that the phone is the problem, not me.",
            "Good plan in the morning, meetings ate the rest. I need to protect my afternoons.",
            "Hard conversation, but I know where I stand now. The walk home did me good.",
            "Creative day away from the desk. Came home tired but inspired.",
            "The run was the best part. Email remains a fight I keep losing.",
            "Good start, then stuck waiting on others. Not everything is in my hands.",
            "One of those rare days where everything clicks. I want more of these.",
            "Lots of input, little output. Felt drained by the evening.",
            "Stressful news, but by the evening I had a plan. Still tense.",
            "Quiet admin day. Nothing exciting, but needed.",
        ]

        let entries: [DailyEntry] = d.enumerated().map { index, date in
            DailyEntry(date: date, summary: index < summaries.count ? summaries[index] : "")
        }
        entries[0].morning = "Block the morning for the quarterly report, get outside at lunch, be home in time for dinner."

        if language == .de {
            for entry in entries {
                if let localized = germanReflectionByEnglish[entry.summary] { entry.summary = localized }
                if let localized = germanReflectionByEnglish[entry.morning] { entry.morning = localized }
            }
        }

        let kpiTemplates = Array(templates.sorted(by: { $0.sortOrder < $1.sortOrder }).prefix(3))
        if kpiTemplates.count == 3 {
            let seedKPIValues: [(deepWorkMinutes: Int, sleepHours: Int, exerciseMinutes: Int)] = [
                (150, 7, 25), (0, 8, 50),   (20, 5, 10),  (95, 6, 20),
                (30, 6, 15),  (180, 7, 35), (60, 7, 20),  (40, 8, 40),
                (75, 7, 30),  (45, 8, 40),  (90, 6, 20),  (200, 7, 25),
                (50, 6, 10),  (80, 6, 15),  (70, 7, 20),
            ]
            for (entry, v) in zip(entries, seedKPIValues) {
                entry.kpiValues = [
                    DailyKPIValue(value: v.deepWorkMinutes, template: kpiTemplates[0], entry: entry),
                    DailyKPIValue(value: v.sleepHours,      template: kpiTemplates[1], entry: entry),
                    DailyKPIValue(value: v.exerciseMinutes, template: kpiTemplates[2], entry: entry),
                ]
            }
        }

        return entries
    }

    /// Creates `DailyLogEntry` objects for the given days with `entry` backlinks set.
    /// Pass the array returned by `makeSeedDays` — order and count must match.
    static func makeSeedLogEntries(for days: [DailyEntry], language: SeedLanguage = .en) -> [DailyLogEntry] {
        let cal = Calendar.current
        func time(_ hour: Int, _ minute: Int = 0, on base: Date) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        guard days.count == seedDayCount else { return [] }

        var all: [DailyLogEntry] = [
            // days[0] — today
            DailyLogEntry(timestamp: time(9,  0,  on: days[0].date),  log: "Two hours on the report without touching my phone. Finally the structure makes sense.", score:  2, entry: days[0],  latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Deep Work,Focus"),
            DailyLogEntry(timestamp: time(14, 30, on: days[0].date),  log: "Inbox at 140 again. Answered the urgent ones, the rest has to wait.",                    score: -1, entry: days[0],  latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Work Stress"),
            // days[1] — yesterday
            DailyLogEntry(timestamp: time(9,  30, on: days[1].date),  log: "Pancakes with the kids, nobody in a hurry for once.",                                    score:  2, entry: days[1],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Family"),
            DailyLogEntry(timestamp: time(16, 0,  on: days[1].date),  log: "8 km by the water. Legs heavy, head clear.",                                             score:  1, entry: days[1],                                                                 tagsRaw: "Sport,Outdoor"),
            // days[2] — 2 days ago
            DailyLogEntry(timestamp: time(9,  30, on: days[2].date),  log: "Woke up at 4 and couldn't fall asleep again. Everything feels like wading through mud.", score: -2, entry: days[2],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Sleep"),
            DailyLogEntry(timestamp: time(15, 0,  on: days[2].date),  log: "Snapped at the kids over nothing. Apologized, but it stays with me.",                    score: -2, entry: days[2],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Sleep,Family"),
            // days[3] — 3 days ago (deliberately long text to check wrapping in the UI)
            DailyLogEntry(timestamp: time(9,  0,  on: days[3].date),  log: "Worked at the café near the station because the house was too loud. Got the first draft of the proposal done, even though the people at the next table were discussing their wedding seating plan in great detail and I listened in more than I'd like to admit.", score: 0, entry: days[3], latitude: 37.7765, longitude: -122.4172, address: "Downtown Cafe", tagsRaw: "Deep Work"),
            DailyLogEntry(timestamp: time(14, 0,  on: days[3].date),  log: "Good call with the client. They liked the direction.",                                   score:  1, entry: days[3],  latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Focus"),
            // days[4] — 4 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[4].date),  log: "Went to the library to concentrate and spent the whole time reading the news. Annoyed with myself.", score: -1, entry: days[4], latitude: 37.7793, longitude: -122.4192, address: "Library", tagsRaw: "Work Stress"),
            // days[5] — 5 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[5].date),  log: "Phone in the bag, and it worked. Finished the budget plan before lunch.",                 score:  2, entry: days[5],  latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Deep Work,Focus"),
            DailyLogEntry(timestamp: time(14, 0,  on: days[5].date),  log: "Helped the new team member with the slides. Felt good to be useful.",                    score:  1, entry: days[5],  latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Focus"),
            // days[6] — 6 days ago
            DailyLogEntry(timestamp: time(9,  0,  on: days[6].date),  log: "Planned the week over coffee before anyone else was up.",                                score:  1, entry: days[6],  latitude: 37.7739, longitude: -122.4312, address: "Home Office",   tagsRaw: "Focus"),
            DailyLogEntry(timestamp: time(14, 0,  on: days[6].date),  log: "A \"quick sync\" that took 90 minutes. The afternoon was gone.",                         score: -1, entry: days[6],  latitude: 37.7739, longitude: -122.4312, address: "Home Office",   tagsRaw: "Work Stress"),
            // days[7] — 7 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[7].date),  log: "Long feedback round with the team. Honest, a bit uncomfortable, but useful.",            score:  0, entry: days[7],  latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Work Stress"),
            DailyLogEntry(timestamp: time(18, 0,  on: days[7].date),  log: "Walked home instead of taking the train. Sorted my thoughts on the way.",                score:  1, entry: days[7],                                                                 tagsRaw: "Outdoor"),
            // days[8] — 8 days ago
            DailyLogEntry(timestamp: time(11, 30, on: days[8].date),  log: "Workshop with the designers. Lots of sticky notes, surprisingly good ideas.",            score:  1, entry: days[8],  latitude: 37.7858, longitude: -122.4064, address: "Design Studio", tagsRaw: "Deep Work"),
            // days[9] — 9 days ago
            DailyLogEntry(timestamp: time(7,  0,  on: days[9].date),  log: "Morning run before work. Cold, dark, worth it.",                                         score:  1, entry: days[9],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Sport,Outdoor"),
            DailyLogEntry(timestamp: time(15, 0,  on: days[9].date),  log: "Tried to clear the inbox, gave up after an hour. It just fills up again.",               score: -1, entry: days[9],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Work Stress"),
            // days[10] — 10 days ago
            DailyLogEntry(timestamp: time(9,  0,  on: days[10].date), log: "Sketched the new process on paper first. Much clearer than starting on the laptop.",    score:  1, entry: days[10], latitude: 37.7858, longitude: -122.4064, address: "Design Studio", tagsRaw: "Deep Work,Focus"),
            DailyLogEntry(timestamp: time(15, 0,  on: days[10].date), log: "Stuck on a question nobody can answer before next week. Frustrating.",                  score: -1, entry: days[10], latitude: 37.7739, longitude: -122.4312, address: "Home Office",   tagsRaw: "Work Stress"),
            // days[11] — 11 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[11].date), log: "Three hours in flow. Forgot to eat lunch.",                                              score:  2, entry: days[11], latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Deep Work,Focus"),
            DailyLogEntry(timestamp: time(14, 0,  on: days[11].date), log: "Presented the results, and everyone actually listened.",                                 score:  1, entry: days[11], latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Focus"),
            // days[12] — 12 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[12].date), log: "Read reports all morning at the café. Useful, but my head is full.",                     score: -1, entry: days[12], latitude: 37.7765, longitude: -122.4172, address: "Cafe",          tagsRaw: "Focus"),
            // days[13] — 13 days ago
            DailyLogEntry(timestamp: time(9,  0,  on: days[13].date), log: "Deadline moved up by a week. Stomach in knots.",                                         score: -2, entry: days[13], latitude: 37.7739, longitude: -122.4312, address: "Home Office",   tagsRaw: "Work Stress"),
            DailyLogEntry(timestamp: time(14, 30, on: days[13].date), log: "Made a list of what can be cut. Feels a little more manageable.",                        score: -1, entry: days[13], latitude: 37.7739, longitude: -122.4312, address: "Home Office",   tagsRaw: "Work Stress"),
            // days[14] — 14 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[14].date), log: "Tidied up my notes and documents. Boring, but desk and head feel lighter.",              score:  0, entry: days[14], latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Deep Work"),
        ]

        // days[15...] — one moment per day, newest first
        for (day, moment) in zip(days[detailedDayCount...], quickMoments) {
            let coordinate = moment.address.flatMap { coordinateByAddress[$0] }
            all.append(DailyLogEntry(timestamp: time(moment.hour, moment.minute, on: day.date), log: moment.log, score: moment.score, entry: day,
                                     latitude: coordinate?.latitude, longitude: coordinate?.longitude, address: moment.address, tagsRaw: moment.tags))
        }

        if language == .de {
            for logEntry in all {
                if let localized = germanLogByEnglish[logEntry.log] { logEntry.log = localized }
                if let addr = logEntry.address, let localized = germanAddressByEnglish[addr] { logEntry.address = localized }
                logEntry.tagsRaw = logEntry.tags.map { germanTagByEnglish[$0] ?? $0 }.joined(separator: ",")
            }
        }

        return all
    }

    /// Single moments for the older days (`days[15...]`), newest first.
    private static let quickMoments: [(hour: Int, minute: Int, log: String, score: Int, tags: String, address: String?)] = [
        (8,  15, "Coffee on the balcony in the sun before everyone woke up.",          1, "Outdoor",                "Home"),
        (19, 30, "Board game night with the kids. I lost, gladly.",                    2, "Family",                 "Home"),
        (13, 0,  "Skipped lunch for a call that could have been an email.",           -1, "Work Stress",            "Office"),
        (7,  0,  "5 km easy run. Nothing special, just good.",                         1, "Sport,Outdoor",          nil),
        (22, 0,  "Couldn't switch off, scrolled until midnight.",                     -1, "Sleep",                  "Home"),
        (10, 30, "Finally solved the problem that's been bugging me for weeks.",       2, "Deep Work,Focus",        "Office"),
        (16, 0,  "Picked the kids up early and we went for ice cream.",                1, "Family,Outdoor",         nil),
        (11, 0,  "Ordinary workday. Nothing good, nothing bad.",                       0, "",                       "Office"),
        (9,  0,  "Slept nine hours. Feel like a new person.",                          2, "Sleep",                  "Home"),
        (15, 30, "Three meetings in a row, no break. My head is buzzing.",            -1, "Work Stress",            "Office"),
        (18, 0,  "Cooked together, everyone helped, almost no chaos.",                 1, "Family",                 "Home"),
        (12, 30, "Lunch in the park instead of at the desk.",                          1, "Outdoor",                nil),
        (10, 0,  "Worked through my to-do list at the library. Quiet and focused.",    1, "Focus",                  "Library"),
        (20, 0,  "Argument about screen time. Nobody won.",                           -1, "Family",                 "Home"),
        (6,  45, "Gym before work. Hard to get up, glad I did.",                       1, "Sport",                  nil),
        (17, 30, "Rewrote the draft. Honestly, it's better now.",                      1, "Deep Work",              "Home Office"),
        (14, 0,  "Feedback on my draft: rewrite half of it.",                         -1, "Work Stress",            "Home Office"),
        (21, 30, "Read a novel instead of my phone. Fell asleep early.",               1, "Sleep",                  "Home"),
        (11, 30, "Tired and unfocused. Got through the day somehow.",                 -1, "Sleep",                  "Office"),
        (10, 0,  "Hiked up the hill with the whole family. Great view, sore feet.",    2, "Family,Outdoor,Sport",   nil),
        (9,  30, "Quiet morning at the café with a notebook and no agenda.",           1, "Focus",                  "Cafe"),
        (16, 30, "Project kickoff. Lots of energy in the room.",                       1, "Focus",                  "Office"),
        (13, 0,  "Headache all afternoon.",                                           -1, "",                       "Home"),
        (19, 0,  "Called my parents. Long overdue, good conversation.",                1, "Family",                 "Home"),
        (8,  0,  "Caught in the rain on the way to work, forgot my umbrella.",        -1, "Outdoor",                nil),
        (15, 0,  "Went through the numbers, everything on track.",                     0, "Focus",                  "Office"),
        (10, 30, "Focus block cancelled because of an \"urgent\" request.",           -2, "Work Stress",            "Office"),
        (18, 30, "Played football in the garden until it got dark.",                   2, "Family,Sport,Outdoor",   "Home"),
        (7,  30, "Woke up before the alarm, rested for once.",                         1, "Sleep",                  "Home"),
        (14, 30, "Long workshop, lots of talk, few decisions.",                        0, "Work Stress",            "Design Studio"),
        (11, 0,  "Wrote the concept in one go. Felt easy for once.",                   2, "Deep Work,Focus",        "Home Office"),
        (20, 30, "The kids wouldn't go to bed. Evening gone.",                        -1, "Family",                 "Home"),
        (12, 0,  "Swimming at lunch. Thirty lengths.",                                 1, "Sport",                  nil),
        (16, 0,  "Couldn't concentrate, cleaned the kitchen instead.",                 0, "",                       "Home"),
        (9,  0,  "Train 40 minutes late. Read the whole time, not bad actually.",      0, "",                       nil),
        (10, 0,  "Day after the release: tired and empty.",                           -1, "Sleep",                  "Office"),
        (17, 0,  "The release is out. Relief.",                                        2, "Deep Work,Work Stress",  "Office"),
        (15, 30, "Bike ride along the river with our oldest.",                         2, "Family,Sport,Outdoor",   nil),
        (11, 0,  "Slowly back at work. The team covered for me.",                      1, "",                       "Office"),
        (14, 0,  "Still sick, but slept most of the day.",                             0, "Sleep",                  "Home"),
        (8,  30, "Woke up with a sore throat. Stayed home.",                          -1, "Sleep",                  "Home"),
        (19, 0,  "Dinner with friends. Laughed a lot.",                                2, "",                       "Downtown Cafe"),
        (13, 30, "Started the new project. Not sure yet where it's going.",            0, "Focus",                  "Office"),
        (10, 0,  "Cleared out the garage. Found things I had forgotten about.",        0, "Family",                 "Home"),
        (21, 0,  "Long walk in the evening. Exactly what I needed.",                   1, "Outdoor",                nil),
    ]

    private static let coordinateByAddress: [String: (latitude: Double, longitude: Double)] = [
        "Home": (37.7749, -122.4194),
        "Office": (37.3317, -122.0301),
        "Library": (37.7793, -122.4192),
        "Home Office": (37.7739, -122.4312),
        "Design Studio": (37.7858, -122.4064),
        "Downtown Cafe": (37.7765, -122.4172),
        "Cafe": (37.7765, -122.4172),
    ]

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

    /// Translations for the evening reflections (`summary`) and the morning forecast (`morning`).
    private static let germanReflectionByEnglish: [String: String] = [
        "Block the morning for the quarterly report, get outside at lunch, be home in time for dinner.": "Vormittag für den Quartalsbericht blocken, mittags kurz raus, pünktlich zum Abendessen zu Hause.",
        "Got real work done in the morning, then drowned in email in the afternoon. The walk at lunch helped.": "Vormittags richtig was geschafft, nachmittags im Mail-Chaos versackt. Der Spaziergang mittags hat geholfen.",
        "A quiet day off. Long breakfast with the family, a run by the water, early to bed.": "Ruhiger freier Tag. Langes Frühstück mit der Familie, eine Runde am Wasser gelaufen, früh ins Bett.",
        "Barely slept and felt it all day. Cancelled the evening plans and went to bed at nine.": "Kaum geschlafen und das den ganzen Tag gespürt. Abendtermin abgesagt und um neun ins Bett.",
        "Mixed day: first draft done in a noisy café, good feedback in the afternoon.": "Gemischter Tag: ersten Entwurf im lauten Café geschafft, nachmittags gutes Feedback.",
        "Wanted a focused day, got a scattered one. Tomorrow the phone stays in the bag.": "Wollte einen fokussierten Tag, wurde ein zerstreuter. Morgen bleibt das Handy in der Tasche.",
        "Productive and calm. Proof that the phone is the problem, not me.": "Produktiv und ruhig. Der Beweis, dass das Handy das Problem ist, nicht ich.",
        "Good plan in the morning, meetings ate the rest. I need to protect my afternoons.": "Morgens guter Plan, den Rest haben Meetings gefressen. Ich muss meine Nachmittage schützen.",
        "Hard conversation, but I know where I stand now. The walk home did me good.": "Schwieriges Gespräch, aber jetzt weiß ich, woran ich bin. Der Heimweg zu Fuß hat gutgetan.",
        "Creative day away from the desk. Came home tired but inspired.": "Kreativer Tag abseits vom Schreibtisch. Müde, aber inspiriert nach Hause gekommen.",
        "The run was the best part. Email remains a fight I keep losing.": "Das Laufen war das Beste am Tag. E-Mail bleibt ein Kampf, den ich immer wieder verliere.",
        "Good start, then stuck waiting on others. Not everything is in my hands.": "Guter Start, dann blockiert, weil ich auf andere warte. Nicht alles liegt in meiner Hand.",
        "One of those rare days where everything clicks. I want more of these.": "Einer dieser seltenen Tage, an denen alles passt. Davon will ich mehr.",
        "Lots of input, little output. Felt drained by the evening.": "Viel Input, wenig Output. Abends ausgelaugt.",
        "Stressful news, but by the evening I had a plan. Still tense.": "Stressige Nachricht, aber abends stand ein Plan. Trotzdem angespannt.",
        "Quiet admin day. Nothing exciting, but needed.": "Ruhiger Orga-Tag. Nichts Aufregendes, aber nötig.",
    ]

    private static let germanLogByEnglish: [String: String] = [
        // Detailed days
        "Two hours on the report without touching my phone. Finally the structure makes sense.": "Zwei Stunden am Bericht, ohne aufs Handy zu schauen. Endlich ergibt die Struktur Sinn.",
        "Inbox at 140 again. Answered the urgent ones, the rest has to wait.": "Postfach wieder bei 140. Das Dringende beantwortet, der Rest muss warten.",
        "Pancakes with the kids, nobody in a hurry for once.": "Pfannkuchen mit den Kindern, ausnahmsweise hatte es niemand eilig.",
        "8 km by the water. Legs heavy, head clear.": "8 km am Wasser entlang. Beine schwer, Kopf frei.",
        "Woke up at 4 and couldn't fall asleep again. Everything feels like wading through mud.": "Um 4 aufgewacht und nicht mehr eingeschlafen. Alles fühlt sich zäh an.",
        "Snapped at the kids over nothing. Apologized, but it stays with me.": "Die Kinder wegen nichts angeblafft. Entschuldigt, aber es hängt mir nach.",
        "Worked at the café near the station because the house was too loud. Got the first draft of the proposal done, even though the people at the next table were discussing their wedding seating plan in great detail and I listened in more than I'd like to admit.": "Im Café am Bahnhof gearbeitet, weil es zu Hause zu laut war. Den ersten Entwurf des Angebots geschafft, obwohl am Nebentisch sehr ausführlich die Sitzordnung einer Hochzeit besprochen wurde und ich mehr zugehört habe, als ich zugeben möchte.",
        "Good call with the client. They liked the direction.": "Gutes Telefonat mit dem Kunden. Die Richtung gefällt ihnen.",
        "Went to the library to concentrate and spent the whole time reading the news. Annoyed with myself.": "In die Bibliothek gegangen, um mich zu konzentrieren, und dann die ganze Zeit Nachrichten gelesen. Ärgere mich über mich selbst.",
        "Phone in the bag, and it worked. Finished the budget plan before lunch.": "Handy in der Tasche, und es hat funktioniert. Den Budgetplan vor dem Mittag fertig.",
        "Helped the new team member with the slides. Felt good to be useful.": "Dem neuen Teammitglied bei den Folien geholfen. Tat gut, nützlich zu sein.",
        "Planned the week over coffee before anyone else was up.": "Die Woche beim Kaffee geplant, bevor die anderen wach waren.",
        "A \"quick sync\" that took 90 minutes. The afternoon was gone.": "Ein „kurzer Abgleich“, der 90 Minuten dauerte. Der Nachmittag war weg.",
        "Long feedback round with the team. Honest, a bit uncomfortable, but useful.": "Lange Feedbackrunde im Team. Ehrlich, etwas unangenehm, aber hilfreich.",
        "Walked home instead of taking the train. Sorted my thoughts on the way.": "Zu Fuß nach Hause statt mit der Bahn. Unterwegs die Gedanken sortiert.",
        "Workshop with the designers. Lots of sticky notes, surprisingly good ideas.": "Workshop mit dem Designteam. Viele Post-its, überraschend gute Ideen.",
        "Morning run before work. Cold, dark, worth it.": "Vor der Arbeit laufen gewesen. Kalt, dunkel, hat sich gelohnt.",
        "Tried to clear the inbox, gave up after an hour. It just fills up again.": "Versucht, das Postfach leer zu bekommen, nach einer Stunde aufgegeben. Es läuft einfach wieder voll.",
        "Sketched the new process on paper first. Much clearer than starting on the laptop.": "Den neuen Ablauf erst auf Papier skizziert. Viel klarer, als gleich am Laptop anzufangen.",
        "Stuck on a question nobody can answer before next week. Frustrating.": "Hänge an einer Frage fest, die vor nächster Woche niemand beantworten kann. Frustrierend.",
        "Three hours in flow. Forgot to eat lunch.": "Drei Stunden am Stück im Flow. Das Mittagessen vergessen.",
        "Presented the results, and everyone actually listened.": "Ergebnisse präsentiert, und alle haben wirklich zugehört.",
        "Read reports all morning at the café. Useful, but my head is full.": "Den ganzen Vormittag im Café Berichte gelesen. Nützlich, aber der Kopf ist voll.",
        "Deadline moved up by a week. Stomach in knots.": "Deadline um eine Woche vorgezogen. Das liegt mir im Magen.",
        "Made a list of what can be cut. Feels a little more manageable.": "Eine Liste gemacht, was wegfallen kann. Fühlt sich etwas machbarer an.",
        "Tidied up my notes and documents. Boring, but desk and head feel lighter.": "Notizen und Unterlagen aufgeräumt. Langweilig, aber Schreibtisch und Kopf fühlen sich leichter an.",
        // Quick moments
        "Coffee on the balcony in the sun before everyone woke up.": "Kaffee auf dem Balkon in der Sonne, bevor alle wach waren.",
        "Board game night with the kids. I lost, gladly.": "Spieleabend mit den Kindern. Verloren, aber gern.",
        "Skipped lunch for a call that could have been an email.": "Mittagspause für ein Telefonat geopfert, das auch eine Mail hätte sein können.",
        "5 km easy run. Nothing special, just good.": "5 km locker gelaufen. Nichts Besonderes, einfach gut.",
        "Couldn't switch off, scrolled until midnight.": "Nicht abschalten können, bis Mitternacht gescrollt.",
        "Finally solved the problem that's been bugging me for weeks.": "Endlich das Problem gelöst, das mich seit Wochen nervt.",
        "Picked the kids up early and we went for ice cream.": "Die Kinder früher abgeholt und Eis essen gegangen.",
        "Ordinary workday. Nothing good, nothing bad.": "Ganz normaler Arbeitstag. Nichts Gutes, nichts Schlechtes.",
        "Slept nine hours. Feel like a new person.": "Neun Stunden geschlafen. Fühle mich wie neu.",
        "Three meetings in a row, no break. My head is buzzing.": "Drei Meetings am Stück ohne Pause. Mir brummt der Schädel.",
        "Cooked together, everyone helped, almost no chaos.": "Zusammen gekocht, alle haben mitgeholfen, fast kein Chaos.",
        "Lunch in the park instead of at the desk.": "Mittagessen im Park statt am Schreibtisch.",
        "Worked through my to-do list at the library. Quiet and focused.": "In der Bibliothek die To-do-Liste abgearbeitet. Ruhig und konzentriert.",
        "Argument about screen time. Nobody won.": "Streit über Bildschirmzeit. Gewonnen hat niemand.",
        "Gym before work. Hard to get up, glad I did.": "Vor der Arbeit im Fitnessstudio. Schwer aufgestanden, aber froh darüber.",
        "Rewrote the draft. Honestly, it's better now.": "Den Entwurf neu geschrieben. Ehrlich gesagt ist er jetzt besser.",
        "Feedback on my draft: rewrite half of it.": "Feedback zum Entwurf: die Hälfte neu schreiben.",
        "Read a novel instead of my phone. Fell asleep early.": "Roman gelesen statt Handy. Früh eingeschlafen.",
        "Tired and unfocused. Got through the day somehow.": "Müde und unkonzentriert. Irgendwie durch den Tag gekommen.",
        "Hiked up the hill with the whole family. Great view, sore feet.": "Mit der ganzen Familie auf den Berg gewandert. Tolle Aussicht, müde Füße.",
        "Quiet morning at the café with a notebook and no agenda.": "Ruhiger Vormittag im Café, mit Notizbuch und ohne Plan.",
        "Project kickoff. Lots of energy in the room.": "Projekt-Kickoff. Viel Energie im Raum.",
        "Headache all afternoon.": "Den ganzen Nachmittag Kopfschmerzen.",
        "Called my parents. Long overdue, good conversation.": "Mit meinen Eltern telefoniert. Längst überfällig, gutes Gespräch.",
        "Caught in the rain on the way to work, forgot my umbrella.": "Auf dem Weg zur Arbeit in den Regen gekommen, Schirm vergessen.",
        "Went through the numbers, everything on track.": "Zahlen durchgesehen, alles im Plan.",
        "Focus block cancelled because of an \"urgent\" request.": "Fokuszeit wegen einer „dringenden“ Anfrage geplatzt.",
        "Played football in the garden until it got dark.": "Im Garten Fußball gespielt, bis es dunkel wurde.",
        "Woke up before the alarm, rested for once.": "Vor dem Wecker aufgewacht, ausnahmsweise ausgeschlafen.",
        "Long workshop, lots of talk, few decisions.": "Langer Workshop, viel geredet, wenig entschieden.",
        "Wrote the concept in one go. Felt easy for once.": "Das Konzept in einem Rutsch geschrieben. Ging ausnahmsweise leicht.",
        "The kids wouldn't go to bed. Evening gone.": "Die Kinder wollten nicht ins Bett. Abend weg.",
        "Swimming at lunch. Thirty lengths.": "Mittags schwimmen. Dreißig Bahnen.",
        "Couldn't concentrate, cleaned the kitchen instead.": "Konnte mich nicht konzentrieren, stattdessen die Küche geputzt.",
        "Train 40 minutes late. Read the whole time, not bad actually.": "Zug 40 Minuten verspätet. Die ganze Zeit gelesen, eigentlich gar nicht schlecht.",
        "Day after the release: tired and empty.": "Tag nach dem Release: müde und leer.",
        "The release is out. Relief.": "Das Release ist raus. Erleichterung.",
        "Bike ride along the river with our oldest.": "Fahrradtour am Fluss mit unserem ältesten Kind.",
        "Slowly back at work. The team covered for me.": "Langsam wieder bei der Arbeit. Das Team hat mich vertreten.",
        "Still sick, but slept most of the day.": "Immer noch krank, aber fast den ganzen Tag geschlafen.",
        "Woke up with a sore throat. Stayed home.": "Mit Halsweh aufgewacht. Zu Hause geblieben.",
        "Dinner with friends. Laughed a lot.": "Abendessen mit Freunden. Viel gelacht.",
        "Started the new project. Not sure yet where it's going.": "Mit dem neuen Projekt begonnen. Noch unklar, wohin es geht.",
        "Cleared out the garage. Found things I had forgotten about.": "Garage ausgemistet. Dinge gefunden, die ich vergessen hatte.",
        "Long walk in the evening. Exactly what I needed.": "Langer Abendspaziergang. Genau das, was ich gebraucht habe.",
    ]

    /// Creates an in-memory container seeded in `language`.
    init(language: SeedLanguage = .current) {
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

            let templates = SampleData.makeSeedTemplates(language: language)
            for template in templates {
                modelContainer.mainContext.insert(template)
            }

            let days = SampleData.makeSeedDays(templates: templates, language: language)
            for day in days {
                modelContainer.mainContext.insert(day)
            }
            for logEntry in SampleData.makeSeedLogEntries(for: days, language: language) {
                modelContainer.mainContext.insert(logEntry)
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
