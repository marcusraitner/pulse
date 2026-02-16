//
//  ScoreLabelView.swift
//  collins score
//
//  Created by Marcus Raitner on 31.01.26.
//

import SwiftUI

struct ScoreLabelView: View {
    var score: Int
    
    var body: some View {
        Text("\(score)")
            .frame(width: 35, height: 35)
            .background(ScoreStyleHelper.color(for: score).gradient,
                        in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(.primary)
    }
}

#Preview {
    ScoreLabelView(score: -1)
}
