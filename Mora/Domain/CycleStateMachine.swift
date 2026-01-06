import Foundation
import Combine

final class CycleStateMachine: ObservableObject {
    struct Configuration {
        let focusDuration: TimeInterval
        let shortBreakDuration: TimeInterval
        let longBreakDuration: TimeInterval

        static let pomodoro = Configuration(focusDuration: 25 * 60, shortBreakDuration: 5 * 60, longBreakDuration: 15 * 60)
    }

    @Published private(set) var timerState: TimerState
    @Published private(set) var isPaused: Bool = false

    private let timerEngine: TimerEngineType
    private let config: Configuration
    private var cancellables: Set<AnyCancellable> = []
    private var activePhase: TimerPhase = .idle
    private var pausedContext: (phase: TimerPhase, remaining: TimeInterval)?
    private var currentFocusIndex: Int = 0
    private var lastTickDate: Date?
    private var watchdog: AnyCancellable?
    private var manualBreakResumeBlock: Int?
    private var manualBreakActive: Bool = false

    var onFocusBlockComplete: ((Int) -> Void)?
    var onBreakComplete: ((TimerPhase, Bool) -> Void)?

    init(timerEngine: TimerEngineType = TimerEngine(),
         configuration: Configuration = .pomodoro,
         restoredState: TimerState? = nil,
         now: Date = Date()) {
        self.timerEngine = timerEngine
        self.config = configuration
        self.timerState = TimerState(phase: .idle, remaining: configuration.focusDuration, targetDate: now, startedAt: now)
        bind()
        startWatchdog()
        if let restored = restoredState {
            restore(from: restored, now: now)
        }
    }

    func startInitialFocus(now: Date = Date()) {
        guard case .idle = activePhase else { return }
        beginFocus(block: 1, now: now)
    }

    func pause(now: Date = Date()) {
        guard !isPaused else { return }
        if case .idle = activePhase { return }
        if case .paused = activePhase { return }
        timerEngine.pause(now: now)
        isPaused = true
        pausedContext = (phase: activePhase, remaining: timerState.remaining)
        activePhase = .paused(activePhase)
        timerState = TimerState(phase: activePhase, remaining: timerState.remaining, targetDate: now, startedAt: now)
    }

    func resume(now: Date = Date()) {
        guard isPaused, case let .paused(originalPhase) = activePhase, let remaining = pausedContext?.remaining else { return }
        isPaused = false
        activePhase = originalPhase
        pausedContext = nil
        timerEngine.resume(now: now)
        timerState = TimerState(phase: originalPhase, remaining: remaining, targetDate: now.addingTimeInterval(remaining), startedAt: now)
    }

    func restartPhase(now: Date = Date()) {
        switch activePhase {
        case .focus(let block):
            beginFocus(block: block, now: now)
        case .shortBreak(let block):
            beginShortBreak(for: block, now: now)
        case .longBreak:
            beginLongBreak(now: now)
        case .paused(let underlying):
            activePhase = underlying
            restartPhase(now: now)
        case .idle:
            startInitialFocus(now: now)
        }
    }

    func skipBreak(now: Date = Date()) {
        switch activePhase {
        case .shortBreak(let block):
            beginFocus(block: block + 1, now: now)
        case .longBreak:
            beginFocus(block: 1, now: now)
        default:
            break
        }
        manualBreakActive = false
        manualBreakResumeBlock = nil
    }

    func startManualShortBreak(now: Date = Date()) {
        let resumeBlock = max(currentFocusIndex, 1)
        manualBreakResumeBlock = resumeBlock
        manualBreakActive = true
        transition(to: .shortBreak(block: resumeBlock), duration: config.shortBreakDuration, now: now)
    }

    func startManualLongBreak(now: Date = Date()) {
        let resumeBlock = max(currentFocusIndex, 1)
        manualBreakResumeBlock = resumeBlock
        manualBreakActive = true
        transition(to: .longBreak, duration: config.longBreakDuration, now: now)
    }

    private func bind() {
        timerEngine.tickPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tick in
                guard let self else { return }
                self.lastTickDate = Date()
                guard case .paused = self.activePhase else {
                    self.timerState = TimerState(phase: self.activePhase, remaining: tick.remaining, targetDate: tick.targetDate, startedAt: tick.startedAt)
                    return
                }
            }
            .store(in: &cancellables)

