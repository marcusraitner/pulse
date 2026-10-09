//
//  CompactMomentRow.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import SwiftUI

/// A single-line row showing a score color strip, truncated log text, and a timestamp.
struct CompactMomentRow: View {
    let logEntry: DailyLogEntry
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Theme.named(themeName).color(for: logEntry.score))
                .frame(width: 10, height: 10)

            Text(logEntry.log)
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer(minLength: 4)

            Text(logEntry.formattedTimestamp)
                .font(.footnote)
                .foregroundStyle(.primary.opacity(0.5))
                .fixedSize()
        }
    }
}
