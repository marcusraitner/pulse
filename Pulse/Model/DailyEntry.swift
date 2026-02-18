//
//  DailyEntry.swift
//  collins score
//
//  Created by Marcus Raitner on 12.05.25.
//

import Foundation
import SwiftData
import SwiftUI

enum PulseVersionedSchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [DailyEntry.self, DailyLogEntry.self]
    }
    
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    @Model
    final class DailyEntry {
        
        // The date of this entry; each day can have at most one entry
        var date: Date = Date.now
        
        /// Calcuates the average score of the log entries
        var averageScore: CGFloat {
            if let logEntries {
                let sum = logEntries.reduce(into: 0.0, { sum, x in
                    sum += CGFloat(x.score)
                })
                return CGFloat(logEntries.isEmpty ? 0.0 : sum / CGFloat(logEntries.count))
            } else {
                return 0
            }
        }
        
        // The summary of the day
        @Relationship(deleteRule: .cascade, inverse: \DailyLogEntry.entry)
        var logEntries: [DailyLogEntry]? = []
        
        init(
            date: Date,
            logEntries: [DailyLogEntry] = [],
        ) {
            self.date = date
            self.logEntries = logEntries
        }
    }
    
    @Model
    class DailyLogEntry: Identifiable {
        var id = UUID()
        var timestamp: Date = Date.now
        var log: String = ""
        var score: Int = 0
        var entry: DailyEntry?
        
        var formatedTimestamp: String {
            self.timestamp.formatted(.dateTime.hour().minute())
        }
        
        init(timestamp: Date, log: String, score: Int, entry: DailyEntry? = nil) {
            self.timestamp = timestamp
            self.log = log
            self.score = score
            self.entry = entry
        }
    }
}

typealias DailyEntry = PulseVersionedSchemaV1.DailyEntry
typealias DailyLogEntry = PulseVersionedSchemaV1.DailyLogEntry
