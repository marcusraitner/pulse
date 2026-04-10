//
//  AggregatedTimelineView.swift
//  Pulse
//
//  Created by Marcus Raitner on 10.04.26.
//

import SwiftUI
import SwiftData
import OSLog

enum AggregationLevel {
    case week
    case month
}


struct AggregatedTimelineView: View {
    var aggregationLevel: AggregationLevel = .week
    private var component: Calendar.Component {
        aggregationLevel == .week ? .weekOfYear : .month
    }
    
    @State private var containerWidth: CGFloat = 0.0
    @State private var cardWidth: CGFloat = 0.0
    @State private var selectedStartDate: Date = .now
    @State private var position: ScrollPosition = .init(idType: Date.self)
    
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "AggregatedTimelineView")
    
    // One entry per period that has at least one DailyEntry
    private var periodStarts: [Date] {
        let cal = Calendar.current
        let starts = allEntries.compactMap { cal.dateInterval(of: component, for: $0.date)?.start }
        return Array(Set(starts)).sorted()
    }
    
    private func entries(for periodStart: Date) -> [DailyEntry] {
        let cal = Calendar.current
        let periodEnd = cal.date(byAdding: component, value: 1, to: periodStart) ?? periodStart
        return allEntries.filter { $0.date >= periodStart && $0.date < periodEnd }
    }
    
    private func days(for periodStart: Date) -> [Date : DailyEntry?] {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: component, for: periodStart)
        var current = interval?.start ?? .now
        let end = interval?.end ?? .now
        var days: [Date : DailyEntry?] = [:]
        
        while current < end {
            days.updateValue(nil, forKey: current)
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        
        for entry in entries(for: periodStart) {
            if let interval = cal.dateInterval(of: .day, for: entry.date) {
                days[interval.start] = entry
            }
        }
        
        return days
    }
    
    var body: some View {
        let heightScale: CGFloat = 20
        let totalHeight: CGFloat = 4 * heightScale
        let width = aggregationLevel == .week ? 8.0 : 6.0
        let cardWidth: CGFloat = aggregationLevel == .week ? 7 * (width + 2) : 31 * (width + 2)
        
        SelectedDateView(date: selectedStartDate, level: aggregationLevel)
            .padding(.vertical)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(periodStarts, id: \.self) { periodStart in
                    HStack(spacing: 2) {
                        ForEach(days(for: periodStart).sorted(by: { $0.key < $1.key }), id: \.key) { (day, entry) in
                            if let entry {
                                let avg: CGFloat = entry.averageScore
                                let barHeight: CGFloat = max(2, heightScale * avg.magnitude)
                                let yOffset: CGFloat = -0.5 * heightScale * avg
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.named(themeName).gradient(for: entry.averageScore))
                                    .frame(width: width, height: barHeight)
                                    .offset(y: yOffset)
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.clear)
                                    .frame(width: width, height: totalHeight)
                            }
                        }
                    }
                    .frame(width: cardWidth, height: totalHeight)
                    .padding(10)
                    .glassBackground()
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    .id(periodStart)
                    .onTapGesture {
                        withAnimation(.default) {
                            position.scrollTo(
                                id: periodStart,
                                anchor: .center
                            )
                        }
                    }
                }
            }
            .scrollTargetLayout()
            .frame(height: totalHeight + 20)
       }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition($position, anchor: .center)
        .contentMargins(.horizontal, (containerWidth - cardWidth - 20) * 0.5, for: .scrollContent)
        .task {
            if let last = periodStarts.last {
                position.scrollTo(id: last, anchor: .center)
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { old, new in
            containerWidth = new.width
        }
        .onChange(of: position) { _, new in
            guard let date = new.viewID(type: Date.self) else {
                logger.warning("Could not find date in scroll position")
                return
            }

            selectedStartDate = date
            logger.trace("New selected date: \(selectedStartDate)")
        }
        .sensoryFeedback(.impact, trigger: selectedStartDate)
        .padding(.vertical, 20)

        DaysListView(aggregationLevel: aggregationLevel, date: selectedStartDate)
            .padding(.top, 10)
    }
}

// MARK: - Previews

#Preview("Week") {
    AggregatedTimelineView(aggregationLevel: .week)
        .modelContainer(SampleData.shared.modelContainer)
}


#Preview("Month") {
    AggregatedTimelineView(aggregationLevel: .month)
        .modelContainer(SampleData.shared.modelContainer)
}
