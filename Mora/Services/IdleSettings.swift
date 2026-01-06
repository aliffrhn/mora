import Foundation

struct IdleSettings: Codable, Equatable {
    var enabled: Bool
    var thresholdSeconds: Int

    static let `default` = IdleSettings(enabled: true, thresholdSeconds: 60)
}
