//
//  AppLockPromptGateTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 04.10.26.
//

import Testing
@testable import Pulse

// `#expect` cannot wrap a mutating call, so each result goes into a local first.

@Suite("AppLockPromptGate")
struct AppLockPromptGateTests {

    @Test("Allows the first automatic prompt")
    func firstAutomatic() {
        var gate = AppLockPromptGate()
        let allowed = gate.beginAutomatic()
        #expect(allowed)
    }

    // The prompt moves the scene inactive -> active; each of those must not start another prompt.
    @Test("Does not re-prompt automatically after a failed or cancelled prompt")
    func noAutomaticRetryAfterFailure() {
        var gate = AppLockPromptGate()
        let first = gate.beginAutomatic()
        gate.finish()  // prompt failed or was cancelled
        #expect(first)

        for _ in 0..<20 {  // scene keeps returning to .active
            let again = gate.beginAutomatic()
            #expect(!again)
        }
    }

    @Test("Never runs two evaluations at once")
    func noConcurrentEvaluations() {
        var gate = AppLockPromptGate()
        let first = gate.beginAutomatic()
        let secondAutomatic = gate.beginAutomatic()
        let manual = gate.beginManual()
        #expect(first)
        #expect(!secondAutomatic)
        #expect(!manual)
    }

    @Test("A blocked automatic prompt does not use up the session's automatic prompt")
    func blockedAutomaticIsNotConsumed() {
        var gate = AppLockPromptGate()
        let manual = gate.beginManual()  // user tapped Unlock first
        let blocked = gate.beginAutomatic()  // blocked: one is already showing
        gate.finish()
        let afterwards = gate.beginAutomatic()  // still available
        #expect(manual)
        #expect(!blocked)
        #expect(afterwards)
    }

    @Test("The Unlock button works again after a prompt finished")
    func manualRetry() {
        var gate = AppLockPromptGate()
        let automatic = gate.beginAutomatic()
        gate.finish()
        let firstRetry = gate.beginManual()
        gate.finish()
        let secondRetry = gate.beginManual()
        #expect(automatic)
        #expect(firstRetry)
        #expect(secondRetry)
    }

    @Test("Going to the background starts a new lock session with a new automatic prompt")
    func newSessionAfterBackground() {
        var gate = AppLockPromptGate()
        let first = gate.beginAutomatic()
        gate.finish()
        let sameSession = gate.beginAutomatic()

        gate.reset()  // app went to the background
        let newSession = gate.beginAutomatic()
        #expect(first)
        #expect(!sameSession)
        #expect(newSession)
    }

    @Test("Reset does not cancel a prompt that is still showing")
    func resetKeepsInFlight() {
        var gate = AppLockPromptGate()
        let first = gate.beginAutomatic()

        gate.reset()
        let automatic = gate.beginAutomatic()
        let manual = gate.beginManual()
        #expect(first)
        #expect(!automatic)
        #expect(!manual)
    }
}
