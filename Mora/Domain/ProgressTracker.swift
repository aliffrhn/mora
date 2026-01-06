import Foundation

struct DailyProgress: Codable, Equatable {
    var date: Date
    var completedBlocks: Int
    var morasEarned: Int
    var currentCycleCount: Int
    var idleEvents: [IdleEvent]

    enum CodingKeys: String, CodingKey {
        case date, completedBlocks, morasEarned, currentCycleCount, idleEvents
    }

    init(date: Date, completedBlocks: Int, morasEarned: Int, currentCycleCount: Int, idleEvents: [IdleEvent]) {
        self.date = date
        self.completedBlocks = completedBlocks
        self.morasEarned = morasEarned
        self.currentCycleCount = currentCycleCount
        self.idleEvents = idleEvents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        completedBlocks = try container.decode(Int.self, forKey: .completedBlocks)
        morasEarned = try container.decode(Int.self, forKey: .morasEarned)
        currentCycleCount = try container.decode(Int.self, forKey: .currentCycleCount)
        idleEvents = try container.decodeIfPresent([IdleEvent].self, forKey: .idleEvents) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(completedBlocks, forKey: .completedBlocks)
        try container.encode(morasEarned, forKey: .morasEarned)
        try container.encode(currentCycleCount, forKey: .currentCycleCount)
        try container.encode(idleEvents, forKey: .idleEvents)
    }
}

struct IdleEvent: Codable, Equatable, Identifiable {
    enum Decision: String, Codable {
        case resumed
        case stayedPaused
        case skipped
    }

    let id: UUID
    var startTimestamp: Date
    var resumeTimestamp: Date?
    var idleDuration: TimeInterval
    var decision: Decision?
    var phaseContext: TimerPhase

    init(id: UUID = UUID(),
         startTimestamp: Date,
         resumeTimestamp: Date? = nil,
         idleDuration: TimeInterval,
         decision: Decision? = nil,
         phaseContext: TimerPhase) {
        self.id = id
        self.startTimestamp = startTimestamp
        self.resumeTimestamp = resumeTimestamp
        self.idleDuration = idleDuration
        self.decision = decision
        self.phaseContext = phaseContext
    }
}

struct ActivityMonitorState {
    var lastInputTimestamp: Date
    var isPromptVisible: Bool
    var autoPausedPhase: TimerPhase?
}

@MainActor
final class ProgressTracker: ObservableObject {
    @Published private(set) var progress: DailyProgress
    private let calendar: Calendar

    init(progress: DailyProgress? = nil, calendar: Calendar = .current, referenceDate: Date = Date()) {
        self.calendar = calendar
        if var stored = progress {
            stored.date = calendar.startOfDay(for: stored.date)
            self.progress = stored
        } else {
            self.progress = DailyProgress(
                date: calendar.startOfDay(for: referenceDate),
                completedBlocks: 0,
                morasEarned: 0,
                currentCycleCount: 0,
                idleEvents: []
            )
        }
        normalizeDateIfNeeded(referenceDate)
    }

    func recordFocusCompletion(blockIndex: Int, date: Date = Date()) {
        normalizeDateIfNeeded(date)
        progress.completedBlocks += 1
        progress.currentCycleCount = blockIndex
    }

    @discardableResult
    func recordLongBreakCompletion(date: Date = Date()) -> Bool {
        normalizeDateIfNeeded(date)
        guard progress.currentCycleCount >= 4 else {
            progress.currentCycleCount = 0
            return false
        }
        progress.morasEarned += 1
        progress.currentCycleCount = 0
        return true
    }

    func resetCycle() {
        progress.currentCycleCount = 0
    }

    func appendIdleEvent(_ event: IdleEvent) {
        progress.idleEvents.append(event)
    }

    func resolveIdleEvent(idleEventID: UUID, decision: IdleEvent.Decision, resumeTimestamp: Date?) {
        guard let index = progress.idleEvents.firstIndex(where: { $0.id == idleEventID }) else { return }
        progress.idleEvents[index].decision = decision
        progress.idleEvents[index].resumeTimestamp = resumeTimestamp
    }

    private func normalizeDateIfNeeded(_ date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        guard !calendar.isDate(progress.date, inSameDayAs: startOfDay) else {
            return
        }
        progress = DailyProgress(
            date: startOfDay,
            completedBlocks: 0,
            morasEarned: 0,
            currentCycleCount: 0,
            idleEvents: []
        )
    }
}
