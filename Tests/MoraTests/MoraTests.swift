import XCTest
@testable import Mora

final class PreferenceStoreTests: XCTestCase {
    func testTimerDurationsUsePomodoroDefaults() async {
        let settings = await withPreferenceStore { store in
            store.currentTimerDurationSettings
        }

        XCTAssertEqual(settings, .defaults)
    }

    func testTimerDurationsPersistAcrossStoreInstances() async {
        let settings = await withPreferenceStore { store, defaults in
            store.focusDurationMinutes = 50
            store.shortBreakDurationMinutes = 7
            store.longBreakDurationMinutes = 30

            return PreferenceStore(userDefaults: defaults).currentTimerDurationSettings
        }

        XCTAssertEqual(
            settings,
            TimerDurationSettings(focusMinutes: 50, shortBreakMinutes: 7, longBreakMinutes: 30)
        )
    }

    func testTimerDurationsClampAndRoundToSupportedSteps() async {
        let settings = await withPreferenceStore { store in
            store.focusDurationMinutes = 43
            store.shortBreakDurationMinutes = 20
            store.longBreakDurationMinutes = 12
            return store.currentTimerDurationSettings
        }

        XCTAssertEqual(
            settings,
            TimerDurationSettings(focusMinutes: 45, shortBreakMinutes: 10, longBreakMinutes: 10)
        )
    }

    func testRestoreTimerDurationDefaultsPersistsDefaults() async {
        let settings = await withPreferenceStore { store, defaults in
            store.focusDurationMinutes = 60
            store.shortBreakDurationMinutes = 8
            store.longBreakDurationMinutes = 45
            store.restoreTimerDurationDefaults()

            return PreferenceStore(userDefaults: defaults).currentTimerDurationSettings
        }

        XCTAssertEqual(settings, .defaults)
    }

    private func withPreferenceStore<T: Sendable>(
        _ operation: @MainActor @Sendable (PreferenceStore) -> T
    ) async -> T {
        await withPreferenceStore { store, _ in operation(store) }
    }

    private func withPreferenceStore<T: Sendable>(
        _ operation: @MainActor @Sendable (PreferenceStore, UserDefaults) -> T
    ) async -> T {
        let suiteName = "PreferenceStoreTests.\(UUID().uuidString)"
        return await MainActor.run {
            let defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)
            defer { defaults.removePersistentDomain(forName: suiteName) }
            return operation(PreferenceStore(userDefaults: defaults), defaults)
        }
    }
}
