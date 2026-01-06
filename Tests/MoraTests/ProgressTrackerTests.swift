import XCTest
@testable import Mora

final class ProgressTrackerTests: XCTestCase {
    func testRecordsFocusBlocksAndMoras() async {
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 11, day: 16, hour: 9))!
        let tracker = await MainActor.run {
            ProgressTracker(progress: nil, calendar: calendar, referenceDate: startDate)
        }

        await MainActor.run {
            tracker.recordFocusCompletion(blockIndex: 1, date: startDate)
            tracker.recordFocusCompletion(blockIndex: 2, date: startDate)
        }
        var snapshot = await MainActor.run { tracker.progress }
        XCTAssertEqual(snapshot.completedBlocks, 2)
        XCTAssertEqual(snapshot.morasEarned, 0)

        let earned = await MainActor.run {
            tracker.recordLongBreakCompletion(date: startDate)
        }
        XCTAssertFalse(earned)

        await MainActor.run {
            tracker.recordFocusCompletion(blockIndex: 4, date: startDate)
        }
        let earnedAfterFocus = await MainActor.run {
            tracker.recordLongBreakCompletion(date: startDate)
        }
        XCTAssertTrue(earnedAfterFocus)

        snapshot = await MainActor.run { tracker.progress }
        XCTAssertEqual(snapshot.morasEarned, 1)
        XCTAssertEqual(snapshot.currentCycleCount, 0)
    }

    func testResetsAtMidnight() async {
        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 11, day: 16, hour: 23, minute: 50))!
        let nextDate = calendar.date(byAdding: .hour, value: 2, to: startDate)!

        let tracker = await MainActor.run {
            ProgressTracker(progress: nil, calendar: calendar, referenceDate: startDate)
        }
        await MainActor.run {
            tracker.recordFocusCompletion(blockIndex: 1, date: startDate)
        }

        var snapshot = await MainActor.run { tracker.progress }
        XCTAssertEqual(snapshot.completedBlocks, 1)
        XCTAssertEqual(calendar.isDate(snapshot.date, inSameDayAs: startDate), true)

        await MainActor.run {
            tracker.recordFocusCompletion(blockIndex: 1, date: nextDate)
        }
        snapshot = await MainActor.run { tracker.progress }
        XCTAssertEqual(snapshot.completedBlocks, 1) // reset
        XCTAssertEqual(calendar.isDate(snapshot.date, inSameDayAs: nextDate), true)
    }
}
