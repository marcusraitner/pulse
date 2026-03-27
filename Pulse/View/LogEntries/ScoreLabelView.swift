//
//  ScoreLabelView.swift
//  collins score
//
//  Created by Marcus Raitner on 31.01.26.
//

import SwiftUI

struct ScoreLabelView: View {
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "default"
    
    var score: Int
    var size: CGFloat = 35
    var radius: CGFloat = 4
    var opacity: CGFloat = 1.0
    
    var body: some View {
        Text("\(score)")
            .frame(width: size, height: size)
            .glassScore(color: Theme.named(themeName).color(for: score), opacity: opacity, cornerRadius: radius)
            .foregroundStyle(.primary)
    }
}

#Preview {
    ScoreLabelView(score: -1)
}
