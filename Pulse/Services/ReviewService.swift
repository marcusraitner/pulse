//
//  ReviewService.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI

/// Rate-limited App Store review request service.
/// At most 3 prompts are shown across the app's lifetime, with each subsequent
/// prompt requiring proportionally more new log entries since the last request.
@Observable
class ReviewService {
    @ObservationIgnored @AppStorage(AppStorageKeys.lastReviewRequest) private var lastReviewRequest: Int = 0
    @ObservationIgnored @AppStorage(AppStorageKeys.numberOfRequests) private var numberOfRequests: Int = 0

    /// Considers requesting a review based on how many log entries have been created.
    ///
    /// A review prompt is triggered only when:
    /// - Fewer than 3 reviews have been requested before, and
    /// - At least `5 × (numberOfRequests + 1)` new entries exist since the last request.
    ///
    /// The prompt is shown after a 2-second delay to avoid interrupting the user.
    /// - Parameters:
    ///   - countLog: The current total number of log entries.
    ///   - requestReview: Closure that triggers the App Store review prompt.
    func considerRequesting(countLog: Int, requestReview: @escaping () -> Void) {
        guard numberOfRequests < 3,
              countLog > lastReviewRequest + (5 * (numberOfRequests + 1)) else { return }
        numberOfRequests += 1
        lastReviewRequest = countLog
        Task {
            try? await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
}
