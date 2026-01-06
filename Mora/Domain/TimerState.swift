import Foundation

struct TimerState: Equatable, Codable {
    var phase: TimerPhase
    var remaining: TimeInterval
    var targetDate: Date
    var startedAt: Date

    init(phase: TimerPhase, remaining: TimeInterval, targetDate: Date, startedAt: Date) {
        self.phase = phase
        self.remaining = remaining
        self.targetDate = targetDate
        self.startedAt = startedAt
    }
}
