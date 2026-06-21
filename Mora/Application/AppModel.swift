import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var phaseDescription: String = "Idle"
    @Published var countdownText: String = "25:00"
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var currentPhase: TimerPhase = .idle
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var statusMessage: String = "Start a focus block"
    @Published var isOnBreak: Bool = false
    @Published var isInFocus: Bool = false
    @Published var todaysBlocks: Int = 0
    @Published var morasEarned: Int = 0
    @Published var currentMoraCircleCount: Int = 0

    weak var controller: MenuBarController?

    var todaysBlocksLabel: String {
        Self.countLabel(todaysBlocks, singular: "circle", plural: "circles")
    }

    var morasEarnedLabel: String {
        Self.countLabel(morasEarned, singular: "mora", plural: "moras")
    }

    var currentMoraProgressText: String {
        "\(currentMoraCircleCount)/4"
    }

    var isMoraRestReady: Bool {
        currentMoraCircleCount >= 4
    }

    var moraHelperText: String {
        let phase = Self.unwrapped(phase: currentPhase)
        let isLongBreak = {
            if case .longBreak = phase { return true }
            return false
        }()

        if isLongBreak && isMoraRestReady {
            return "Finish this break to bank 1 mora"
        }

        if isLongBreak {
            return "Rest now, then keep building"
        }

        if isMoraRestReady {
            return "Long break ready to bank a mora"
        }

        guard currentMoraCircleCount > 0 else {
            if morasEarned > 0 {
                return "\(morasEarnedLabel) banked today"
            }
            return "4 circles + long break = 1 mora"
        }

        let remaining = 4 - currentMoraCircleCount
        return "\(Self.countLabel(remaining, singular: "more circle", plural: "more circles")) until long break"
    }

    var moraProgressAccessibilityLabel: String {
        if isMoraRestReady {
            return "Mora progress, 4 of 4 circles complete. Long break ready."
        }
        return "Mora progress, \(currentMoraCircleCount) of 4 circles complete."
    }

    func start() {
        controller?.start()
    }

    func pause() {
        controller?.pause()
    }

    func resume() {
        controller?.resume()
    }

    func restart() {
        controller?.restart()
    }

    func skipBreak() {
        controller?.skipBreak()
    }

    func pause(for duration: TimeInterval) {
        controller?.pause()
    }

    func pauseUntilTomorrow() {
        controller?.pause()
    }

    func startShortBreak() {
        controller?.startShortBreak()
    }

    func startLongBreak() {
        controller?.startLongBreak()
    }

    func apply(timerState: TimerState) {
        countdownText = Self.format(duration: timerState.remaining)
        timeRemaining = timerState.remaining
        currentPhase = timerState.phase
        phaseDescription = phaseLabel(for: timerState.phase)
        isPaused = {
            if case .paused = timerState.phase { return true }
            return false
        }()
        isOnBreak = {
            if case .shortBreak = timerState.phase { return true }
            if case .longBreak = timerState.phase { return true }
            return false
        }()
        isInFocus = {
            if case .focus = timerState.phase { return true }
            return false
        }()
        isRunning = !isPaused && timerState.phase != .idle
        statusMessage = status(for: timerState.phase)
    }

    func apply(progress: DailyProgress) {
        todaysBlocks = progress.completedBlocks
        morasEarned = progress.morasEarned
        currentMoraCircleCount = min(max(progress.currentCycleCount, 0), 4)
    }

    private func phaseLabel(for phase: TimerPhase) -> String {
        switch phase {
        case .idle:
            return "Idle"
        case .focus(let block):
            return "Focus \(block)"
        case .shortBreak(let block):
            return "Break \(block)"
        case .longBreak:
            return "Long Break"
        case .paused(let original):
            return "Paused (\(phaseLabel(for: original)))"
        }
    }

    private func status(for phase: TimerPhase) -> String {
        switch phase {
        case .idle:
            return "Ready when you are"
        case .focus:
            return "Stay in flow"
        case .shortBreak, .longBreak:
            return "Take a breather"
        case .paused:
            return "Timer paused"
        }
    }

    private static func format(duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private static func countLabel(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private static func unwrapped(phase: TimerPhase) -> TimerPhase {
        if case let .paused(original) = phase {
            return unwrapped(phase: original)
        }
        return phase
    }
}
