//
//  TagChipView.swift
//  Pulse
//
//  Created by Marcus Raitner on 17.04.26.
//

import SwiftUI

enum TagChipStyle {
    case display
    case selectable(isSelected: Bool, onTap: () -> Void)
}

struct TagChipView: View {
    var label: String
    var style: TagChipStyle

    private var displayLabel: String {
        NSLocalizedString("tag.\(label)", value: label, comment: "")
    }

    var body: some View {
        switch style {
        case .display:
            chip(isSelected: false, color: .secondary)
        case .selectable(let isSelected, let onTap):
            Button(action: onTap) {
                chip(isSelected: isSelected, color: .accent)
            }
            .buttonStyle(.plain)
        }
    }

    private func chip(isSelected: Bool, color: Color) -> some View {
        Text(displayLabel)
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? color.opacity(0.8) : .clear, in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.7), lineWidth: 1))
            .foregroundStyle(.primary)
    }
}

#Preview("All states") {
    @Previewable @State var isSelected: Bool = false
    HStack(spacing: 8) {
        TagChipView(label: "exercise", style: .display)
        TagChipView(label: "deep work", style: .selectable(isSelected: isSelected, onTap: { isSelected.toggle() }))
    }
    .padding()
    .preferredColorScheme(.dark)
}
