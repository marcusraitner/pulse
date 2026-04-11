//
//  DaysListView.swift
//  Pulse
//
//  Created by Marcus Raitner on 08.04.26.
//

import SwiftUI
import SwiftData

struct DaysListView: View {

    var aggregationLevel: AggregationLevel
    var date: Date
    
    @Query private var allEntries: [DailyEntry]

    init(aggregationLevel: AggregationLevel = .week, date: Date = .now) {
        self.aggregationLevel = aggregationLevel
        self.date = date
        let cal = Calendar.current
        let component = aggregationLevel == .week ? Calendar.Component.weekOfYear : Calendar.Component.month
        if let interval = cal.dateInterval(of: component, for: date) {
            _allEntries = .init(
                filter: #Predicate<DailyEntry> { $0.date >= interval.start && $0.date < interval.end },
                sort: \.date)
        } else {
            _allEntries = .init(
                filter: #Predicate<DailyEntry> { _ in false },
                sort: \.date)
        }
    }
    
    var body: some View {
        LazyVStack {
            ForEach(allEntries) { entry in
                DayCardView(entry: entry, aggregationLevel: aggregationLevel)
            }
        }
    }
}

// MARK: - Previews

#Preview("Week") {
        DaysListView(aggregationLevel: .week)
            .modelContainer(SampleData.shared.modelContainer)
}

#Preview("Month") {
        DaysListView(aggregationLevel: .month)
            .modelContainer(SampleData.shared.modelContainer)
}
