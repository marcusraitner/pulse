//
//  NewLogEntrySheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 21.02.26.
//

import SwiftUI

struct NewLogEntrySheet: View {
    @Binding var newEntry: DailyLogEntry
    
    var body: some View {
        Form {
            TextField("What's going on?", text: $newEntry.log, axis: .vertical)
                .multilineTextAlignment(.leading)
                .lineLimit(5...Int.max)
            HStack {
                VStack(alignment: .leading) {
                    Text("How are you feeling?")
                    Text("Capture your mood from -2 (bad) to 2 (good)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.top, 2)
                }
                Spacer()
                VStack {
                    ScoreLabelView(score: newEntry.score)
                        .padding(.leading, 2)
                    
                    Stepper(value: $newEntry.score, in: -2...2, step: 1) {
                        
                    }
                    .labelsHidden()
                }
                .padding(.leading)
                
            }
        }
        .navigationTitle("New Moment")
    }
}

#Preview {
    NewLogEntrySheet(newEntry: .constant(DailyLogEntry(timestamp: .now, log: "", score: 0)))
}
