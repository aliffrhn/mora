import AppKit
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
        let player: AVAudioPlayer
        if let dataAsset = NSDataAsset(name: event.assetName, bundle: resourceBundle) {
            player = try AVAudioPlayer(data: dataAsset.data)
        } else if let url = url(for: event) {
            player = try AVAudioPlayer(contentsOf: url)
        } else {
            throw NSError(domain: "AudioService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing audio for \(event)"])
        }
        player.prepareToPlay()
        players[event] = player
        return player
    }

    private var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return bundle
        #endif
    }

    private func url(for event: AudioEvent) -> URL? {
        resourceBundle.url(forResource: event.fileBaseName, withExtension: "wav")
            ?? resourceBundle.url(
                forResource: event.fileBaseName,
                withExtension: "wav",
                subdirectory: "Assets.xcassets/\(event.assetName).dataset"
            )
    }
}

private extension AudioEvent {
    var assetName: String {
        switch self {
        case .focusEnd:
            return "FocusEnd"
        case .breakEnd:
            return "BreakEnd"
        case .cycleComplete:
            return "CycleComplete"
        }
    }

    var fileBaseName: String {
        switch self {
        case .focusEnd:
            return "focus_end"
        case .breakEnd:
            return "break_end"
        case .cycleComplete:
            return "cycle_complete"
        }
    }
}
