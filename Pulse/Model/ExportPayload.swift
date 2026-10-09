//
//  ExportPayload.swift
//  Pulse
//
//  Created by Marcus Raitner on 20.05.26.
//

import Foundation

// MARK: - KPITemplate
struct KPITemplateDTO: Codable {
    let id: UUID
    let title: String
    let note: String?
    let unit: String?
    let sortOrder: Int
}

private extension KPITemplate {
    func toExport() -> KPITemplateDTO {
        KPITemplateDTO(
            id: id,
            title: title,
            note: note,
            unit: unit,
            sortOrder: sortOrder
        )
    }
}

// MARK: - DailyKPIValue
struct DailyKPIValueDTO: Codable {
    let value: Int
    let templateID: UUID?
}

private extension DailyKPIValue {
    func toExport() -> DailyKPIValueDTO {
        DailyKPIValueDTO(
            value: value,
            templateID: template?.id
        )
    }
}

// MARK: - DailyLogEntry

struct DailyLogEntryDTO: Codable {
    let id: UUID
    let timestamp: Date
    let log: String
    let score: Int
    let latitude: Double?
    let longitude: Double?
    let address: String?
    let tagsRaw: String
}

private extension DailyLogEntry {
    func toExport() -> DailyLogEntryDTO {
        DailyLogEntryDTO(
            id: id,
            timestamp: timestamp,
            log: log,
            score: score,
            latitude: latitude,
            longitude: longitude,
            address: address,
            tagsRaw: tagsRaw)
    }
}

// MARK: - DailyEntry

struct DailyEntryDTO: Codable {
    let date: Date
    let morning: String
    let summary: String
    let logEntries: [DailyLogEntryDTO]
    let kpiValues: [DailyKPIValueDTO]
}

private extension DailyEntry {
    func toExport(tags: Set<String>?) -> DailyEntryDTO {
        let mappedLogEntries = (logEntries ?? [])
            .filter { logEntry in
                guard let tags else { return true }
                return logEntry.tags.contains { tags.contains($0) }
            }
            .sorted { $0.timestamp < $1.timestamp }
            .map { $0.toExport() }

        let mappedKPIValues = (kpiValues ?? [])
            .sorted {
                if let template1 = $0.template, let template2 = $1.template {
                    return template1.sortOrder < template2.sortOrder
                } else {
                    return $0.value < $1.value
                }
            }
            .map( { $0.toExport() })
        
        return DailyEntryDTO(
            date: date,
            morning: morning,
            summary: summary,
            logEntries: mappedLogEntries,
            kpiValues: mappedKPIValues
        )
    }
}

struct ExportPayload: Codable {
    let exportedAt: Date
    let modelSchemaVersion: String
    let formatVersion: String
    let entries: [DailyEntryDTO]
    let kpiTemplates: [KPITemplateDTO]
}

enum ExportPayloadMapper {
    static let currentModelSchemaVersion = "1.5.0"
    static let currentFormatVersion: String = "1.0.0"
    
    /// - Parameters:
    ///   - dateRange: When set, only entries whose `date` falls within the range are exported.
    ///   - tags: When set, only log entries carrying at least one of these tags are exported (OR-matched);
    ///     the parent `DailyEntry` is still exported even if none of its log entries match. `nil` exports all log entries.
    static func exportPayload(
        from entries: [DailyEntry],
        kpiTemplates: [KPITemplate],
        dateRange: ClosedRange<Date>? = nil,
        tags: Set<String>? = nil
    ) -> ExportPayload {
        let filteredEntries = entries.filter { entry in
            guard let dateRange else { return true }
            return dateRange.contains(entry.date)
        }

        return ExportPayload(
            exportedAt: .now,
            modelSchemaVersion: currentModelSchemaVersion,
            formatVersion: currentFormatVersion,
            entries: filteredEntries
                .sorted { $0.date < $1.date }
                .map { $0.toExport(tags: tags) },
            kpiTemplates: kpiTemplates
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { $0.toExport() }
        )
    }
}
