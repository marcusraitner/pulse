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
    var allEntries: [DailyEntry]
    @Environment(\.modelContext) private var context
    @Binding var selectedEntry: DailyEntry
    @State private var frames: [DailyEntry: CGRect] = [:]
    @State private var position: ScrollPosition = .init(idType: Date.self)
    @State private var containerWidth: CGFloat = 0.0
    private static let geometry = NamedCoordinateSpace.named("geometry")

    var body: some View {
        let barWidth: CGFloat = 20
        let heightScale: CGFloat = 20
        let totalHeight: CGFloat = 4 * heightScale

        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 3) {
                    ForEach(allEntries) { entry in
                        let avg: CGFloat = entry.averageScore
                        let barHeight: CGFloat = max(
                            1,
                            heightScale * abs(avg)
                        )
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
                            withAnimation(.smooth) {
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
                .foregroundStyle(.white.opacity(0.8))
            }
            .onChange(of: frames) {
                // initial scroll
                DispatchQueue.main.async {
                    position.scrollTo(id: selectedEntry.date, anchor: .center)
                }
            }
            .onChange(of: position) { _, new in
                // set selectedEntry on scroll pos change
                if let date: Date = new.viewID(type: Date.self) {
                    selectedEntry =
                        allEntries.first(
                            where: { $0.date == date }) ?? allEntries.first!
                }
            }
            .sensoryFeedback(.impact, trigger: selectedEntry)
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
            TimeLineView(allEntries: entries, selectedEntry: .constant(entry))
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
