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
    let summary: String
    let logEntries: [DailyLogEntryDTO]
    let kpiValues: [DailyKPIValueDTO]
}

private extension DailyEntry {
    func toExport() -> DailyEntryDTO {
        let mappedLogEntries = (logEntries ?? [])
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
    
    static func exportPayload(from entries: [DailyEntry], kpiTemplates: [KPITemplate]) -> ExportPayload {
        return ExportPayload(
            exportedAt: .now,
            modelSchemaVersion: currentModelSchemaVersion,
            formatVersion: currentFormatVersion,
            entries: entries
                .sorted { $0.date < $1.date }
                .map { $0.toExport() },
            kpiTemplates: kpiTemplates
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { $0.toExport() }
        )
    }
}
