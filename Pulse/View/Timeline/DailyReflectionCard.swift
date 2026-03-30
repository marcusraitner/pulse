//
//  DailyReflectionCard.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI

/// Displays either a "Reflect Your Day" call-to-action button (when `summary` is empty)
/// or the saved reflection text in a glass card. Tapping either form invokes `onTap`.
struct DailyReflectionCard: View {
    let summary: String
    /// Called when the user taps the card or button to open the reflection sheet.
    let onTap: () -> Void

    var body: some View {
        if summary.isEmpty {
            Button(action: onTap) {
                Text("Reflect Your Day")
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
