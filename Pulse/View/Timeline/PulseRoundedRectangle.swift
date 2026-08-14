//
//  PulseRoundedRectangle.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.08.26.
//

import SwiftUI

struct PulseRoundedRectangle: View {
    let pulse: Bool
    @State private var cursorOpacity: Double = 0.3
    
    private var cursorAnimation: Animation {
        .snappy
        .speed(0.6)
        .repeatForever(autoreverses: true)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.tertiary.opacity(cursorOpacity))
            .onAppear() {
                guard pulse else { return }
                withAnimation(cursorAnimation) {
                    cursorOpacity = 1
                }
            }
    }
}

#Preview {
    PulseRoundedRectangle(pulse: true)
}
