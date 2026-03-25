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
            if #available(iOS 26.0, *) {
                Button(action: onTap) {
                    Text("Reflect Your Day")
                        .foregroundStyle(.white)
                        .font(.title3)
                        .padding()
                        .glassEffect(.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.vertical)
            } else {
                Button(action: onTap) {
                    Text("Reflect Your Day")
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.vertical)
            }
        } else {
            if #available(iOS 26.0, *) {
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
                .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 5)
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
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
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 5)
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
            }
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
