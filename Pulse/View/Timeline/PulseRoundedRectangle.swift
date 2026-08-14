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
        .easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.tertiary.opacity(cursorOpacity))
            .onAppear() {
                guard pulse else { return }
                DispatchQueue.main.async {
                    withAnimation(cursorAnimation) {
                        cursorOpacity = 1
                    }
                }
            }
    }
}

#Preview {
    PulseRoundedRectangle(pulse: true)
}
