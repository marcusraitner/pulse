//
//  ThemePreview.swift
//  Pulse
//
//  Created by Marcus Raitner on 19.03.26.
//

import SwiftUI

struct ThemePreview: View {
    var theme: Theme
    private var size: CGFloat = 20
    
    init(_ theme: Theme) {
        self.theme = theme
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(theme.name)")
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.minus2)
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.minus1)
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.neutral)
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.plus1)
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.plus2)
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    ThemePreview(Theme.default)
}
