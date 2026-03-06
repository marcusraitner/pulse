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
    
    var body: some View {
        Text("\(score)")
            .frame(width: size, height: size)
            .background(ScoreStyleHelper.color(for: score).gradient,
                        in: RoundedRectangle(cornerRadius: radius))
            .shadow(radius: 2)
            .foregroundStyle(.primary)
    }
}

#Preview {
    ScoreLabelView(score: -1)
}
