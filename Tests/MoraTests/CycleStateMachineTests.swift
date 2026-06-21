import XCTest
import Combine
@testable import Mora

final class CycleStateMachineTests: XCTestCase {
    func testFocusCompletionAdvancesToShortBreak() {
        let timer = FakeTimerEngine()
        let machine = CycleStateMachine(timerEngine: timer, now: referenceDate)

        machine.startInitialFocus(now: referenceDate)
        XCTAssertEqual(machine.timerState.phase, .focus(block: 1))

        timer.triggerCompletion()
        drainMainQueue()
        XCTAssertEqual(machine.timerState.phase, .shortBreak(block: 1))

        timer.triggerCompletion()
        drainMainQueue()
        XCTAssertEqual(machine.timerState.phase, .focus(block: 2))
    }

    func testLongBreakAfterFourthFocus() {
        let timer = FakeTimerEngine()
        let machine = CycleStateMachine(timerEngine: timer, now: referenceDate)

        machine.startInitialFocus(now: referenceDate)

        for block in 1...4 {
            timer.triggerCompletion() // focus completed -> short or long break
            drainMainQueue()
            if block < 4 {
                XCTAssertEqual(machine.timerState.phase, .shortBreak(block: block))
                timer.triggerCompletion() // complete short break
                drainMainQueue()
                XCTAssertEqual(machine.timerState.phase, .focus(block: block + 1))
            } else {
                XCTAssertEqual(machine.timerState.phase, .longBreak)
            }
        }
    }

    func testAutomaticLongBreakCompletionIsNotManual() {
        let timer = FakeTimerEngine()
        let machine = CycleStateMachine(timerEngine: timer, now: referenceDate)
        var completedBreaks: [(TimerPhase, Bool)] = []
        machine.onBreakComplete = { phase, wasManual in
            completedBreaks.append((phase, wasManual))
        }

        machine.startInitialFocus(now: referenceDate)
        advanceToLongBreak(timer: timer)

        timer.triggerCompletion()
        drainMainQueue()

        XCTAssertEqual(completedBreaks.last?.0, .longBreak)
        XCTAssertEqual(completedBreaks.last?.1, false)
        XCTAssertEqual(machine.timerState.phase, .focus(block: 1))
    }

    func testSkippedLongBreakDoesNotCompleteBreak() {
        let timer = FakeTimerEngine()
        let machine = CycleStateMachine(timerEngine: timer, now: referenceDate)
        var completedBreakCount = 0
        machine.onBreakComplete = { _, _ in
            completedBreakCount += 1
        }

        machine.startInitialFocus(now: referenceDate)
        advanceToLongBreak(timer: timer)
        let completedShortBreaks = completedBreakCount

        machine.skipBreak(now: referenceDate)

        XCTAssertEqual(completedBreakCount, completedShortBreaks)
        XCTAssertEqual(machine.timerState.phase, .focus(block: 1))
    }

    func testManualLongBreakCompletionIsMarkedManual() {
        let timer = FakeTimerEngine()
        let machine = CycleStateMachine(timerEngine: timer, now: referenceDate)
        var completedBreaks: [(TimerPhase, Bool)] = []
        machine.onBreakComplete = { phase, wasManual in
            completedBreaks.append((phase, wasManual))
        }

        machine.startInitialFocus(now: referenceDate)
        machine.startManualLongBreak(now: referenceDate)

        XCTAssertEqual(machine.timerState.phase, .longBreak)

        timer.triggerCompletion()
        drainMainQueue()

        XCTAssertEqual(completedBreaks.last?.0, .longBreak)
        XCTAssertEqual(completedBreaks.last?.1, true)
        XCTAssertEqual(machine.timerState.phase, .focus(block: 1))
    }

    func testRefreshAfterWakeFinishesExpiredPhase() {
        let timer = FakeTimerEngine()
        let machine = CycleStateMachine(timerEngine: timer, now: referenceDate)

        machine.startInitialFocus(now: referenceDate)
        XCTAssertEqual(machine.timerState.phase, .focus(block: 1))

        let later = referenceDate.addingTimeInterval(26 * 60)
        machine.refreshAfterWake(now: later)

        XCTAssertEqual(machine.timerState.phase, .shortBreak(block: 1))
    }

    // MARK: - Helpers

    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func drainMainQueue() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
    }

    private func advanceToLongBreak(timer: FakeTimerEngine) {
        for block in 1...4 {
            timer.triggerCompletion()
            drainMainQueue()
            if block < 4 {
                timer.triggerCompletion()
                drainMainQueue()
            }
        }
    }
}

private final class FakeTimerEngine: TimerEngineType {
    private let tickSubject = PassthroughSubject<TimerTick, Never>()
    private let completionSubject = PassthroughSubject<Void, Never>()

    private(set) var lastDuration: TimeInterval?
    private(set) var lastStartDate: Date?

    var tickPublisher: AnyPublisher<TimerTick, Never> {
        tickSubject.eraseToAnyPublisher()
    }

    var completionPublisher: AnyPublisher<Void, Never> {
        completionSubject.eraseToAnyPublisher()
    }

    func start(duration: TimeInterval, now: Date = Date()) {
        lastDuration = duration
        lastStartDate = now
        let tick = TimerTick(remaining: duration, targetDate: now.addingTimeInterval(duration), startedAt: now)
        tickSubject.send(tick)
    }

    func pause(now: Date = Date()) {}
    func resume(now: Date = Date()) {}
    func restart(duration: TimeInterval, now: Date = Date()) {
        start(duration: duration, now: now)
    }
    func cancel() {}

    func triggerCompletion() {
        completionSubject.send(())
    }
}
