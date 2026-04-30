//
//  DailyEntry.swift
//  collins score
//
//  Created by Marcus Raitner on 12.05.25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Schema V1.0.0

/// Initial schema. Contains `DailyEntry` and `DailyLogEntry` without a summary field.
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
            guard let logEntries, !logEntries.isEmpty else { return 0 }
            return logEntries.reduce(0) { $0 + CGFloat($1.score) } / CGFloat(logEntries.count)
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
        
        var formattedTimestamp: String {
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

// MARK: - Schema V1.1.0

/// Adds `summary` to `DailyEntry`. Migration removes orphaned log entries (entries without a parent day).
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
            guard let logEntries, !logEntries.isEmpty else { return 0 }
            return logEntries.reduce(0) { $0 + CGFloat($1.score) } / CGFloat(logEntries.count)
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
        
        var formattedTimestamp: String {
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

// MARK: - Schema V1.2.0

/// Adds optional `latitude`, `longitude`, and `address` fields to `DailyLogEntry`.
/// Migration from V1.1.0 is lightweight (no data transformation needed).
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
            guard let logEntries, !logEntries.isEmpty else { return 0 }
            return logEntries.reduce(0) { $0 + CGFloat($1.score) } / CGFloat(logEntries.count)
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
 
        // TODO: Check if an MKMapItem or CLCoordinate would be more suitable?
        // New fields
        var latitude: Double?
        var longitude: Double?
        var address: String?
        
        var formattedTimestamp: String {
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

// MARK: - Schema V1.3.0

/// Adds `KPITemplate` and `DailyKPIValue` models. `DailyEntry` gains a `kpiValues` relationship.
/// Migration from V1.2.0 is lightweight (additive only, no data transformation needed).
enum PulseVersionedSchemaV130: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [DailyEntry.self, DailyLogEntry.self, DailyKPIValue.self, KPITemplate.self]
    }

    static var versionIdentifier = Schema.Version(1, 3, 0)

    @Model
    final class DailyEntry {
        var date: Date = Date.now
        var summary: String = ""

        /// Calculates the average score of the log entries.
        var averageScore: CGFloat {
            guard let logEntries, !logEntries.isEmpty else { return 0 }
            return logEntries.reduce(0) { $0 + CGFloat($1.score) } / CGFloat(logEntries.count)
        }

        @Relationship(deleteRule: .cascade, inverse: \DailyLogEntry.entry)
        var logEntries: [DailyLogEntry]? = []

        @Relationship(deleteRule: .cascade, inverse: \DailyKPIValue.entry)
        var kpiValues: [DailyKPIValue]? = []

        init(date: Date, summary: String = "", logEntries: [DailyLogEntry] = []) {
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

        var latitude: Double?
        var longitude: Double?
        var address: String?

        var formattedTimestamp: String {
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

    /// A KPI value recorded for a specific day's entry.
    /// Title, note, and unit are looked up via the `template` relationship.
    @Model
    final class DailyKPIValue {
        var value: Int = 0
        var template: KPITemplate?
        var entry: DailyEntry?

        init(value: Int, template: KPITemplate? = nil, entry: DailyEntry? = nil) {
            self.value = value
            self.template = template
            self.entry = entry
        }
    }

    /// A reusable KPI definition configured by the user in Settings.
    /// Synced via CloudKit so templates are available on all devices.
    /// Cascade delete automatically removes all associated `DailyKPIValue` records.
    @Model
    final class KPITemplate {
        var id: UUID = UUID()
        var title: String = ""
        var note: String?
        var unit: String?

        @Relationship(deleteRule: .cascade, inverse: \DailyKPIValue.template)
        var values: [DailyKPIValue]? = []

        init(title: String, note: String? = nil, unit: String? = nil) {
            self.title = title
            self.note = note
            self.unit = unit
        }
    }
}

// MARK: - Schema V1.4.0

/// Adds `sortOrder` to `KPITemplate` to support stable, user-defined ordering.
/// Migration from V1.3.0 is lightweight (additive field with a default value).
enum PulseVersionedSchemaV140: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [DailyEntry.self, DailyLogEntry.self, DailyKPIValue.self, KPITemplate.self]
    }

    static var versionIdentifier = Schema.Version(1, 4, 0)

    @Model
    final class DailyEntry {
        var date: Date = Date.now
        var summary: String = ""

        var averageScore: CGFloat {
            guard let logEntries, !logEntries.isEmpty else { return 0 }
            return logEntries.reduce(0) { $0 + CGFloat($1.score) } / CGFloat(logEntries.count)
        }

        @Relationship(deleteRule: .cascade, inverse: \DailyLogEntry.entry)
        var logEntries: [DailyLogEntry]? = []

        @Relationship(deleteRule: .cascade, inverse: \DailyKPIValue.entry)
        var kpiValues: [DailyKPIValue]? = []

        init(date: Date, summary: String = "", logEntries: [DailyLogEntry] = []) {
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

        var latitude: Double?
        var longitude: Double?
        var address: String?

        var formattedTimestamp: String {
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

    /// A KPI value recorded for a specific day's entry.
    /// Title, note, and unit are looked up via the `template` relationship.
    @Model
    final class DailyKPIValue {
        var value: Int = 0
        var template: KPITemplate?
        var entry: DailyEntry?

        init(value: Int, template: KPITemplate? = nil, entry: DailyEntry? = nil) {
            self.value = value
            self.template = template
            self.entry = entry
        }
    }

    /// A reusable KPI definition configured by the user in Settings.
    /// Synced via CloudKit so templates are available on all devices.
    /// Cascade delete automatically removes all associated `DailyKPIValue` records.
    /// `sortOrder` controls display order; the top 3 appear on the ReflectionCard.
    @Model
    final class KPITemplate {
        var id: UUID = UUID()
        var title: String = ""
        var note: String?
        var unit: String?
        var sortOrder: Int = 0

        @Relationship(deleteRule: .cascade, inverse: \DailyKPIValue.template)
        var values: [DailyKPIValue]? = []

        init(title: String, note: String? = nil, unit: String? = nil, sortOrder: Int = 0) {
            self.title = title
            self.note = note
            self.unit = unit
            self.sortOrder = sortOrder
        }
    }
}

// MARK: - Schema V1.5.0

/// Adds `tagsRaw` to `DailyLogEntry` for comma-separated tag storage, and introduces
/// the standalone `Tag` model as a user-managed palette of custom tag names.
/// `Tag` has no relationship to `DailyLogEntry` — many-to-many relationships are not
/// supported by CloudKit. The actual tags on each entry are stored in `tagsRaw`.
/// Migration from V1.4.0 is lightweight (additive fields/model with defaults).
enum PulseVersionedSchemaV150: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [DailyEntry.self, DailyLogEntry.self, DailyKPIValue.self, KPITemplate.self, Tag.self]
    }

    static var versionIdentifier = Schema.Version(1, 5, 0)

    @Model
    final class DailyEntry {
        var date: Date = Date.now
        var summary: String = ""

        var averageScore: CGFloat {
            guard let logEntries, !logEntries.isEmpty else { return 0 }
            return logEntries.reduce(0) { $0 + CGFloat($1.score) } / CGFloat(logEntries.count)
        }

        @Relationship(deleteRule: .cascade, inverse: \DailyLogEntry.entry)
        var logEntries: [DailyLogEntry]? = []

        @Relationship(deleteRule: .cascade, inverse: \DailyKPIValue.entry)
        var kpiValues: [DailyKPIValue]? = []

        init(date: Date, summary: String = "", logEntries: [DailyLogEntry] = []) {
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

        var latitude: Double?
        var longitude: Double?
        var address: String?
        
        var tagsRaw: String = ""
        
        var tags: [String] {
            tagsRaw.split(separator: ",")
                .map( { $0.trimmingCharacters(in: .whitespacesAndNewlines) } )
                .filter( { !$0.isEmpty } )
        }

        var formattedTimestamp: String {
            self.timestamp.formatted(.dateTime.hour().minute())
        }

        init(timestamp: Date, log: String, score: Int, entry: DailyEntry? = nil, latitude: Double? = nil, longitude: Double? = nil, address: String? = nil, tagsRaw: String = "") {
            self.timestamp = timestamp
            self.log = log
            self.score = score
            self.entry = entry
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.tagsRaw = tagsRaw
        }
    }

    /// A KPI value recorded for a specific day's entry.
    /// Title, note, and unit are looked up via the `template` relationship.
    @Model
    final class DailyKPIValue {
        var value: Int = 0
        var template: KPITemplate?
        var entry: DailyEntry?

        init(value: Int, template: KPITemplate? = nil, entry: DailyEntry? = nil) {
            self.value = value
            self.template = template
            self.entry = entry
        }
    }

    /// A reusable KPI definition configured by the user in Settings.
    /// Synced via CloudKit so templates are available on all devices.
    /// Cascade delete automatically removes all associated `DailyKPIValue` records.
    /// `sortOrder` controls display order; the top 3 appear on the ReflectionCard.
    @Model
    final class KPITemplate {
        var id: UUID = UUID()
        var title: String = ""
        var note: String?
        var unit: String?
        var sortOrder: Int = 0

        @Relationship(deleteRule: .cascade, inverse: \DailyKPIValue.template)
        var values: [DailyKPIValue]? = []

        init(title: String, note: String? = nil, unit: String? = nil, sortOrder: Int = 0) {
            self.title = title
            self.note = note
            self.unit = unit
            self.sortOrder = sortOrder
        }
    }
    
    /// A user-defined custom tag name, synced via CloudKit so the tag palette is
    /// available across all devices. Not related to `DailyLogEntry` directly —
    /// entry tags are stored as comma-separated values in `DailyLogEntry.tagsRaw`.
    @Model
    final class Tag {
        var name: String = ""

        init(name: String) {
            self.name = name
        }
    }
}

// MARK: - Migration Plan

/// Defines the ordered migration path across all schema versions.
enum PulseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PulseVersionedSchemaV1.self,
         PulseVersionedSchemaV110.self,
         PulseVersionedSchemaV120.self,
         PulseVersionedSchemaV130.self,
         PulseVersionedSchemaV140.self,
         PulseVersionedSchemaV150.self]
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

    static let migrateV120toV130: MigrationStage =
        .lightweight(fromVersion: PulseVersionedSchemaV120.self, toVersion: PulseVersionedSchemaV130.self)

    static let migrateV130toV140: MigrationStage =
        .lightweight(fromVersion: PulseVersionedSchemaV130.self, toVersion: PulseVersionedSchemaV140.self)

    static let migrateV140toV150: MigrationStage =
        .lightweight(fromVersion: PulseVersionedSchemaV140.self, toVersion: PulseVersionedSchemaV150.self)

    static var stages: [MigrationStage] {
        [migrateV1toV110, migrateV110toV120, migrateV120toV130, migrateV130toV140, migrateV140toV150]
    }
}

// MARK: - Current type aliases

/// The current `DailyEntry` model. Always points to the latest schema version.
typealias DailyEntry = PulseVersionedSchemaV150.DailyEntry
/// The current `DailyLogEntry` model. Always points to the latest schema version.
typealias DailyLogEntry = PulseVersionedSchemaV150.DailyLogEntry
/// A KPI value recorded for a specific day's entry.
typealias DailyKPIValue = PulseVersionedSchemaV150.DailyKPIValue
/// A reusable KPI definition configured by the user in Settings.
typealias KPITemplate = PulseVersionedSchemaV150.KPITemplate
/// A user-defined custom tag name synced via CloudKit.
typealias Tag = PulseVersionedSchemaV150.Tag
