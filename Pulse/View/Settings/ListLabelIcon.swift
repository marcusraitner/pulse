//
//  ListLabelIcon.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI

struct ListLabelIcon: ViewModifier {
    let color: Color
    let iconFrame: CGFloat
    let iconSize: CGFloat
    let cornerRadius: CGFloat

    init(color: Color, iconFrame: CGFloat, iconSize: CGFloat, cornerRadius: CGFloat) {
        self.color = color
        self.iconFrame = iconFrame
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: iconSize))
            .frame(width: iconFrame, height: iconFrame)
            .foregroundStyle(.white)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func listLabelIcon(_ color: Color) -> some View {
        modifier(ListLabelIcon(color: color, iconFrame: 30, iconSize: 12, cornerRadius: 8))
    }

    func titleLabelIcon(_ color: Color) -> some View {
        modifier(ListLabelIcon(color: color, iconFrame: 55, iconSize: 32, cornerRadius: 16))
    }
}
