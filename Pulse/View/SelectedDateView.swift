//
//  SelectedDateView.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI

/// Displays the selected date as a large serif weekday name and full date string.
struct SelectedDateView: View {
    let date: Date
    var level: AggregationLevel? = nil
    
    private var cal: Calendar { .current }

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            if let level {
                switch level {
                case .week:
                    let start = cal.dateInterval(of: .weekOfYear, for: date)?.start ?? date
                    let end = cal.date(byAdding: .day, value: 6, to: start) ?? start

                    Text((start..<end).formatted(.interval.day().month(.abbreviated).year()))
                case .month:
                    Text(date.formatted(.dateTime.month(.wide).year()))
                }
            } else if cal.isDateInToday(date) {
                Text("Today")
            } else if cal.isDateInYesterday(date) {
                Text("Yesterday")
            } else {
                Text(date.formatted(.dateTime.weekday().day().month().year()))
            }

            Rectangle()
                .fill(.secondary)
                .frame(width: 40, height: 1)

            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .font(.body.bold())
    }
}

#Preview("Day") {
    SelectedDateView(date: .now)
        .preferredColorScheme(.dark)
}

#Preview("Week") {
    SelectedDateView(date: .now, level: .week)
        .preferredColorScheme(.dark)
}

#Preview("Month") {
    SelectedDateView(date: .now, level: .month)
        .preferredColorScheme(.dark)
}
