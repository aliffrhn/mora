import Foundation

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

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        userDefaults.register(defaults: [
            Keys.soundEnabled: true,
            Keys.idleEnabled: false,
            Keys.idleThresholdSeconds: 60
        ])
        soundEnabled = userDefaults.bool(forKey: Keys.soundEnabled)
        idleEnabled = userDefaults.bool(forKey: Keys.idleEnabled)
        let storedThreshold = userDefaults.integer(forKey: Keys.idleThresholdSeconds)
        idleThresholdSeconds = storedThreshold == 0 ? 60 : PreferenceStore.clampIdleThreshold(storedThreshold)
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

    private static func clampIdleThreshold(_ value: Int) -> Int {
        return min(max(value, 30), 600)
    }

    private enum Keys {
        static let soundEnabled = "com.mora.preferences.soundEnabled"
        static let idleEnabled = "com.mora.preferences.idleEnabled"
        static let idleThresholdSeconds = "com.mora.preferences.idleThresholdSeconds"
    }
}
