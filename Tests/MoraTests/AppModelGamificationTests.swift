import XCTest
@testable import Mora

final class AppModelGamificationTests: XCTestCase {
    func testExplainsMoraRuleAtZeroProgress() async {
        let currentProgress = Self.progress(blocks: 0, moras: 0, cycleCount: 0)

        let helperText = await MainActor.run {
            let model = AppModel()
            model.apply(progress: currentProgress)
            return model.moraHelperText
        }

        XCTAssertEqual(helperText, "4 circles + long break = 1 mora")
    }

    func testShowsRemainingCirclesBeforeLongBreak() async {
        let currentProgress = Self.progress(blocks: 2, moras: 0, cycleCount: 2)

        let snapshot = await MainActor.run {
            let model = AppModel()
            model.apply(progress: currentProgress)
            return (model.moraHelperText, model.currentMoraProgressText)
        }

        XCTAssertEqual(snapshot.0, "2 more circles until long break")
        XCTAssertEqual(snapshot.1, "2/4")
    }

    func testPromptsUserToFinishLongBreakBeforeBankingMora() async {
        let currentProgress = Self.progress(blocks: 4, moras: 0, cycleCount: 4)
        let longBreakState = Self.timerState(phase: .longBreak)

        let helperText = await MainActor.run {
            let model = AppModel()
            model.apply(progress: currentProgress)
            model.apply(timerState: longBreakState)
            return model.moraHelperText
        }

        XCTAssertEqual(helperText, "Finish this break to bank 1 mora")
    }

    func testShowsBankedMoraAfterCycleReset() async {
        let currentProgress = Self.progress(blocks: 4, moras: 1, cycleCount: 0)

        let snapshot = await MainActor.run {
            let model = AppModel()
            model.apply(progress: currentProgress)
            return (model.moraHelperText, model.morasEarnedLabel)
        }

        XCTAssertEqual(snapshot.0, "1 mora banked today")
        XCTAssertEqual(snapshot.1, "1 mora")
    }

    private static func progress(blocks: Int, moras: Int, cycleCount: Int) -> DailyProgress {
        DailyProgress(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            completedBlocks: blocks,
            morasEarned: moras,
            currentCycleCount: cycleCount,
            idleEvents: []
        )
    }

    private static func timerState(phase: TimerPhase) -> TimerState {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        return TimerState(phase: phase, remaining: 60, targetDate: now.addingTimeInterval(60), startedAt: now)
    }
}
