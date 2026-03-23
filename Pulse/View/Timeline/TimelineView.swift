//
//  TimelineView.swift
//  Pulse
//
//  Created by Marcus Raitner on 21.03.26.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]

    var body: some View {
        NavigationStack {
            List(allEntries) { entry in
                VStack(alignment: .leading) {
                    Text("\(entry.date.formatted(.dateTime.day().month().year()))")
                        .font(.title3).bold()
                    if !entry.summary.isEmpty {
                        Text("\(entry.summary)")
                            .padding(.bottom, 4)
                    }
                    ForEach(entry.logEntries ?? []) { logEntry in
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .frame(width: 20, height: 20)
                                .foregroundColor(ScoreStyleHelper.color(for: logEntry.score))
                                .overlay {
                                    Text("\(logEntry.score)")
                                        .font(.caption2)
                                }
                            
                            Text("**\(logEntry.timestamp.formatted(.dateTime.hour().minute()))**: \(logEntry.log)")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TimelineView()
        .modelContainer(SampleData.shared.modelContainer)
}
