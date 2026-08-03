//
//  VerticalStepper.swift
//  Pulse
//
//  Created by Marcus Raitner on 07.07.26.
//

import SwiftUI

struct VerticalStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...10
    var step: Int = 1
    var size: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            Button {
                if value + step <= range.upperBound {
                    value += step
                }
            } label: {
                Image(systemName: "plus")
                    .frame(width: size, height: size)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(value + step > range.upperBound)
            
            Divider()
                .frame(width: size)
            
            Button {
                if value - step >= range.lowerBound {
                    value -= step
                }
            } label: {
                Image(systemName: "minus")
                    .frame(width: size, height: size)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(value - step < range.lowerBound)
        }
        .glassCapsule()
    }
}

#Preview {
    @Previewable @State var value = 1
    VStack {
        VerticalStepper(value: $value)
            .preferredColorScheme(.dark)
        Text("\(value)")
    }
}
