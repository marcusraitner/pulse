//
//  SelectedDateView.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI

/// Displays the selected date as a large serif weekday name and full date string.
struct SelectedDateView: View {
    let date: Date

    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Text(date.formatted(.dateTime.weekday(.wide)))
                Text(date.formatted(.dateTime.day().month(.wide).year()))
            }
            .font(.system(.title, design: .serif).bold())
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical)
    }
}

#Preview {
    SelectedDateView(date: .now)
        .background(.black)
}
