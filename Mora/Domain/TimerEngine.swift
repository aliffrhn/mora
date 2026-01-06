import Foundation
import Combine

struct TimerTick {
    let remaining: TimeInterval
    let targetDate: Date
    let startedAt: Date
}

protocol TimerEngineType: AnyObject {
    var tickPublisher: AnyPublisher<TimerTick, Never> { get }
    var completionPublisher: AnyPublisher<Void, Never> { get }
    func start(duration: TimeInterval, now: Date)
    func pause(now: Date)
    func resume(now: Date)
    func restart(duration: TimeInterval, now: Date)
    func cancel()
}

final class TimerEngine: TimerEngineType {
    private enum State {
        case idle
        case running(targetDate: Date, startedAt: Date)
        case paused(remaining: TimeInterval)
    }

    private let tickSubject = PassthroughSubject<TimerTick, Never>()
    private let completionSubject = PassthroughSubject<Void, Never>()
    private var timer: DispatchSourceTimer?
    private var state: State = .idle
    private let queue = DispatchQueue(label: "app.mora.timer.engine", qos: .userInitiated)

    var tickPublisher: AnyPublisher<TimerTick, Never> { tickSubject.eraseToAnyPublisher() }
    var completionPublisher: AnyPublisher<Void, Never> { completionSubject.eraseToAnyPublisher() }

    func start(duration: TimeInterval, now: Date = Date()) {
        queue.sync {
            cancelTimerLocked()
            state = .running(targetDate: now.addingTimeInterval(duration), startedAt: now)
            scheduleTimerLocked()
            sendTickLocked(now: now)
        }
    }

    func pause(now: Date = Date()) {
        queue.sync {
            guard case let .running(targetDate, _) = state else { return }
            cancelTimerLocked()
            let remaining = max(0, targetDate.timeIntervalSince(now))
            state = .paused(remaining: remaining)
            tickSubject.send(TimerTick(remaining: remaining, targetDate: now.addingTimeInterval(remaining), startedAt: now))
        }
    }

    func resume(now: Date = Date()) {
        queue.sync {
            guard case let .paused(remaining) = state else { return }
            state = .running(targetDate: now.addingTimeInterval(remaining), startedAt: now)
            scheduleTimerLocked()
            sendTickLocked(now: now)
        }
    }

    func restart(duration: TimeInterval, now: Date = Date()) {
        start(duration: duration, now: now)
    }

    func cancel() {
        queue.sync {
            cancelTimerLocked()
            state = .idle
        }
    }

    private func scheduleTimerLocked() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.handleTickLocked()
        }
        timer.resume()
        self.timer = timer
    }

    private func handleTickLocked() {
        let now = Date()
        sendTickLocked(now: now)
    }

    private func sendTickLocked(now: Date) {
        guard case let .running(targetDate, startedAt) = state else { return }
        let remaining = max(0, targetDate.timeIntervalSince(now))
        tickSubject.send(TimerTick(remaining: remaining, targetDate: targetDate, startedAt: startedAt))
        if remaining <= 0 {
            completionSubject.send(())
            cancelTimerLocked()
            state = .idle
        }
    }

    private func cancelTimerLocked() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
    }
}
