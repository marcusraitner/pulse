//
//  View+Glass.swift
//  Pulse
//
//  Created by Marcus Raitner on 15.09.26.
//

import Foundation
import SwiftUI

extension View {
    func glassCard(cornerRadius: CGFloat = 10) -> some View {
        glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    func glassTintedCard(_ color: Color, opacity: Double = 0.5, cornerRadius: CGFloat = 10) -> some View {
        glassEffect(.regular.tint(color.opacity(opacity)).interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
