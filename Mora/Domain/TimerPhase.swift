import Foundation

indirect enum TimerPhase: Equatable, Codable {
    case idle
    case focus(block: Int)
    case shortBreak(block: Int)
    case longBreak
    case paused(TimerPhase)

    private enum CodingKeys: String, CodingKey {
        case caseName
        case block
        case embedded
    }

    private enum CaseName: String, Codable {
        case idle
        case focus
        case shortBreak
        case longBreak
        case paused
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseName = try container.decode(CaseName.self, forKey: .caseName)
        switch caseName {
        case .idle:
            self = .idle
        case .focus:
            let block = try container.decode(Int.self, forKey: .block)
            self = .focus(block: block)
        case .shortBreak:
            let block = try container.decode(Int.self, forKey: .block)
            self = .shortBreak(block: block)
        case .longBreak:
            self = .longBreak
        case .paused:
            let embedded = try container.decode(TimerPhase.self, forKey: .embedded)
            self = .paused(embedded)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .idle:
            try container.encode(CaseName.idle, forKey: .caseName)
        case .focus(let block):
            try container.encode(CaseName.focus, forKey: .caseName)
            try container.encode(block, forKey: .block)
        case .shortBreak(let block):
            try container.encode(CaseName.shortBreak, forKey: .caseName)
            try container.encode(block, forKey: .block)
        case .longBreak:
            try container.encode(CaseName.longBreak, forKey: .caseName)
        case .paused(let embedded):
            try container.encode(CaseName.paused, forKey: .caseName)
            try container.encode(embedded, forKey: .embedded)
        }
    }
}
