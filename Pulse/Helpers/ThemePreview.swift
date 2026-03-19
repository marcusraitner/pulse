//
//  ThemePreview.swift
//  Pulse
//
//  Created by Marcus Raitner on 19.03.26.
//

import SwiftUI

struct ThemePreview: View {
    var theme: String
    private var size: CGFloat = 20
    
    init(_ theme: String) {
        self.theme = theme
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(theme.capitalized)")
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("\(theme)/minus2"))
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("\(theme)/minus1"))
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("\(theme)/neutral"))
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("\(theme)/plus1"))
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("\(theme)/plus2"))
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    ThemePreview("default")
}
