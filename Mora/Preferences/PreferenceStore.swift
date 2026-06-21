import Foundation

struct TimerDurationSettings: Equatable, Sendable {
    static let defaults = TimerDurationSettings(
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15
    )

    static let focusRange = 10...120
    static let shortBreakRange = 1...10
    static let longBreakRange = 10...60

    static let focusStep = 5
    static let shortBreakStep = 1
    static let longBreakStep = 5

    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
}

@MainActor
final class PreferenceStore: ObservableObject {
    @Published var soundEnabled: Bool {
        didSet {
            userDefaults.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }
    @Published var idleEnabled: Bool {
        didSet {
            userDefaults.set(idleEnabled, forKey: Keys.idleEnabled)
        }
    }
    @Published var idleThresholdSeconds: Int {
        didSet {
            let clamped = PreferenceStore.clampIdleThreshold(idleThresholdSeconds)
            if clamped != idleThresholdSeconds {
                idleThresholdSeconds = clamped
                return
            }
            userDefaults.set(clamped, forKey: Keys.idleThresholdSeconds)
        }
    }
    @Published var focusDurationMinutes: Int {
        didSet {
            let normalized = PreferenceStore.normalize(
                focusDurationMinutes,
                in: TimerDurationSettings.focusRange,
                step: TimerDurationSettings.focusStep
            )
            if normalized != focusDurationMinutes {
                focusDurationMinutes = normalized
            }
            userDefaults.set(normalized, forKey: Keys.focusDurationMinutes)
        }
    }
    @Published var shortBreakDurationMinutes: Int {
        didSet {
            let normalized = PreferenceStore.normalize(
                shortBreakDurationMinutes,
                in: TimerDurationSettings.shortBreakRange,
                step: TimerDurationSettings.shortBreakStep
            )
            if normalized != shortBreakDurationMinutes {
                shortBreakDurationMinutes = normalized
            }
            userDefaults.set(normalized, forKey: Keys.shortBreakDurationMinutes)
        }
    }
    @Published var longBreakDurationMinutes: Int {
        didSet {
            let normalized = PreferenceStore.normalize(
                longBreakDurationMinutes,
                in: TimerDurationSettings.longBreakRange,
                step: TimerDurationSettings.longBreakStep
            )
            if normalized != longBreakDurationMinutes {
                longBreakDurationMinutes = normalized
            }
            userDefaults.set(normalized, forKey: Keys.longBreakDurationMinutes)
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        userDefaults.register(defaults: [
            Keys.soundEnabled: true,
            Keys.idleEnabled: false,
            Keys.idleThresholdSeconds: 60,
            Keys.focusDurationMinutes: TimerDurationSettings.defaults.focusMinutes,
            Keys.shortBreakDurationMinutes: TimerDurationSettings.defaults.shortBreakMinutes,
            Keys.longBreakDurationMinutes: TimerDurationSettings.defaults.longBreakMinutes
        ])
        soundEnabled = userDefaults.bool(forKey: Keys.soundEnabled)
        idleEnabled = userDefaults.bool(forKey: Keys.idleEnabled)
        let storedThreshold = userDefaults.integer(forKey: Keys.idleThresholdSeconds)
        idleThresholdSeconds = storedThreshold == 0 ? 60 : PreferenceStore.clampIdleThreshold(storedThreshold)
        focusDurationMinutes = PreferenceStore.normalize(
            userDefaults.integer(forKey: Keys.focusDurationMinutes),
            in: TimerDurationSettings.focusRange,
            step: TimerDurationSettings.focusStep
        )
        shortBreakDurationMinutes = PreferenceStore.normalize(
            userDefaults.integer(forKey: Keys.shortBreakDurationMinutes),
            in: TimerDurationSettings.shortBreakRange,
            step: TimerDurationSettings.shortBreakStep
        )
        longBreakDurationMinutes = PreferenceStore.normalize(
            userDefaults.integer(forKey: Keys.longBreakDurationMinutes),
            in: TimerDurationSettings.longBreakRange,
            step: TimerDurationSettings.longBreakStep
        )
    }

    func toggleSound() {
        soundEnabled.toggle()
    }

    func updateIdleSettings(_ settings: IdleSettings) {
        idleEnabled = settings.enabled
        idleThresholdSeconds = PreferenceStore.clampIdleThreshold(settings.thresholdSeconds)
    }

    var currentIdleSettings: IdleSettings {
        IdleSettings(enabled: idleEnabled, thresholdSeconds: idleThresholdSeconds)
    }

    var currentTimerDurationSettings: TimerDurationSettings {
        TimerDurationSettings(
            focusMinutes: focusDurationMinutes,
            shortBreakMinutes: shortBreakDurationMinutes,
            longBreakMinutes: longBreakDurationMinutes
        )
    }

    func restoreTimerDurationDefaults() {
        focusDurationMinutes = TimerDurationSettings.defaults.focusMinutes
        shortBreakDurationMinutes = TimerDurationSettings.defaults.shortBreakMinutes
        longBreakDurationMinutes = TimerDurationSettings.defaults.longBreakMinutes
    }

    private static func clampIdleThreshold(_ value: Int) -> Int {
        return min(max(value, 30), 600)
    }

    private static func normalize(_ value: Int, in range: ClosedRange<Int>, step: Int) -> Int {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        let offset = clamped - range.lowerBound
        let roundedSteps = Int((Double(offset) / Double(step)).rounded())
        return min(range.lowerBound + roundedSteps * step, range.upperBound)
    }

    private enum Keys {
        static let soundEnabled = "com.mora.preferences.soundEnabled"
        static let idleEnabled = "com.mora.preferences.idleEnabled"
        static let idleThresholdSeconds = "com.mora.preferences.idleThresholdSeconds"
        static let focusDurationMinutes = "com.mora.preferences.focusDurationMinutes"
        static let shortBreakDurationMinutes = "com.mora.preferences.shortBreakDurationMinutes"
        static let longBreakDurationMinutes = "com.mora.preferences.longBreakDurationMinutes"
    }
}
