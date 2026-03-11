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

enum PulseVersionedSchemaV110: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [DailyEntry.self, DailyLogEntry.self]
    }
    
    static var versionIdentifier = Schema.Version(1, 1, 0)
    
    @Model
    final class DailyEntry {
        
        // The date of this entry; each day can have at most one entry
        var date: Date = Date.now
        
        var summary: String = ""
        
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
            summary: String = "",
            logEntries: [DailyLogEntry] = [],
        ) {
            self.date = date
            self.summary = summary
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

enum PulseVersionedSchemaV120: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [DailyEntry.self, DailyLogEntry.self]
    }
    
    static var versionIdentifier = Schema.Version(1, 2, 0)
    
    @Model
    final class DailyEntry {
        
        // The date of this entry; each day can have at most one entry
        var date: Date = Date.now
        
        var summary: String = ""
        
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
            summary: String = "",
            logEntries: [DailyLogEntry] = [],
        ) {
            self.date = date
            self.summary = summary
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
 
        // New fields
        var latitude: Double?
        var longitude: Double?
        var address: String?
        
        var formatedTimestamp: String {
            self.timestamp.formatted(.dateTime.hour().minute())
        }
        
        init(timestamp: Date, log: String, score: Int, entry: DailyEntry? = nil, latitude: Double? = nil, longitude: Double? = nil, address: String? = nil) {
            self.timestamp = timestamp
            self.log = log
            self.score = score
            self.entry = entry
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
        }
    }
}

enum PulseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PulseVersionedSchemaV1.self, PulseVersionedSchemaV110.self, PulseVersionedSchemaV120.self]
    }
    
    static let migrateV1toV110 = MigrationStage.custom(
        fromVersion: PulseVersionedSchemaV1.self,
        toVersion: PulseVersionedSchemaV110.self,
        willMigrate: nil,
        didMigrate: { context in
            // remove all stale log entries
            let descriptor = FetchDescriptor<DailyLogEntry>(predicate: #Predicate { $0.entry == nil })
            
            try context.enumerate(descriptor) { logEntry in
                context.delete(logEntry)
            }
            
            try context.save()
        }
    )
    
    static let migrateV110toV120: MigrationStage =
        .lightweight(fromVersion: PulseVersionedSchemaV110.self, toVersion: PulseVersionedSchemaV120.self)
    
    static var stages: [MigrationStage] {
        [migrateV1toV110, migrateV110toV120]
    }
        
}

typealias DailyEntry = PulseVersionedSchemaV120.DailyEntry
typealias DailyLogEntry = PulseVersionedSchemaV120.DailyLogEntry
