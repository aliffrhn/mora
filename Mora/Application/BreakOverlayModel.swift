import Foundation
import SwiftUI

@MainActor
final class BreakOverlayModel: ObservableObject {
    @Published var title: String
    @Published var message: String
    @Published var remainingText: String
    @Published var progress: Double

    private let totalDuration: TimeInterval
    private let phase: TimerPhase
    private let skipAction: () -> Void
    private let dismissAction: () -> Void

    init(phase: TimerPhase, totalDuration: TimeInterval, skipAction: @escaping () -> Void, dismissAction: @escaping () -> Void) {
        self.phase = phase
        self.totalDuration = max(1, totalDuration)
        self.skipAction = skipAction
        self.dismissAction = dismissAction
        self.title = BreakOverlayModel.title(for: phase)
        self.message = BreakOverlayModel.message(for: phase)
        self.remainingText = BreakOverlayModel.format(duration: totalDuration)
        self.progress = 0
    }

    func update(remaining: TimeInterval) {
        remainingText = BreakOverlayModel.format(duration: remaining)
        let clamped = min(max(remaining, 0), totalDuration)
        progress = 1 - (clamped / totalDuration)
    }

    func skipBreak() {
        skipAction()
    }

    func dismissOverlay() {
        dismissAction()
    }

    private static func title(for phase: TimerPhase) -> String {
        switch phase {
        case .longBreak:
            return "Long break"
        default:
            return "Break time"
        }
    }

    private static func message(for phase: TimerPhase) -> String {
        switch phase {
        case .longBreak:
            return "Celebrate the mora. Step away, breathe, reset."
        default:
            return "Unwind your mind. Stretch, hydrate, refocus."
        }
    }

    private static func format(duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
