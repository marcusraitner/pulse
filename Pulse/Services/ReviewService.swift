//
//  ReviewService.swift
//  Pulse
//
//  Created by Marcus Raitner on 25.03.26.
//

import SwiftUI

@Observable
class ReviewService {
    @ObservationIgnored @AppStorage("lastReviewRequest") private var lastReviewRequest: Int = 0
    @ObservationIgnored @AppStorage("numberOfRequests") private var numberOfRequests: Int = 0

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
