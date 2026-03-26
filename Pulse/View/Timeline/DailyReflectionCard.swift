//
//  DailyReflectionCard.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI

struct DailyReflectionCard: View {
    let summary: String
    let onTap: () -> Void

    var body: some View {
        if summary.isEmpty {
            Button(action: onTap) {
                Text("Reflect Your Day")
                    .foregroundStyle(.white)
                    .font(.title3)
                    .padding()
                    .glassCapsule()
            }
            .buttonStyle(.plain)
            .padding(.vertical)
        } else {
            HStack {
                VStack(alignment: .leading) {
                    Text("Reflection")
                        .font(.title3)
                        .padding(.bottom, 5)
                    Text(summary)
                }
                .foregroundStyle(.white)
                .padding()
                Spacer()
            }
            .glassCard()
            .padding(.horizontal, 5)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
    }
}

#Preview("Empty") {
    DailyReflectionCard(summary: "", onTap: {})
        .background(.black)
}

#Preview("With summary") {
    DailyReflectionCard(summary: "Had a great day overall. Felt productive and calm.", onTap: {})
        .background(.black)
}
