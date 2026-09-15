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
    /// small inline bade
    case inline
}

extension Color {
    /// Relative Luminanz nach WCAG (0 = schwarz, 1 = weiß)
    private func luminance(in env: EnvironmentValues) -> Double {
        let r = resolve(in: env)
        func lin(_ c: Float) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r.red) + 0.7152 * lin(r.green) + 0.0722 * lin(r.blue)
    }

    func contrastingTextColor(in env: EnvironmentValues) -> Color {
        luminance(in: env) >= 0.179 ? .black : .white
    }
}



/// A circular score indicator that displays the numeric score (−2 to +2) with a theme-matched color ring.
struct ScoreLabelView: View {
    @Environment(\.self) private var env
    
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"

    let score: Int
    let style: ScoreLabelStyle
        
    private var color: Color {
        Theme.named(themeName).color(for: score)
    }
    
    var body: some View {
        switch style {
            case .badge:
            Text(score, format: .number.sign(strategy: .always(includingZero: false)))
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .overlay(Circle().stroke(color, lineWidth: 4).shadow(color: .white, radius: 1))

            case .outlined:
            Text(score, format: .number.sign(strategy: .always(includingZero: false)))
                .font(.title.bold())
                .foregroundStyle(.primary)
                .frame(width: 72, height: 72)
                .background(color.opacity(0.2), in: Circle())
                .overlay(Circle().stroke(color, lineWidth: 7))
            
            case .inline:
            ZStack {
                Text(Int(-2), format: .number.sign(strategy: .always(includingZero: false))).hidden()
                Text(score, format: .number.sign(strategy: .always(includingZero: false)))
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(color.contrastingTextColor(in: env))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
        }
        
    }
}

#Preview("badge") {
    ScoreLabelView(score: -1, style: .badge)
}

#Preview("outlined") {
    ScoreLabelView(score: -1, style: .outlined)
}
