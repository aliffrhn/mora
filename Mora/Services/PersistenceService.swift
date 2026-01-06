import Foundation

protocol PersistenceServiceType {
    func save(progress: DailyProgress)
    func loadProgress() -> DailyProgress?
    func save(timerState: TimerState)
    func loadTimerState() -> TimerState?
    func clearTimerState()
}

final class PersistenceService: PersistenceServiceType {
    private enum Keys {
        static let progress = "com.mora.persistence.progress"
        static let timerState = "com.mora.persistence.timerstate"
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(progress: DailyProgress) {
        do {
            let data = try encoder.encode(progress)
            defaults.set(data, forKey: Keys.progress)
        } catch {
            NSLog("PersistenceService.save(progress:) error: %@", error.localizedDescription)
        }
    }

    func loadProgress() -> DailyProgress? {
        guard let data = defaults.data(forKey: Keys.progress) else {
            return nil
        }
        return try? decoder.decode(DailyProgress.self, from: data)
    }

    func save(timerState: TimerState) {
        do {
            let data = try encoder.encode(timerState)
            defaults.set(data, forKey: Keys.timerState)
        } catch {
            NSLog("PersistenceService.save(timerState:) error: %@", error.localizedDescription)
        }
    }

    func loadTimerState() -> TimerState? {
        guard let data = defaults.data(forKey: Keys.timerState) else {
            return nil
        }
        return try? decoder.decode(TimerState.self, from: data)
    }

    func clearTimerState() {
        defaults.removeObject(forKey: Keys.timerState)
    }
}
