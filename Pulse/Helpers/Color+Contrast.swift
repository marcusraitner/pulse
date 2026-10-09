//
//  Color+Contrast.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import SwiftUI

extension Color {
    /// Relative luminance WCAG (0 = black, 1 = white)
    private func luminance(in env: EnvironmentValues) -> Double {
        let r = resolve(in: env)
        func lin(_ c: Float) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r.red) + 0.7152 * lin(r.green) + 0.0722 * lin(r.blue)
    }

    func contrastingTextColor(in env: EnvironmentValues) -> Color {
        // 0.179 is where contrast-vs-black equals contrast-vs-white: sqrt(0.05 * 1.05) - 0.05
        luminance(in: env) >= 0.179 ? .black : .white
    }
}