        timerEngine.completionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleCompletion()
            }
            .store(in: &cancellables)
    }

    private func handleCompletion() {
        switch activePhase {
        case .focus(let block):
            onFocusBlockComplete?(block)
            if block == 4 {
                beginLongBreak()
            } else {
                beginShortBreak(for: block)
            }
        case .shortBreak(let block):
            let manual = manualBreakActive
            let resumeBlock = manualBreakResumeBlock
            manualBreakActive = false
            manualBreakResumeBlock = nil
            onBreakComplete?(.shortBreak(block: block), manual)
            let nextBlock = manual ? (resumeBlock ?? max(currentFocusIndex, 1)) : block + 1
            beginFocus(block: nextBlock)
        case .longBreak:
            let manual = manualBreakActive
            let resumeBlock = manualBreakResumeBlock
            manualBreakActive = false
            manualBreakResumeBlock = nil
            onBreakComplete?(.longBreak, manual)
            let nextBlock = manual ? (resumeBlock ?? max(currentFocusIndex, 1)) : 1
            beginFocus(block: nextBlock)
        case .idle, .paused:
            break
        }
    }

    private func beginFocus(block: Int, now: Date = Date()) {
        currentFocusIndex = block
        transition(to: .focus(block: block), duration: config.focusDuration, now: now)
    }

    private func beginShortBreak(for block: Int, now: Date = Date()) {
        transition(to: .shortBreak(block: block), duration: config.shortBreakDuration, now: now)
    }

    private func beginLongBreak(now: Date = Date()) {
        currentFocusIndex = 0
        transition(to: .longBreak, duration: config.longBreakDuration, now: now)
    }

    private func transition(to phase: TimerPhase, duration: TimeInterval, now: Date = Date()) {
        activePhase = phase
        isPaused = false
        pausedContext = nil
        timerEngine.start(duration: duration, now: now)
        timerState = TimerState(phase: phase, remaining: duration, targetDate: now.addingTimeInterval(duration), startedAt: now)
        lastTickDate = now
    }

    private func restore(from state: TimerState, now: Date) {
        switch state.phase {
        case .idle:
            timerState = TimerState(phase: .idle, remaining: config.focusDuration, targetDate: now, startedAt: now)
            activePhase = .idle
        case .paused(let underlying):
            isPaused = true
            activePhase = .paused(underlying)
            pausedContext = (phase: underlying, remaining: state.remaining)
            timerState = TimerState(phase: .paused(underlying), remaining: state.remaining, targetDate: now.addingTimeInterval(state.remaining), startedAt: now)
        case .focus(let block):
            restoreRunningPhase(.focus(block: block), persisted: state, now: now)
        case .shortBreak(let block):
            restoreRunningPhase(.shortBreak(block: block), persisted: state, now: now)
        case .longBreak:
            restoreRunningPhase(.longBreak, persisted: state, now: now)
        }
    }

    private func restoreRunningPhase(_ phase: TimerPhase, persisted: TimerState, now: Date) {
        activePhase = phase
        switch phase {
        case .focus(let block):
            currentFocusIndex = block
        case .shortBreak(let block):
            currentFocusIndex = block
        case .longBreak:
            currentFocusIndex = 0
        default:
            break
        }
        let remaining = max(0, persisted.targetDate.timeIntervalSince(now))
        if remaining <= 0 {
            timerState = TimerState(phase: phase, remaining: 0, targetDate: now, startedAt: now)
            handleCompletion()
        } else {
            timerEngine.start(duration: remaining, now: now)
            timerState = TimerState(phase: phase, remaining: remaining, targetDate: now.addingTimeInterval(remaining), startedAt: now)
            lastTickDate = now
        }
    }

    func refreshAfterWake(now: Date = Date()) {
        switch activePhase {
        case .focus, .shortBreak, .longBreak:
            guard !isPaused else { return }
            let remaining = max(0, timerState.targetDate.timeIntervalSince(now))
            if remaining <= 0 {
                timerEngine.cancel()
                timerState = TimerState(phase: activePhase, remaining: 0, targetDate: now, startedAt: now)
                handleCompletion()
            } else {
                timerEngine.start(duration: remaining, now: now)
                timerState = TimerState(phase: activePhase, remaining: remaining, targetDate: now.addingTimeInterval(remaining), startedAt: now)
                lastTickDate = now
            }
        default:
            break
        }
    }

    private func startWatchdog() {
        watchdog = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForStall()
            }
    }

    private func checkForStall(now: Date = Date()) {
        switch activePhase {
        case .focus, .shortBreak, .longBreak:
            break
        default:
            return
        }
        guard !isPaused else { return }
        guard let lastTickDate else { return }
        if now.timeIntervalSince(lastTickDate) >= 3 {
            refreshAfterWake(now: now)
        }
    }
}
