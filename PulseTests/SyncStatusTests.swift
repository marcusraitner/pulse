//
//  SyncStatusTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 05.10.26.
//

import Testing
import CloudKit
@testable import Pulse
internal import Foundation

// MARK: - Helpers

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
private func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

private func event(_ kind: SyncEventInfo.Kind, _ status: SyncEventInfo.Status,
                   id: UUID = UUID()) -> SyncEventInfo {
    SyncEventInfo(id: id, kind: kind, status: status)
}

/// A model that has seen `events`, in order.
private func model(_ events: SyncEventInfo..., account: SyncStatusModel.Account = .unknown,
                   lastSuccess: Date? = nil) -> SyncStatusModel {
    var model = SyncStatusModel(lastSuccess: lastSuccess)
    model.setAccount(account)
    for event in events { model.apply(event) }
    return model
}

// MARK: - SyncStatusModel

@Suite("SyncStatusModel")
struct SyncStatusModelTests {

    @Test("Waits until a first event is seen")
    func waiting() {
        #expect(SyncStatusModel().summary == .waiting)
    }

    @Test("An import alone is enough to be synced; no export is needed")
    func importOnly() {
        let m = model(event(.import, .succeeded(ended: at(10))))
        #expect(m.summary == .synced(at(10)))
    }

    @Test("Setup succeeding does not count as synced data")
    func setupIsNotASync() {
        let m = model(event(.setup, .succeeded(ended: at(5))))
        #expect(m.summary == .waiting)
    }

    @Test("A running event shows syncing, and its end shows the sync time")
    func runningThenDone() {
        let id = UUID()
        var m = model(event(.import, .running, id: id))
        #expect(m.summary == .syncing)

        m.apply(event(.import, .succeeded(ended: at(3)), id: id))
        #expect(m.summary == .synced(at(3)))
    }

    @Test("Overlapping events keep showing syncing until the last one ends")
    func overlappingEvents() {
        let first = UUID()
        let second = UUID()
        var m = model(event(.import, .running, id: first), event(.import, .running, id: second))

        m.apply(event(.import, .succeeded(ended: at(4)), id: first))
        #expect(m.summary == .syncing)  // the other import is still running

        m.apply(event(.import, .succeeded(ended: at(6)), id: second))
        #expect(m.summary == .synced(at(6)))
    }

    @Test("The sync time never moves backward")
    func lastSuccessIsMonotonic() {
        let m = model(event(.export, .succeeded(ended: at(20))),
                      event(.import, .succeeded(ended: at(10))))
        #expect(m.summary == .synced(at(20)))
    }

    @Test("A stored sync time shows until something newer happens")
    func storedLastSuccess() {
        let m = SyncStatusModel(lastSuccess: at(-3600))
        #expect(m.summary == .synced(at(-3600)))
    }

    @Test("A failure of one kind is cleared by the next success of that kind")
    func staleFailureCleared() {
        var m = model(event(.export, .failed(.storageFull)))
        #expect(m.summary == .storageFull)

        m.apply(event(.export, .succeeded(ended: at(8))))
        #expect(m.summary == .synced(at(8)))
    }

    @Test("A success of another kind does not clear a failure")
    func otherKindDoesNotClear() {
        let m = model(event(.export, .failed(.storageFull)),
                      event(.import, .succeeded(ended: at(8))))
        #expect(m.summary == .storageFull)
    }

    @Test("Offline and busy are neutral, and a retry shows syncing")
    func transientFailures() {
        var offline = model(event(.import, .failed(.offline)))
        #expect(offline.summary == .offline)
        let busy = model(event(.import, .failed(.busy)))
        #expect(busy.summary == .busy)

        offline.apply(event(.import, .running))
        #expect(offline.summary == .syncing)
    }

    @Test("A real problem is not hidden by a retry in progress")
    func problemStaysWhileRetrying() {
        let m = model(event(.export, .failed(.storageFull)), event(.export, .running))
        #expect(m.summary == .storageFull)
    }

    @Test("A cancelled event neither succeeds nor fails")
    func cancelled() {
        let id = UUID()
        var m = model(event(.import, .running, id: id))
        m.apply(event(.import, .cancelled, id: id))
        #expect(m.summary == .waiting)
    }

    @Test("A missing iCloud account beats everything else")
    func noAccountWins() {
        let m = model(event(.import, .succeeded(ended: at(1))), event(.export, .running),
                      account: .unavailable)
        #expect(m.summary == .noAccount)
    }

    @Test("A no-account failure is reported even before the account status is read")
    func noAccountFromFailure() {
        let m = model(event(.setup, .failed(.noAccount)))
        #expect(m.summary == .noAccount)
    }

    @Test("An unknown account status is not a problem")
    func unknownAccountIsNeutral() {
        let m = model(event(.import, .succeeded(ended: at(1))), account: .unknown)
        #expect(m.summary == .synced(at(1)))
    }

    @Test("Maps CKAccountStatus")
    func accountMapping() {
        #expect(SyncStatusModel.Account(.available) == .available)
        #expect(SyncStatusModel.Account(.noAccount) == .unavailable)
        #expect(SyncStatusModel.Account(.restricted) == .unavailable)
        #expect(SyncStatusModel.Account(.temporarilyUnavailable) == .unknown)
        #expect(SyncStatusModel.Account(.couldNotDetermine) == .unknown)
    }

    @Test("Export problems are reported before import problems")
    func exportFirst() {
        let m = model(event(.import, .failed(.other("import"))),
                      event(.export, .failed(.other("export"))))
        #expect(m.summary == .problem("export"))
    }
}

// MARK: - SyncFailure

@Suite("SyncFailure")
struct SyncFailureTests {

    @Test("Maps CloudKit errors", arguments: [
        (CKError.Code.notAuthenticated, SyncFailure.noAccount),
        (.quotaExceeded, .storageFull),
        (.networkUnavailable, .offline),
        (.networkFailure, .offline),
        (.serviceUnavailable, .busy),
        (.zoneBusy, .busy),
        (.requestRateLimited, .busy),
        (.accountTemporarilyUnavailable, .busy),
    ])
    func cloudKitCodes(code: CKError.Code, expected: SyncFailure) {
        #expect(SyncFailure(error: CKError(code)) == expected)
    }

    @Test("Looks through a wrapping error")
    func wrapped() {
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: 134400,
                              userInfo: [NSUnderlyingErrorKey: CKError(.quotaExceeded) as NSError])
        #expect(SyncFailure(error: wrapped) == .storageFull)
    }

    @Test("Maps URL loading errors to offline")
    func urlErrors() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        #expect(SyncFailure(error: error) == .offline)
    }

    @Test("A partial failure reports its most serious reason")
    func partialFailure() {
        let partial = CKError(.partialFailure, userInfo: [
            CKPartialErrorsByItemIDKey: ["a": CKError(.networkUnavailable) as NSError,
                                         "b": CKError(.quotaExceeded) as NSError],
        ])
        #expect(SyncFailure(error: partial) == .storageFull)
    }

    @Test("Keeps unknown errors with their description")
    func unknown() {
        let error = NSError(domain: "test", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Something odd"])
        #expect(SyncFailure(error: error) == .other("Something odd"))
    }

    @Test("Only offline and busy are transient")
    func transient() {
        #expect(SyncFailure.offline.isTransient)
        #expect(SyncFailure.busy.isTransient)
        #expect(!SyncFailure.noAccount.isTransient)
        #expect(!SyncFailure.storageFull.isTransient)
        #expect(!SyncFailure.other("x").isTransient)
    }
}
