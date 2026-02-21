//
//  NewLogEntrySheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 21.02.26.
//

import SwiftUI

struct NewLogEntrySheet: View {
    @Binding var newEntry: DailyLogEntry
    @State private var isNew = true
    
    var body: some View {
        Form {
            VStack(alignment: .leading) {
                TextField("What's going on?", text: $newEntry.log, axis: .vertical)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5...Int.max)
                
                Text("Please capture your moment here.")
                    .font(.caption)
                    .foregroundStyle(!isNew && newEntry.log.isEmpty ? .red : .clear)
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("How are you feeling?")
                    Text("Capture your mood on a scale from -2 (bad) to 2 (good)")
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                Spacer()
                VStack {
                    ScoreLabelView(score: newEntry.score, size: 72, radius: 12)
                        .font(.title).bold()
                    Stepper("", value: $newEntry.score, in: -2...2, step: 1)
                    .labelsHidden()
                    .padding(.top, 4)
                }
                .padding(.leading)
            }
        }
        .navigationTitle("New Moment")
        .onChange(of: newEntry.score) {
            isNew = false
        }
    }
}

#Preview {
    NavigationStack {
        NewLogEntrySheet(newEntry: .constant(DailyLogEntry(timestamp: .now, log: "", score: 0)))
    }
}
