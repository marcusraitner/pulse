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
    
    var body: some View {
        VStack(alignment: .center) {
            if let level {
                switch level {
                case .week:
                    let cal = Calendar.current
                    let start = cal.dateInterval(of: .weekOfYear, for: date)?.start ?? date
                    let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
                    
                    Text("Week \(date.formatted(.dateTime.week())): \(start.formatted(.dateTime.day().month(.defaultDigits).year(.twoDigits))) – \(end.formatted(.dateTime.day().month(.defaultDigits).year(.twoDigits)))")
                case .month:
                    Text(date.formatted(.dateTime.month(.wide).year()))
                }
            } else {
                Text(date.formatted(.dateTime.weekday().day().month().year()))
            }
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
