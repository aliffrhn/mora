import Foundation

struct IdleSettings: Codable, Equatable, Sendable {
    var enabled: Bool
    var thresholdSeconds: Int

    static let `default` = IdleSettings(enabled: true, thresholdSeconds: 60)
}
