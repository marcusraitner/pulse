//
//  TimeLineView.swift
//  collins score
//
//  Created by Marcus Raitner on 02.02.26.
//

import OSLog
import SwiftData
import SwiftUI

/// Horizontally scrollable bar chart of all daily entries.
/// Each bar's height and color represent the day's average score.
/// Tapping a bar centers it; scrolling updates `selectedEntry`.
struct HorizontalTimelineView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]

    @Binding var selectedEntry: DailyEntry
    /// Set to `true` to programmatically scroll the timeline to today's entry.
    @Binding var scrollToToday: Bool

    @State private var position: Date?
    @State private var containerWidth: CGFloat = 0.0
    @State private var hasSetInitialPosition = false
    
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"
    @AppStorage(AppStorageKeys.showEmptyDays) private var showEmptyDays: Bool = false
    @Environment(FilterState.self) private var filterState
    
    @Environment(\.featureFlags) private var featureFlags

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "HorizontalTimeLineView")

    var body: some View {
        let barWidth: CGFloat = 20
        let heightScale: CGFloat = 20
        let totalHeight: CGFloat = 4 * heightScale

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 3) {
                ForEach(allEntries.filter(isShown), id: \.date ) { entry in
                    let avg: CGFloat? = entry.averageScore(
                        taggedWith: filterState.activeFilter)
                    let barHeight: CGFloat = max(2, heightScale * (avg?.magnitude ?? 0))
                    let yOffset: CGFloat = -0.5 * heightScale * (avg ?? 0)

                    PulseRoundedRectangle(pulse: entry.date == selectedEntry.date)
                        .frame(width: barWidth, height: totalHeight)
                        .overlay {
                            if let avg {
                                RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.named(themeName).gradient(for: avg))
                                .frame(width: barWidth, height: barHeight)
                                .offset(y: yOffset)
                            }
                        }
                        .id(entry.date)
                        .onTapGesture {
                            withAnimation(.default) {
                                position = entry.date
                            }
                        }
                }
            }
            .frame(height: totalHeight)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $position, anchor: .center)
        .defaultScrollAnchor(.trailing)
        .contentMargins(.horizontal, max(0, (containerWidth - barWidth) * 0.5), for: .scrollContent)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { old, new in
            logger.trace("Setting container width to \(new.width)")
            containerWidth = new.width

            // The side margins follow the width but the scroll offset does not, so the selected day
            // ends up off-center once the real width is known (launch, rotation, window resizing)
            guard new.width > 0, new.width != old.width else { return }
            scroll(to: recenterTarget())
        }
        .onChange(of: position) { _, new in
            // set selectedEntry on scroll pos change
            
            guard let new else {
                logger.warning("Could not find date in scroll position")
                return
            }
            
            guard let newSelected = entry(for: new) else {
                logger.warning("Could not find entry for date \(new)")
                return
            }
            
            selectedEntry = newSelected
            logger.trace("New selected date: \(selectedEntry.date)")
        }
        .onChange(of: allEntries, initial: true) {
            logger.trace("allEntries changed")

            // skip the initial run; triggerScrollToToday handles the first scroll
            // once layout has actually settled
            guard hasSetInitialPosition else {
                hasSetInitialPosition = true
                return
            }

            guard let last = allEntries.last else { return }
            logger.trace("scrolling to last")
            position = last.date
        }
        .sensoryFeedback(.impact, trigger: selectedEntry)
        .onChange(of: scrollToToday) { _, new in
            if new {
                logger.trace("scroll to today triggered")
                if let last = allEntries.last {
                    position = nil
                    logger.trace("scrolling to today / last")
                    withAnimation() {
                        position = last.date
                    }
                }
                scrollToToday = false
            }
        }
        .onChange(of: showEmptyDays) { _, _ in
            let target =
            (!selectedEntry.isEmpty || Calendar.current.isDateInToday(selectedEntry.date)) ?
            selectedEntry.date : allEntries.last?.date
           
            scroll(to: target)
        }
    }

    /// The entry for `date`. A plain search over the sorted entries: building a dictionary of all
    /// of them on every scroll step costs more than one pass.
    private func entry(for date: Date) -> DailyEntry? {
        allEntries.first { $0.date == date }
    }

    /// Whether the day gets a bar in the timeline.
    private func isShown(_ entry: DailyEntry) -> Bool {
        showEmptyDays || !entry.isEmpty || Calendar.current.isDateInToday(entry.date)
    }

    /// The day to keep centered when the width changes: the selected day, or the last day if
    /// nothing is selected yet. Not `position`, which is `nil` while a scroll is being re-applied
    /// and whenever SwiftUI lays the scroll view out at an odd size.
    private func recenterTarget() -> Date? {
        let selected = allEntries.first { $0.date == selectedEntry.date && isShown($0) }
        return selected?.date ?? allEntries.last?.date
    }

    /// Scrolls the timeline to `target` in a following main-actor task. The position is cleared
    /// first, because setting it to the value it already has would not scroll.
    private func scroll(to target: Date?) {
        position = nil
        Task {
            if let target {
                position = target
            }
        }
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
