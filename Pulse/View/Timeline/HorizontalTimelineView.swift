//
//  TimeLineView.swift
//  collins score
//
//  Created by Marcus Raitner on 02.02.26.
//

import OSLog
import SwiftData
import SwiftUI

struct HorizontalTimelineView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]

    @Binding var selectedEntry: DailyEntry
    @Binding var scrollToToday: Bool

    @State private var entriesByDate: [Date: DailyEntry] = [:]
    @State private var position: ScrollPosition = .init(idType: Date.self)
    @State private var containerWidth: CGFloat = 0.0
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "default"
    @State private var isPresentingInsights: Bool = false
    @Environment(\.featureFlags) private var featureFlags

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "TimeLineView")

    var body: some View {
        let barWidth: CGFloat = 20
        let heightScale: CGFloat = 20
        let totalHeight: CGFloat = 4 * heightScale

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 3) {
                ForEach(allEntries, id: \.date ) { entry in
                    let avg: CGFloat = entry.averageScore
                    let barHeight: CGFloat = max(2, heightScale * avg.magnitude)
                    let yOffset: CGFloat = -0.5 * heightScale * avg

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.clear)
                        .frame(width: barWidth, height: totalHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ScoreStyleHelper.gradient(for: avg, themeName: themeName))
                                .frame(width: barWidth, height: barHeight)
                                .offset(y: yOffset)
                        }
                        .id(entry.date)
                        .onTapGesture {
                            withAnimation(.default) {
                                position.scrollTo(
                                    id: entry.date,
                                    anchor: .center
                                )
                            }
                    }
                }
            }
            .scrollTargetLayout()
        }
        .frame(idealHeight: totalHeight)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition($position, anchor: .center)
        .contentMargins(.horizontal, (containerWidth - barWidth) * 0.5, for: .scrollContent)
        .task {
            if let last = allEntries.last {
                position.scrollTo(id: last.date, anchor: .center)
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { old, new in
            containerWidth = new.width
        }
        .background {
            // draw baseline and indicator for selected day
            Group {
                EquilateralTriangle()
                    .frame(width: 10, height: 10)
                    .rotationEffect(Angle(degrees: 180))
                    .offset(y: -totalHeight * 0.5 - 15)
                Rectangle()
                    .frame(width: 1, height: totalHeight + 12)
                    .foregroundStyle(.white.opacity(1))
            }
            .foregroundStyle(.white.opacity(1))
        }
        .onChange(of: position) { _, new in
            // set selectedEntry on scroll pos change
            
            guard let date = new.viewID(type: Date.self) else {
                logger.warning("Could not find date in scroll position")
                return
            }
            
            guard let newSelected = entriesByDate[date] else {
                logger.warning("Could not find entry for date \(date)")
                return
            }
            
            selectedEntry = newSelected
            logger.trace("New selected date: \(selectedEntry.date)")
        }
        .onChange(of: allEntries) {
            entriesByDate = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.date, $0 ) } )
        }
        .sheet(isPresented: $isPresentingInsights) {
            // #available required by compiler: InsightsView is @available(iOS 26, *)
            if featureFlags.iOS26, #available(iOS 26, *) {
                NavigationStack {
                    InsightsView()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if featureFlags.iOS26 {
                    Button {
                        isPresentingInsights = true
                    } label: {
                        Image(systemName: "sparkles")
                    }
                }
            }
        }
        .sensoryFeedback(.impact, trigger: selectedEntry)
        .onChange(of: scrollToToday) { _, new in
            if new {
                logger.trace("scroll to today triggered")
                if let last = allEntries.last {
                    position.scrollTo(id: last.date, anchor: .center)
                }
                scrollToToday = false
            }
        }
    }
}

struct EquilateralTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Define the three points of the triangle
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

        // Draw the lines
        path.move(to: top)
        path.addLine(to: bottomLeft)
        path.addLine(to: bottomRight)
        path.addLine(to: top)  // Close the path

        return path
    }
}

struct TimeLineViewPreviewContainer: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries:
        [DailyEntry]

    var body: some View {
        if let entry = entries.randomElement() {
            HorizontalTimelineView(selectedEntry: .constant(entry), scrollToToday: .constant(true))
        } else {
            Text("No sample data available")
                .padding()
        }
    }
}

#Preview {
    TimeLineViewPreviewContainer()
        .modelContainer(SampleData.shared.modelContainer)
}
