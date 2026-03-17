//
//  TimeLineView.swift
//  collins score
//
//  Created by Marcus Raitner on 02.02.26.
//

import OSLog
import SwiftData
import SwiftUI

struct TimeLineView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Binding var selectedEntry: DailyEntry
    @Binding var scrollToToday: Bool
    
    @State private var today: DailyEntry = .init(date: .now)
    @State private var position: ScrollPosition = .init(idType: Date.self)
    @State private var containerWidth: CGFloat = 0.0
    
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
                                .fill(ScoreStyleHelper.gradient(for: avg))
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

//                RoundedRectangle(cornerRadius: 4)
//                    .stroke(style: StrokeStyle(lineWidth: 1))
//                    .frame(width: barWidth + 3, height: totalHeight + 3)
                Rectangle()
                    .frame(width: 1, height: totalHeight + 12)
//                    .foregroundStyle(.white.opacity(1))
//                EquilateralTriangle()
//                    .frame(width: 10, height: 10)
//                    .offset(y: totalHeight * 0.5 + 10)
            }
            .foregroundStyle(.white.opacity(1))
        }
        .onChange(of: position) { _, new in
            // set selectedEntry on scroll pos change
            
            if let date: Date = new.viewID(type: Date.self) {
                if let newSelected = allEntries.first(where: { $0.date == date }) {
                    selectedEntry = newSelected
                    logger.trace("New selected date: \(selectedEntry.date)")
                } else {
                    logger.trace("Could not find entry for date \(date)")
                }
            } else {
                logger.trace("Could not find date in scroll position")
            }
        }
        .sensoryFeedback(.impact, trigger: selectedEntry)
        .onChange(of: scenePhase) { _, newPhase in
            // check if a day passed
            if newPhase == .active {
                logger.trace("scene is now active. Updating today.")
                updateToday()
            }
        }
        .onChange(of: today) {
            logger.trace("Today changed: \(today.date)")
            position.scrollTo(id: today.date, anchor: .center)
        }
        .onChange(of: scrollToToday) { _, new in
            if new {
                logger.trace("scroll to today triggered")
                position.scrollTo(id: today.date, anchor: .center)
                scrollToToday = false
            }
            
        }
    }
    
    private func updateToday() {
        if let entry = allEntries.last {
            if Calendar.current.isDateInToday(entry.date) {
                if entry != today {
                    today = entry
                }
                return
            }
        }

        // entry for today missing: create and save it
        let newToday = DailyEntry(date: .now)
        logger.debug("Creating a new day: \(newToday.date)")
        context.insert(newToday)
        
        do {
            try context.save()
        } catch {
            logger.error("Failed saving new day: \(String(describing: error))")
        }
        
        // this triggers also scrolling
        today = newToday
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
            TimeLineView(selectedEntry: .constant(entry), scrollToToday: .constant(true))
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
