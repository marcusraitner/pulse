//
//  DailyReflectionCard.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI
import SwiftData

/// Displays a glass card with the day's reflection summary and top metrics. Tapping invokes `onTap`.
struct DailyReflectionCard: View {
    let day: DailyEntry
    /// Called when the user taps the card to open the reflection sheet.
    let onTap: () -> Void

    @Query(sort: \KPITemplate.sortOrder) private var allTemplates: [KPITemplate]
    private var topTemplates: [KPITemplate] { Array(allTemplates.prefix(3)) }

    private func recordedValue(for template: KPITemplate) -> Int? {
        day.kpiValues?.first { $0.template?.id == template.id }?.value
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Reflection")
                .bold()
                .italic()
                .padding(.bottom, 4)

            if !day.summary.isEmpty {
                Text(day.summary)
            }
            
            if !topTemplates.isEmpty {
                metricsRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            ForEach(topTemplates) { template in
                VStack(spacing: 2) {
                    if let val = recordedValue(for: template) {
                        Text("\(val)")
                            .font(.headline)
                        if let unit = template.unit, !unit.isEmpty {
                            Text(unit)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("—")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Text(template.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                if template.id != topTemplates.last?.id {
                    Rectangle()
                        .fill(.secondary)
                        .frame(width: 1, height: 30)
                }
            }
        }
        .padding(.top, 8)
    }
}

#Preview("Empty") {
    DailyReflectionCard(day: DailyEntry(date: .now), onTap: {})
        .modelContainer(SampleData.shared.modelContainer)
        .background(.black)
}

#Preview("With summary") {
    DailyReflectionCard(day: DailyEntry(date: .now, summary: "Had a great day overall. Felt productive and calm."), onTap: {})
        .modelContainer(SampleData.shared.modelContainer)
        .background(.black)
}
