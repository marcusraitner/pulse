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
    @State private var scoreFilter: Set<Int> = []

    var filteredEntries: [DailyEntry] {
        guard !scoreFilter.isEmpty else { return allEntries }
        return allEntries.filter { entry in
            (entry.logEntries ?? []).contains { scoreFilter.contains($0.score) }
        }
    }

    func filteredLogEntries(for entry: DailyEntry) -> [DailyLogEntry] {
        guard !scoreFilter.isEmpty else { return entry.logEntries ?? [] }
        return (entry.logEntries ?? []).filter { scoreFilter.contains($0.score) }
    }

    var body: some View {
        NavigationStack {
            List(filteredEntries) { entry in
                DisclosureGroup() {
                    VStack(alignment: .leading) {
                        ForEach(filteredLogEntries(for: entry)) { logEntry in
                            let width: CGFloat = 60
                            let height: CGFloat = 15
                            let entryWidth: CGFloat = max(5, CGFloat(logEntry.score.magnitude) * height)
                            let offset: CGFloat = CGFloat(logEntry.score) * (height * 0.5)
                            
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("**\(logEntry.timestamp.formatted(.dateTime.hour().minute()))**: \(logEntry.log)")
                                        .font(.caption)
                                    Text("\(Image(systemName: "location.square"))\u{00a0}*\(logEntry.address ?? "")*")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 1)
                                    
                                    //                                        if let address = logEntry.address {
                                    //                                            Label("\(address)", systemImage: "location.square")
                                    //                                                .font(.caption2)
                                    //                                                .padding(.top, 1)
                                    //                                        }
                                }
                                Spacer()
                                RoundedRectangle(cornerRadius: 2)
                                    .frame(width: width, height: height)
                                    .foregroundStyle(Color.gray.opacity(0.15))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 2)
                                            .frame(width: entryWidth, height: height)
                                            .offset(x: offset)
                                            .foregroundStyle(ScoreStyleHelper.color(for: logEntry.score))
                                    }
                            }
                            .padding(.top, 5)
                            Divider()
                            
                        }
                    }
                    .listRowSeparator(.hidden)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach([-2, -1, 0, 1, 2], id: \.self) { score in
                            let label = score > 0 ? "+\(score)" : "\(score)"
                            Button {
                                if scoreFilter.contains(score) {
                                    scoreFilter.remove(score)
                                } else {
                                    scoreFilter.insert(score)
                                }
                            } label: {
                                if scoreFilter.contains(score) {
                                    Label(label, systemImage: "checkmark")
                                } else {
                                    Text(label)
                                }
                            }
                        }
                        if !scoreFilter.isEmpty {
                            Divider()
                            Button("Clear Filter", role: .destructive) {
                                scoreFilter = []
                            }
                        }
                    } label: {
                        Image(systemName: scoreFilter.isEmpty
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
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
