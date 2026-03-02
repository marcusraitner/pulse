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
    @State private var today: DailyEntry = .init(date: .now)
    @State private var frames: [DailyEntry: CGRect] = [:]
    @State private var position: ScrollPosition = .init(idType: Date.self)
    @State private var containerWidth: CGFloat = 0.0
    @State private var countDays: Int = 0
    private static let geometry = NamedCoordinateSpace.named("geometry")
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "TimeLineView")
    @State private var todayFrameVisible: Bool = true

    var body: some View {
        let barWidth: CGFloat = 20
        let heightScale: CGFloat = 20
        let totalHeight: CGFloat = 4 * heightScale

        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 3) {
                    
                    ForEach(allEntries, id: \.date ) { entry in
                        let avg: CGFloat = entry.averageScore
                        let barHeight: CGFloat = max(1, heightScale * abs(avg))
                        let yOffset: CGFloat = -0.5 * heightScale * avg

                        Group {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ScoreStyleHelper.gradient(for: avg))
                                .frame(width: barWidth, height: barHeight)
                                .offset(y: yOffset)
                                .background {
                                    // storing frame for scrolling
                                    GeometryReader { proxy in
                                        Color.clear
                                            .onAppear {
                                                frames[entry] = proxy.frame(
                                                    in: Self.geometry
                                                )
                                            }
                                            .onChange(
                                                of: proxy.frame(
                                                    in: Self.geometry
                                                )
                                            ) { _, newValue in
                                                frames[entry] = newValue
                                            }
                                    }
                                }
                        }
                        .id(entry.date)
                        .onTapGesture {
                            withAnimation(.default) {
                                selectedEntry = entry
                                position.scrollTo(
                                    id: entry.date,
                                    anchor: .center
                                )
                            }
                        }
                    }
                }
                .scrollTargetLayout()
                .coordinateSpace(Self.geometry)
            }
            .accessibilityIdentifier("timelineView")
            .accessibilityValue(
                Text("position:\(DateFormatHelper.formatDate(position.viewID(type: Date.self)))")
            )
            .scrollTargetBehavior(
                TimeLineViewScrollTargetBehavior(
                    frames: frames
                )
            )
            .scrollPosition($position, anchor: .center)
            .frame(height: totalHeight)
            .safeAreaPadding(.horizontal, containerWidth * 0.5)
            .background {
                // keep track of width
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        containerWidth = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        containerWidth = newWidth
                    }
                }
                
                // draw baseline and indicator for selected day
                Group {
                    EquilateralTriangle()
                        .frame(width: 10, height: 10)
                        .rotationEffect(Angle(degrees: 180))
                        .offset(y: -totalHeight * 0.5 - 5)
                    Rectangle()
                        .frame(width: 1, height: totalHeight + 10)
                    EquilateralTriangle()
                        .frame(width: 10, height: 10)
                        .offset(y: totalHeight * 0.5 + 5)
                }
                .foregroundStyle(Color("neutral"))
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
        }
        .onChange(of: scenePhase) { _, newPhase in
            // check if a day passed
            if newPhase == .active {
                updateToday()
            }
        }
        .onChange(of: today) {
            logger.trace("Today changed: \(today.date)")
            if frames[today] != nil {
                logger.trace("found frame; scrolling to it")
                position.scrollTo(id: today.date, anchor: .center)
            } else {
                // frame for today not yet created
                // scroll to the last frame
                logger.trace("no frame for today; scrolling to last")
                position.scrollTo(edge: .trailing)
                todayFrameVisible = false
            }
        }
        .onChange(of: frames) {
            logger.trace("Frames changed")
            if !todayFrameVisible {
                logger.trace("today was not visible before")
                if frames[today] != nil {
                    logger.trace("now today's frame exists; scrolling to it")
                    position.scrollTo(id: today.date, anchor: .center)
                    todayFrameVisible = true
                }
            }
        }
        .task {
            if let last = allEntries.last {
                position.scrollTo(id: last.date, anchor: .center)
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
        try? context.save()
        
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

struct TimeLineViewScrollTargetBehavior: ScrollTargetBehavior {
    var frames: [DailyEntry: CGRect]

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let xProposed = target.rect.midX
        guard
            let nearestEntry =
                frames
                .min(by: {
                    ($0.value.midX - xProposed).magnitude
                        < ($1.value.midX - xProposed).magnitude
                })
        else { return }
        target.rect.origin.x =
            nearestEntry.value.midX - 0.5 * target.rect.size.width
    }
}

struct TimeLineViewPreviewContainer: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries:
        [DailyEntry]

    var body: some View {
        if let entry = entries.randomElement() {
            TimeLineView(selectedEntry: .constant(entry))
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
