//
//  ScoreLabelView.swift
//  collins score
//
//  Created by Marcus Raitner on 31.01.26.
//

import SwiftUI

/// The visual presentation style of a ``ScoreLabelView``.
enum ScoreLabelStyle {
    /// Small circular badge (38 pt) suitable for list rows.
    case badge
    /// Large outlined circle (72 pt) suitable for score entry forms.
    case outlined
}

/// A circular score indicator that displays the numeric score (−2 to +2) with a theme-matched color ring.
struct ScoreLabelView: View {
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "default"

    let score: Int
    let style: ScoreLabelStyle
        
    private var label: String {
        score > 0 ? "+\(score)" : "\(score)"
    }
    
    private var color: Color {
        Theme.named(themeName).color(for: score)
    }
    
    var body: some View {
        switch style {
            case .badge:
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .overlay(Circle().stroke(color, lineWidth: 4).shadow(color: .white, radius: 1))

            case .outlined:
            Text(label)
                .font(.title.bold())
                .foregroundStyle(.primary)
                .frame(width: 72, height: 72)
                .background(color.opacity(0.2), in: Circle())
                .overlay(Circle().stroke(color, lineWidth: 7))
        }
        
    }
}

#Preview("badge") {
    ScoreLabelView(score: -1, style: .badge)
}

#Preview("outlined") {
    ScoreLabelView(score: -1, style: .outlined)
}
