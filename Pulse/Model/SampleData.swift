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

        // Reflections loosely follow the guiding questions (`stoic.reflection.1…3`): a role filled well,
        // something outside my control, one small thing to do differently tomorrow.
        let summaries: [String] = [
            "", // today: reflection left open
            "At breakfast I was fully there, phone in the drawer. The neighbours' party went on past midnight – not mine to control. Tomorrow: earplugs on the nightstand.",
            "Not a good day with the kids, but I apologized and meant it. The sleepless night wasn't my choice; my mood afterwards partly was. Tomorrow: breathe first, then react.",
            "Took care of myself today: three chapters and a check-up with good results. The noise in the café wasn't mine to control. Tomorrow: book the next check-up before I forget.",
            "Studying didn't work out today. The building work outside the library wasn't my fault – reaching for the news was. Tomorrow the phone stays in the bag.",
            "Good neighbourliness today, and the vocabulary is done. The lift was broken again – three floors on foot, nothing to be done. Tomorrow: ask how the new sofa is holding up.",
            "Did my part well in the meeting, even though it dragged on. That it ran 90 minutes wasn't my call. Tomorrow: block two hours in the afternoon in my calendar.",
            "Listened at the parent-teacher meeting instead of getting defensive. Class sizes and the teacher shortage are beyond my control. Tomorrow: 20 minutes of homework together.",
            "Held my part in the choir, even in the tricky verse. The rehearsal room was freezing again – the heating isn't mine to fix. Tomorrow: five minutes of warming up my voice in the morning.",
            "Kept my promise to myself and went running before work. The bureaucratic language in those letters isn't mine to change. Tomorrow: one envelope from the pile, not the whole pile.",
            "Patient with the kids' hundred questions in the garden. The washing machine breaking down was bad luck, nothing more. Tomorrow: ask the neighbours if we can use theirs.",
            "Did good work and looked after our friends well, all in one day. The pizza arrived cold – nothing to be done. Tomorrow: eat a proper lunch.",
            "Wasn't really present in any role today. World events aren't in my hands; how much of them I consume is. Tomorrow: news once at noon, then off.",
            "Sat down together as a team and made a plan. The rent increase is beyond our control; our budget isn't. Tomorrow: cancel the streaming subscription we never use.",
            "Quiet household day; finally tackled the kids' cupboard. It rained all day, so the bike ride was off – not mine to control. Tomorrow: ride, whatever the weather.",
        ]

        // Forecasts as premeditatio: anticipate what might be hard today.
        let forecasts: [String] = [
            "App review might reject the v2.5 build over some detail – that's not in my hands, only how carefully I prepare it.",
            "The kids will want everything at once on a free day – I don't have to fill every hour.",
            "After this night I'll be short-tempered – the kids aren't to blame for my tiredness.",
            "The blood test results could be bad news – worrying beforehand won't change them.",
            "The urge to check my phone will come every few minutes – I can notice it without following it.",
            "Something will get in the way of my study plan – I can be flexible without dropping it.",
            "Meetings will eat into my afternoon – how much I let that annoy me is up to me.",
            "The teacher might criticise our child – I want to listen before I defend.",
            "I'll probably mess up the tricky verse again – that's what rehearsals are for.",
            "The paperwork will feel overwhelming – one sheet at a time is enough.",
            "Something will go wrong today that I didn't plan for – I'll deal with it when it comes.",
            "Colleagues will interrupt my focus – I can protect it without being unfriendly.",
            "The news will try to pull me in all morning – I choose what I let in.",
            "Bad news might come in the post – panicking won't make it any smaller.",
            "The weather may spoil our plans – there's always something to do at home.",
        ]

        let entries: [DailyEntry] = d.enumerated().map { index, date in
            DailyEntry(date: date,
                       summary: index < summaries.count ? summaries[index] : "",
                       morning: index < forecasts.count ? forecasts[index] : "")
        }

        if language == .de {
            for entry in entries {
                if let localized = germanReflectionByEnglish[entry.summary] { entry.summary = localized }
                if let localized = germanReflectionByEnglish[entry.morning] { entry.morning = localized }
            }
        }

        let kpiTemplates = Array(templates.sorted(by: { $0.sortOrder < $1.sortOrder }).prefix(3))
        if kpiTemplates.count == 3 {
            let seedKPIValues: [(deepWorkMinutes: Int, sleepHours: Int, exerciseMinutes: Int)] = [
                (120, 7, 15), (0, 8, 50),   (20, 5, 10),  (30, 6, 20),
                (30, 6, 15),  (90, 7, 35),  (60, 7, 20),  (40, 8, 40),
                (20, 7, 30),  (45, 8, 40),  (20, 6, 40),  (200, 7, 25),
                (30, 6, 10),  (40, 6, 15),  (0, 7, 20),
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
            // days[0] — today (early times, so moments added by hand land after them)
            DailyLogEntry(timestamp: time(7,  30, on: days[0].date),  log: "Ran the whole test suite before breakfast – green on the first try. I'll take it.", score:  1, entry: days[0],  latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Focus"),
            DailyLogEntry(timestamp: time(8,  15, on: days[0].date),  log: "The App Store screenshots are out of date again – the new forecast card is missing.", score: -1, entry: days[0],  latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Work Stress"),
            DailyLogEntry(timestamp: time(9,  0,  on: days[0].date),  log: "Went through the v2.5 release notes in German and English. Cut two sentences, now they read well.", score:  1, entry: days[0],  latitude: 37.7739, longitude: -122.4312, address: "Home Office", tagsRaw: "Deep Work,Focus"),
            // days[1] — yesterday
            DailyLogEntry(timestamp: time(9,  30, on: days[1].date),  log: "Pancakes with the kids, nobody in a hurry for once.",                                    score:  2, entry: days[1],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Family"),
            DailyLogEntry(timestamp: time(16, 0,  on: days[1].date),  log: "8 km by the water. Legs heavy, head clear.",                                             score:  1, entry: days[1],                                                                 tagsRaw: "Sport,Outdoor"),
            // days[2] — 2 days ago
            DailyLogEntry(timestamp: time(9,  30, on: days[2].date),  log: "Woke up at 4 and couldn't fall asleep again. Everything feels like wading through mud.", score: -2, entry: days[2],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Sleep"),
            DailyLogEntry(timestamp: time(15, 0,  on: days[2].date),  log: "Snapped at the kids over nothing. Apologized, but it stays with me.",                    score: -2, entry: days[2],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Sleep,Family"),
            // days[3] — 3 days ago (deliberately long text to check wrapping in the UI)
            DailyLogEntry(timestamp: time(9,  0,  on: days[3].date),  log: "Sat in the café by the station with a book I've been meaning to finish for months. Got through three chapters, even though the couple at the next table were planning their wedding seating chart in great detail and I listened in more than I'd like to admit.", score: 1, entry: days[3], latitude: 37.7765, longitude: -122.4172, address: "Downtown Cafe", tagsRaw: "Focus"),
            DailyLogEntry(timestamp: time(14, 0,  on: days[3].date),  log: "Doctor's appointment: blood test results all fine. Relieved.",                           score:  1, entry: days[3]),
            // days[4] — 4 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[4].date),  log: "Went to the library to study for the language course and spent the whole time reading the news. Annoyed with myself.", score: -1, entry: days[4], latitude: 37.7793, longitude: -122.4192, address: "Library", tagsRaw: "Focus"),
            // days[5] — 5 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[5].date),  log: "Phone in the bag, and it worked. Learned all the vocabulary for the next lesson.",       score:  2, entry: days[5],  latitude: 37.7793, longitude: -122.4192, address: "Library",       tagsRaw: "Focus"),
            DailyLogEntry(timestamp: time(16, 0,  on: days[5].date),  log: "Helped the neighbours carry a new sofa up three floors. Got coffee and a long chat in return.", score: 1, entry: days[5], latitude: 37.7749, longitude: -122.4194, address: "Home",       tagsRaw: "Sport"),
            // days[6] — 6 days ago
            DailyLogEntry(timestamp: time(9,  0,  on: days[6].date),  log: "Planned the week over coffee before anyone else was up.",                                score:  1, entry: days[6],  latitude: 37.7739, longitude: -122.4312, address: "Home Office",   tagsRaw: "Focus"),
            DailyLogEntry(timestamp: time(14, 0,  on: days[6].date),  log: "A \"quick sync\" that took 90 minutes. The afternoon was gone.",                         score: -1, entry: days[6],  latitude: 37.7739, longitude: -122.4312, address: "Home Office",   tagsRaw: "Work Stress"),
            // days[7] — 7 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[7].date),  log: "Parent-teacher meeting. Honest, a bit uncomfortable, but useful.",                       score:  0, entry: days[7],                                                                 tagsRaw: "Family"),
            DailyLogEntry(timestamp: time(18, 0,  on: days[7].date),  log: "Walked home instead of taking the train. Sorted my thoughts on the way.",                score:  1, entry: days[7],                                                                 tagsRaw: "Outdoor"),
            // days[8] — 8 days ago
            DailyLogEntry(timestamp: time(19, 30, on: days[8].date),  log: "Choir rehearsal. We finally nailed the tricky part in the second verse.",                score:  2, entry: days[8]),
            // days[9] — 9 days ago
            DailyLogEntry(timestamp: time(7,  0,  on: days[9].date),  log: "Morning run before work. Cold, dark, worth it.",                                         score:  1, entry: days[9],  latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Sport,Outdoor"),
            DailyLogEntry(timestamp: time(20, 0,  on: days[9].date),  log: "Tried to sort the pile of paperwork on the kitchen table, gave up after an hour.",       score: -1, entry: days[9],  latitude: 37.7749, longitude: -122.4194, address: "Home"),
            // days[10] — 10 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[10].date), log: "Planted tulip bulbs with the kids. Muddy hands, lots of questions.",                     score:  1, entry: days[10], latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Family,Outdoor"),
            DailyLogEntry(timestamp: time(15, 0,  on: days[10].date), log: "Washing machine broke down. Nobody can come to repair it before next week.",              score: -1, entry: days[10], latitude: 37.7749, longitude: -122.4194, address: "Home"),
            // days[11] — 11 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[11].date), log: "Three hours in flow at work. Forgot to eat lunch.",                                      score:  2, entry: days[11], latitude: 37.3317, longitude: -122.0301, address: "Office",        tagsRaw: "Deep Work,Focus"),
            DailyLogEntry(timestamp: time(20, 0,  on: days[11].date), log: "Friends dropped by unannounced. We ordered pizza and talked until late.",                 score:  1, entry: days[11], latitude: 37.7749, longitude: -122.4194, address: "Home"),
            // days[12] — 12 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[12].date), log: "Read the news all morning at the café. Too much bad news, my head is full.",              score: -1, entry: days[12], latitude: 37.7765, longitude: -122.4172, address: "Cafe"),
            // days[13] — 13 days ago
            DailyLogEntry(timestamp: time(9,  0,  on: days[13].date), log: "Letter from the property management: the rent is going up. Stomach in knots.",          score: -2, entry: days[13], latitude: 37.7749, longitude: -122.4194, address: "Home"),
            DailyLogEntry(timestamp: time(20, 30, on: days[13].date), log: "Went through our budget together. Feels a little more manageable.",                     score:  0, entry: days[13], latitude: 37.7749, longitude: -122.4194, address: "Home",          tagsRaw: "Family"),
            // days[14] — 14 days ago
            DailyLogEntry(timestamp: time(10, 0,  on: days[14].date), log: "Sorted out the kids' clothes and took a bag to the donation bin. Boring, but cupboard and head feel lighter.", score: 0, entry: days[14], latitude: 37.7749, longitude: -122.4194, address: "Home", tagsRaw: "Family"),
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
        (11, 0,  "Waited an hour at the doctor's for a five-minute appointment.",     -1, "",                       nil),
        (7,  0,  "5 km easy run. Nothing special, just good.",                         1, "Sport,Outdoor",          nil),
        (22, 0,  "Couldn't switch off, scrolled until midnight.",                     -1, "Sleep",                  "Home"),
        (17, 0,  "Fixed the dripping tap myself. Unreasonably proud.",                 2, "",                       "Home"),
        (16, 0,  "Picked the kids up early and we went for ice cream.",                1, "Family,Outdoor",         nil),
        (11, 0,  "Ordinary workday. Nothing good, nothing bad.",                       0, "",                       "Office"),
        (9,  0,  "Slept nine hours. Feel like a new person.",                          2, "Sleep",                  "Home"),
        (15, 30, "Three meetings in a row, no break. My head is buzzing.",            -1, "Work Stress",            "Office"),
        (18, 0,  "Cooked together, everyone helped, almost no chaos.",                 1, "Family",                 "Home"),
        (12, 30, "Lunch in the park instead of at the desk.",                          1, "Outdoor",                nil),
        (10, 0,  "Read at the library for two hours. Quiet and focused.",              1, "Focus",                  "Library"),
        (20, 0,  "Argument about screen time. Nobody won.",                           -1, "Family",                 "Home"),
        (6,  45, "Gym before work. Hard to get up, glad I did.",                       1, "Sport",                  nil),
        (21, 0,  "Half an hour of guitar. The chord change finally works.",            1, "Focus",                  "Home"),
        (17, 30, "Tried a new bread recipe. Flat as a pancake.",                       0, "Family",                 "Home"),
        (21, 30, "Read a novel instead of my phone. Fell asleep early.",               1, "Sleep",                  "Home"),
        (11, 30, "Tired and unfocused. Got through the day somehow.",                 -1, "Sleep",                  "Office"),
        (10, 0,  "Hiked up the hill with the whole family. Great view, sore feet.",    2, "Family,Outdoor,Sport",   nil),
        (9,  30, "Quiet morning at the café with a notebook and no agenda.",           1, "Focus",                  "Cafe"),
        (14, 0,  "Helped out at the food bank. Tiring, but the good kind of tired.",   1, "",                       nil),
        (13, 0,  "Headache all afternoon.",                                           -1, "",                       "Home"),
        (19, 0,  "Called my parents. Long overdue, good conversation.",                1, "Family",                 "Home"),
        (8,  0,  "Caught in the rain on the way to work, forgot my umbrella.",        -1, "Outdoor",                nil),
        (20, 0,  "Long phone call with my sister. We should do that more often.",      1, "Family",                 "Home"),
        (7,  30, "Overslept, rushed, forgot the lunch boxes. Bad start.",             -2, "Family,Sleep",           "Home"),
        (18, 30, "Played football in the garden until it got dark.",                   2, "Family,Sport,Outdoor",   "Home"),
        (7,  15, "Woke up before the alarm, rested for once.",                         1, "Sleep",                  "Home"),
        (20, 30, "Parents' evening at school: lots of talk, few decisions.",           0, "Family",                 nil),
        (16, 0,  "Wrote a long letter to an old school friend. Came easily for once.", 2, "",                       "Home"),
        (20, 45, "The kids wouldn't go to bed. Evening gone.",                        -1, "Family",                 "Home"),
        (12, 0,  "Swimming at lunch. Thirty lengths.",                                 1, "Sport",                  nil),
        (16, 0,  "Couldn't concentrate, cleaned the kitchen instead.",                 0, "",                       "Home"),
        (9,  0,  "Train 40 minutes late. Read the whole time, not bad actually.",      0, "",                       nil),
        (10, 0,  "Day after painting: sore arms, everything smells of paint.",        -1, "",                       "Home"),
        (18, 0,  "The flat is finally painted. Relief.",                               2, "Family",                 "Home"),
        (15, 30, "Bike ride along the river with our oldest.",                         2, "Family,Sport,Outdoor",   nil),
        (11, 0,  "Slowly back to normal. The neighbours had done our shopping.",       1, "",                       "Home"),
        (14, 0,  "Still sick, but slept most of the day.",                             0, "Sleep",                  "Home"),
        (8,  30, "Woke up with a sore throat. Stayed home.",                          -1, "Sleep",                  "Home"),
        (19, 0,  "Dinner with friends. Laughed a lot.",                                2, "",                       "Downtown Cafe"),
        (19, 30, "First lesson of the Spanish course. Understood almost nothing, loved it.", 1, "Focus",            "Library"),
        (10, 0,  "Cleared out the garage. Found things I had forgotten about.",        0, "Family",                 "Home"),
        (21, 0,  "Long walk in the evening. Exactly what I needed.",                   1, "Outdoor",                nil),
    ]

    private static let coordinateByAddress: [String: (latitude: Double, longitude: Double)] = [
        "Home": (37.7749, -122.4194),
        "Office": (37.3317, -122.0301),
        "Library": (37.7793, -122.4192),
        "Home Office": (37.7739, -122.4312),
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
        "App review might reject the v2.5 build over some detail – that's not in my hands, only how carefully I prepare it.": "Das App-Review könnte den Build von v2.5 wegen einer Kleinigkeit ablehnen – das liegt nicht in meiner Hand, nur wie sorgfältig ich ihn vorbereite.",
        "The kids will want everything at once on a free day – I don't have to fill every hour.": "Die Kinder werden am freien Tag alles auf einmal wollen – ich muss nicht jede Stunde füllen.",
        "After this night I'll be short-tempered – the kids aren't to blame for my tiredness.": "Nach dieser Nacht werde ich gereizt sein – die Kinder können nichts für meine Müdigkeit.",
        "The blood test results could be bad news – worrying beforehand won't change them.": "Die Blutwerte könnten schlechte Nachrichten bringen – Sorgen vorher ändern nichts daran.",
        "The urge to check my phone will come every few minutes – I can notice it without following it.": "Der Drang, aufs Handy zu schauen, wird alle paar Minuten kommen – ich kann ihn bemerken, ohne ihm zu folgen.",
        "Something will get in the way of my study plan – I can be flexible without dropping it.": "Irgendetwas wird meinen Lernplan durchkreuzen – ich kann flexibel sein, ohne ihn aufzugeben.",
        "Meetings will eat into my afternoon – how much I let that annoy me is up to me.": "Meetings werden mir den Nachmittag wegfressen – wie sehr ich mich darüber ärgere, entscheide ich.",
        "The teacher might criticise our child – I want to listen before I defend.": "Die Lehrkraft könnte unser Kind kritisieren – ich will zuhören, bevor ich verteidige.",
        "I'll probably mess up the tricky verse again – that's what rehearsals are for.": "Ich werde die schwierige Strophe wohl wieder verpatzen – genau dafür ist die Probe da.",
        "The paperwork will feel overwhelming – one sheet at a time is enough.": "Der Papierkram wird mich erschlagen wollen – ein Blatt nach dem anderen reicht.",
        "Something will go wrong today that I didn't plan for – I'll deal with it when it comes.": "Heute wird etwas schiefgehen, das ich nicht eingeplant habe – ich kümmere mich darum, wenn es so weit ist.",
        "Colleagues will interrupt my focus – I can protect it without being unfriendly.": "Kolleginnen und Kollegen werden meine Konzentration stören – ich kann sie schützen, ohne unfreundlich zu sein.",
        "The news will try to pull me in all morning – I choose what I let in.": "Die Nachrichten werden mich den ganzen Vormittag hineinziehen wollen – was ich hereinlasse, entscheide ich.",
        "Bad news might come in the post – panicking won't make it any smaller.": "Mit der Post könnten schlechte Nachrichten kommen – Panik macht sie nicht kleiner.",
        "The weather may spoil our plans – there's always something to do at home.": "Das Wetter könnte unsere Pläne durchkreuzen – zu Hause gibt es immer etwas zu tun.",
        "At breakfast I was fully there, phone in the drawer. The neighbours' party went on past midnight – not mine to control. Tomorrow: earplugs on the nightstand.": "Beim Frühstück war ich ganz da, das Handy in der Schublade. Die Party der Nachbarn ging bis nach Mitternacht – liegt nicht in meiner Hand. Morgen: Ohrstöpsel auf den Nachttisch.",
        "Not a good day with the kids, but I apologized and meant it. The sleepless night wasn't my choice; my mood afterwards partly was. Tomorrow: breathe first, then react.": "Kein guter Tag mit den Kindern, aber ich habe mich entschuldigt und es ernst gemeint. Die schlaflose Nacht konnte ich mir nicht aussuchen, meine Laune danach zum Teil schon. Morgen: erst durchatmen, dann reagieren.",
        "Took care of myself today: three chapters and a check-up with good results. The noise in the café wasn't mine to control. Tomorrow: book the next check-up before I forget.": "Heute gut für mich selbst gesorgt: drei Kapitel und ein Check-up mit guten Ergebnissen. Den Lärm im Café konnte ich nicht beeinflussen. Morgen: den nächsten Termin gleich ausmachen.",
        "Studying didn't work out today. The building work outside the library wasn't my fault – reaching for the news was. Tomorrow the phone stays in the bag.": "Mit dem Lernen hat es heute nicht geklappt. Für den Baulärm vor der Bibliothek kann ich nichts – für den Griff zu den Nachrichten schon. Morgen bleibt das Handy in der Tasche.",
        "Good neighbourliness today, and the vocabulary is done. The lift was broken again – three floors on foot, nothing to be done. Tomorrow: ask how the new sofa is holding up.": "Heute gute Nachbarschaft gelebt, und die Vokabeln sitzen. Der Aufzug war mal wieder kaputt – also drei Stockwerke zu Fuß, nicht zu ändern. Morgen: nachfragen, wie sich das neue Sofa macht.",
        "Did my part well in the meeting, even though it dragged on. That it ran 90 minutes wasn't my call. Tomorrow: block two hours in the afternoon in my calendar.": "Im Meeting habe ich meinen Teil gut gemacht, auch wenn es sich zog. Dass es 90 Minuten dauerte, lag nicht bei mir. Morgen: zwei Stunden am Nachmittag im Kalender blocken.",
        "Listened at the parent-teacher meeting instead of getting defensive. Class sizes and the teacher shortage are beyond my control. Tomorrow: 20 minutes of homework together.": "Beim Elterngespräch zugehört, statt mich zu verteidigen. Klassengröße und Lehrermangel liegen nicht in meiner Hand. Morgen: 20 Minuten gemeinsam Hausaufgaben machen.",
        "Held my part in the choir, even in the tricky verse. The rehearsal room was freezing again – the heating isn't mine to fix. Tomorrow: five minutes of warming up my voice in the morning.": "Im Chor meine Stimme gehalten, auch in der schwierigen Strophe. Der Probenraum war wieder eiskalt – die Heizung kann ich nicht reparieren. Morgen: fünf Minuten Einsingen am Morgen.",
        "Kept my promise to myself and went running before work. The bureaucratic language in those letters isn't mine to change. Tomorrow: one envelope from the pile, not the whole pile.": "Mein Versprechen an mich gehalten und vor der Arbeit gelaufen. Das Amtsdeutsch in den Briefen kann ich nicht ändern. Morgen: ein Umschlag vom Stapel, nicht der ganze Stapel.",
        "Patient with the kids' hundred questions in the garden. The washing machine breaking down was bad luck, nothing more. Tomorrow: ask the neighbours if we can use theirs.": "Im Garten geduldig mit den hundert Fragen der Kinder gewesen. Dass die Waschmaschine kaputtgeht, war Pech, mehr nicht. Morgen: die Nachbarn fragen, ob wir ihre mitbenutzen dürfen.",
        "Did good work and looked after our friends well, all in one day. The pizza arrived cold – nothing to be done. Tomorrow: eat a proper lunch.": "Am selben Tag gute Arbeit gemacht und Freunde gut bewirtet. Die Pizza kam kalt an – nicht zu ändern. Morgen: richtig zu Mittag essen.",
        "Wasn't really present in any role today. World events aren't in my hands; how much of them I consume is. Tomorrow: news once at noon, then off.": "Heute in keiner Rolle wirklich da gewesen. Das Weltgeschehen liegt nicht in meiner Hand, wie viel ich davon konsumiere schon. Morgen: einmal mittags Nachrichten, dann aus.",
        "Sat down together as a team and made a plan. The rent increase is beyond our control; our budget isn't. Tomorrow: cancel the streaming subscription we never use.": "Gemeinsam hingesetzt und als Team einen Plan gemacht. Die Mieterhöhung liegt nicht in unserer Hand, unser Budget schon. Morgen: das Streaming-Abo kündigen, das wir nie nutzen.",
        "Quiet household day; finally tackled the kids' cupboard. It rained all day, so the bike ride was off – not mine to control. Tomorrow: ride, whatever the weather.": "Ruhiger Haushaltstag; endlich den Kinderschrank angepackt. Es hat den ganzen Tag geregnet, die Radtour fiel aus – nicht zu ändern. Morgen: fahren, egal bei welchem Wetter.",
    ]

    private static let germanLogByEnglish: [String: String] = [
        // Detailed days
        "Ran the whole test suite before breakfast – green on the first try. I'll take it.": "Vor dem Frühstück die ganze Testsuite laufen lassen – auf Anhieb grün. Nehme ich.",
        "The App Store screenshots are out of date again – the new forecast card is missing.": "Die App-Store-Screenshots sind schon wieder veraltet – die neue Forecast-Karte fehlt.",
        "Went through the v2.5 release notes in German and English. Cut two sentences, now they read well.": "Die Release Notes für v2.5 auf Deutsch und Englisch durchgegangen. Zwei Sätze gestrichen, jetzt lesen sie sich gut.",
        "Pancakes with the kids, nobody in a hurry for once.": "Pfannkuchen mit den Kindern, ausnahmsweise hatte es niemand eilig.",
        "8 km by the water. Legs heavy, head clear.": "8 km am Wasser entlang. Beine schwer, Kopf frei.",
        "Woke up at 4 and couldn't fall asleep again. Everything feels like wading through mud.": "Um 4 aufgewacht und nicht mehr eingeschlafen. Alles fühlt sich zäh an.",
        "Snapped at the kids over nothing. Apologized, but it stays with me.": "Die Kinder wegen nichts angeblafft. Entschuldigt, aber es hängt mir nach.",
        "Sat in the café by the station with a book I've been meaning to finish for months. Got through three chapters, even though the couple at the next table were planning their wedding seating chart in great detail and I listened in more than I'd like to admit.": "Im Café am Bahnhof mit einem Buch gesessen, das ich seit Monaten zu Ende lesen will. Drei Kapitel geschafft, obwohl das Paar am Nebentisch sehr ausführlich die Sitzordnung seiner Hochzeit geplant hat und ich mehr zugehört habe, als ich zugeben möchte.",
        "Doctor's appointment: blood test results all fine. Relieved.": "Arzttermin: Blutwerte alle in Ordnung. Erleichtert.",
        "Went to the library to study for the language course and spent the whole time reading the news. Annoyed with myself.": "In die Bibliothek gegangen, um für den Sprachkurs zu lernen, und dann die ganze Zeit Nachrichten gelesen. Ärgere mich über mich selbst.",
        "Phone in the bag, and it worked. Learned all the vocabulary for the next lesson.": "Handy in der Tasche, und es hat funktioniert. Alle Vokabeln für die nächste Stunde gelernt.",
        "Helped the neighbours carry a new sofa up three floors. Got coffee and a long chat in return.": "Den Nachbarn geholfen, ein neues Sofa drei Stockwerke hochzutragen. Dafür gab es Kaffee und ein langes Gespräch.",
        "Planned the week over coffee before anyone else was up.": "Die Woche beim Kaffee geplant, bevor die anderen wach waren.",
        "A \"quick sync\" that took 90 minutes. The afternoon was gone.": "Ein „kurzer Abgleich“, der 90 Minuten dauerte. Der Nachmittag war weg.",
        "Parent-teacher meeting. Honest, a bit uncomfortable, but useful.": "Elterngespräch in der Schule. Ehrlich, etwas unangenehm, aber hilfreich.",
        "Walked home instead of taking the train. Sorted my thoughts on the way.": "Zu Fuß nach Hause statt mit der Bahn. Unterwegs die Gedanken sortiert.",
        "Choir rehearsal. We finally nailed the tricky part in the second verse.": "Chorprobe. Endlich die schwierige Stelle in der zweiten Strophe hinbekommen.",
        "Morning run before work. Cold, dark, worth it.": "Vor der Arbeit laufen gewesen. Kalt, dunkel, hat sich gelohnt.",
        "Tried to sort the pile of paperwork on the kitchen table, gave up after an hour.": "Versucht, den Papierstapel auf dem Küchentisch zu sortieren, nach einer Stunde aufgegeben.",
        "Planted tulip bulbs with the kids. Muddy hands, lots of questions.": "Mit den Kindern Tulpenzwiebeln gepflanzt. Matschige Hände, viele Fragen.",
        "Washing machine broke down. Nobody can come to repair it before next week.": "Waschmaschine kaputt. Vor nächster Woche kann niemand zur Reparatur kommen.",
        "Three hours in flow at work. Forgot to eat lunch.": "Drei Stunden am Stück im Flow bei der Arbeit. Das Mittagessen vergessen.",
        "Friends dropped by unannounced. We ordered pizza and talked until late.": "Spontan kamen Freunde vorbei. Pizza bestellt und bis spät geredet.",
        "Read the news all morning at the café. Too much bad news, my head is full.": "Den ganzen Vormittag im Café Nachrichten gelesen. Zu viele schlechte Nachrichten, der Kopf ist voll.",
        "Letter from the property management: the rent is going up. Stomach in knots.": "Brief von der Hausverwaltung: Die Miete steigt. Das liegt mir im Magen.",
        "Went through our budget together. Feels a little more manageable.": "Zusammen unser Budget durchgerechnet. Fühlt sich etwas machbarer an.",
        "Sorted out the kids' clothes and took a bag to the donation bin. Boring, but cupboard and head feel lighter.": "Kinderkleidung aussortiert und eine Tüte zum Altkleidercontainer gebracht. Langweilig, aber Schrank und Kopf fühlen sich leichter an.",
        // Quick moments
        "Coffee on the balcony in the sun before everyone woke up.": "Kaffee auf dem Balkon in der Sonne, bevor alle wach waren.",
        "Board game night with the kids. I lost, gladly.": "Spieleabend mit den Kindern. Verloren, aber gern.",
        "Waited an hour at the doctor's for a five-minute appointment.": "Eine Stunde beim Arzt gewartet für einen Termin von fünf Minuten.",
        "5 km easy run. Nothing special, just good.": "5 km locker gelaufen. Nichts Besonderes, einfach gut.",
        "Couldn't switch off, scrolled until midnight.": "Nicht abschalten können, bis Mitternacht gescrollt.",
        "Fixed the dripping tap myself. Unreasonably proud.": "Den tropfenden Wasserhahn selbst repariert. Unverhältnismäßig stolz.",
        "Picked the kids up early and we went for ice cream.": "Die Kinder früher abgeholt und Eis essen gegangen.",
        "Ordinary workday. Nothing good, nothing bad.": "Ganz normaler Arbeitstag. Nichts Gutes, nichts Schlechtes.",
        "Slept nine hours. Feel like a new person.": "Neun Stunden geschlafen. Fühle mich wie neu.",
        "Three meetings in a row, no break. My head is buzzing.": "Drei Meetings am Stück ohne Pause. Mir brummt der Schädel.",
        "Cooked together, everyone helped, almost no chaos.": "Zusammen gekocht, alle haben mitgeholfen, fast kein Chaos.",
        "Lunch in the park instead of at the desk.": "Mittagessen im Park statt am Schreibtisch.",
        "Read at the library for two hours. Quiet and focused.": "Zwei Stunden in der Bibliothek gelesen. Ruhig und konzentriert.",
        "Argument about screen time. Nobody won.": "Streit über Bildschirmzeit. Gewonnen hat niemand.",
        "Gym before work. Hard to get up, glad I did.": "Vor der Arbeit im Fitnessstudio. Schwer aufgestanden, aber froh darüber.",
        "Half an hour of guitar. The chord change finally works.": "Eine halbe Stunde Gitarre geübt. Der Akkordwechsel klappt endlich.",
        "Tried a new bread recipe. Flat as a pancake.": "Neues Brotrezept ausprobiert. Platt wie eine Flunder.",
        "Read a novel instead of my phone. Fell asleep early.": "Roman gelesen statt Handy. Früh eingeschlafen.",
        "Tired and unfocused. Got through the day somehow.": "Müde und unkonzentriert. Irgendwie durch den Tag gekommen.",
        "Hiked up the hill with the whole family. Great view, sore feet.": "Mit der ganzen Familie auf den Berg gewandert. Tolle Aussicht, müde Füße.",
        "Quiet morning at the café with a notebook and no agenda.": "Ruhiger Vormittag im Café, mit Notizbuch und ohne Plan.",
        "Helped out at the food bank. Tiring, but the good kind of tired.": "Bei der Tafel ausgeholfen. Anstrengend, aber auf die gute Art.",
        "Headache all afternoon.": "Den ganzen Nachmittag Kopfschmerzen.",
        "Called my parents. Long overdue, good conversation.": "Mit meinen Eltern telefoniert. Längst überfällig, gutes Gespräch.",
        "Caught in the rain on the way to work, forgot my umbrella.": "Auf dem Weg zur Arbeit in den Regen gekommen, Schirm vergessen.",
        "Long phone call with my sister. We should do that more often.": "Langes Telefonat mit meiner Schwester. Sollten wir öfter machen.",
        "Overslept, rushed, forgot the lunch boxes. Bad start.": "Verschlafen, gehetzt, die Brotdosen vergessen. Schlechter Start.",
        "Played football in the garden until it got dark.": "Im Garten Fußball gespielt, bis es dunkel wurde.",
        "Woke up before the alarm, rested for once.": "Vor dem Wecker aufgewacht, ausnahmsweise ausgeschlafen.",
        "Parents' evening at school: lots of talk, few decisions.": "Elternabend in der Schule: viel geredet, wenig entschieden.",
        "Wrote a long letter to an old school friend. Came easily for once.": "Einem alten Schulfreund einen langen Brief geschrieben. Ging ausnahmsweise leicht.",
        "The kids wouldn't go to bed. Evening gone.": "Die Kinder wollten nicht ins Bett. Abend weg.",
        "Swimming at lunch. Thirty lengths.": "Mittags schwimmen. Dreißig Bahnen.",
        "Couldn't concentrate, cleaned the kitchen instead.": "Konnte mich nicht konzentrieren, stattdessen die Küche geputzt.",
        "Train 40 minutes late. Read the whole time, not bad actually.": "Zug 40 Minuten verspätet. Die ganze Zeit gelesen, eigentlich gar nicht schlecht.",
        "Day after painting: sore arms, everything smells of paint.": "Tag nach dem Streichen: Muskelkater in den Armen, alles riecht nach Farbe.",
        "The flat is finally painted. Relief.": "Die Wohnung ist endlich gestrichen. Erleichterung.",
        "Bike ride along the river with our oldest.": "Fahrradtour am Fluss mit unserem ältesten Kind.",
        "Slowly back to normal. The neighbours had done our shopping.": "Langsam wieder normal. Die Nachbarn hatten für uns eingekauft.",
        "Still sick, but slept most of the day.": "Immer noch krank, aber fast den ganzen Tag geschlafen.",
        "Woke up with a sore throat. Stayed home.": "Mit Halsweh aufgewacht. Zu Hause geblieben.",
        "Dinner with friends. Laughed a lot.": "Abendessen mit Freunden. Viel gelacht.",
        "First lesson of the Spanish course. Understood almost nothing, loved it.": "Erste Stunde im Spanischkurs. Fast nichts verstanden, trotzdem toll.",
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
