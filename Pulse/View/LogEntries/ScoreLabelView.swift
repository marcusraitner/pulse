//
//  ScoreLabelView.swift
//  collins score
//
//  Created by Marcus Raitner on 31.01.26.
//

import SwiftUI

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
