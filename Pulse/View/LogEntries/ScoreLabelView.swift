//
//  ScoreLabelView.swift
//  collins score
//
//  Created by Marcus Raitner on 31.01.26.
//

import SwiftUI

struct ScoreLabelView: View {
    var score: Int
    var size: CGFloat = 35
    var radius: CGFloat = 4
    var opacity: CGFloat = 1.0
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Text("\(score)")
                .frame(width: size, height: size)
                .glassEffect(.regular.tint(ScoreStyleHelper.color(for: score).opacity(opacity)), in: RoundedRectangle(cornerRadius: radius))
                .foregroundStyle(.primary)
        } else {
            // Fallback on earlier versions
            if opacity < 1.0 {
                Text("\(score)")
                    .frame(width: size, height: size)
                    .background(.thinMaterial,
                                in: RoundedRectangle(cornerRadius: radius))
                    .foregroundStyle(.primary)
            } else {
                Text("\(score)")
                    .frame(width: size, height: size)
                    .background(ScoreStyleHelper.color(for: score),
                                in: RoundedRectangle(cornerRadius: radius))
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    ScoreLabelView(score: -1)
}
