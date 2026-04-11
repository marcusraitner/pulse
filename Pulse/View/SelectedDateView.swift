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
                    
                    Text("Week \(date.formatted(.dateTime.week()))")
                    Text("\(start.formatted(.dateTime.day().month(.defaultDigits).year())) – \(end.formatted(.dateTime.day().month(.defaultDigits).year()))")
                case .month:
                    Text(date.formatted(.dateTime.month(.wide)))
                    Text(date.formatted(.dateTime.year()))
                }
            } else {
                Text(date.formatted(.dateTime.weekday(.wide)))
                Text(date.formatted(.dateTime.day().month(.wide).year()))
            }
        }
        .font(.system(.title, design: .serif).bold())
        .foregroundStyle(.white.opacity(0.85))
    }
}

#Preview("Day") {
    SelectedDateView(date: .now)
        .background(.black)
}

#Preview("Week") {
    SelectedDateView(date: .now, level: .week)
        .background(.black)
}

#Preview("Month") {
    SelectedDateView(date: .now, level: .month)
        .background(.black)
}
