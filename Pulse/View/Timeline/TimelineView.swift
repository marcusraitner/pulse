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
    @State private var isExpanded: Bool = true

    var body: some View {
        NavigationStack {
            List(allEntries) { entry in
                DisclosureGroup(isExpanded: .constant(true)) {
                        VStack(alignment: .leading) {
                            ForEach(entry.logEntries ?? []) { logEntry in
                                let width: CGFloat = 60
                                let height: CGFloat = 15
                                let entryWidth: CGFloat = max(5, CGFloat(logEntry.score.magnitude) * height)
                                let offset: CGFloat = CGFloat(logEntry.score) * (height * 0.5)
                                
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading) {
                                        Text("**\(logEntry.timestamp.formatted(.dateTime.hour().minute()))**: \(logEntry.log) (\(Image(systemName: "location.fill"))\u{00a0}\(logEntry.address ?? ""))")
                                            .font(.caption)
                                        if let address = logEntry.address {
//                                            Label("\(address)", systemImage: "location.square")
//                                                .font(.caption2)
//                                                .padding(.top, 1)
                                        }
                                    }
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 2)
                                        .frame(width: width, height: height)
                                        .foregroundStyle(Color.gray.opacity(0.2))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 2)
                                                .frame(width: entryWidth, height: height)
                                                .offset(x: offset)
                                                .foregroundStyle(ScoreStyleHelper.color(for: logEntry.score))
                                        }
                                }
                            }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text("\(entry.date.formatted(.dateTime.day().month().year()))")
                                .font(.title3).bold()
                            if !entry.summary.isEmpty {
                                Text("\(entry.summary)")
                                    .padding(.bottom, 4)
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
