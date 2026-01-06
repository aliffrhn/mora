import AVFoundation

protocol AudioServiceType {
    var soundEnabled: Bool { get set }
    func play(event: AudioEvent)
}

enum AudioEvent: CaseIterable {
    case focusEnd
    case breakEnd
    case cycleComplete
}

final class AudioService: AudioServiceType {
    var soundEnabled: Bool = true
    private var players: [AudioEvent: AVAudioPlayer] = [:]
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func play(event: AudioEvent) {
        guard soundEnabled else { return }
        do {
            let player = try self.player(for: event)
            player.currentTime = 0
            player.play()
        } catch {
            NSLog("AudioService play error: %@", error.localizedDescription)
        }
    }

    private func player(for event: AudioEvent) throws -> AVAudioPlayer {
        if let existing = players[event] {
            return existing
        }
        guard let url = url(for: event) else {
            throw NSError(domain: "AudioService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing audio for \(event)"])
        }
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        players[event] = player
        return player
    }

    private func url(for event: AudioEvent) -> URL? {
        switch event {
        case .focusEnd:
            return bundle.url(forResource: "focus_end", withExtension: "wav")
        case .breakEnd:
            return bundle.url(forResource: "break_end", withExtension: "wav")
        case .cycleComplete:
            return bundle.url(forResource: "cycle_complete", withExtension: "wav")
        }
    }
}
