import HotKey

final class HotKeyCenter {
    private var hotKeys: [HotKey] = []

    init(controller: MenuBarController) {
        let startHotKey = HotKey(key: .s, modifiers: [.command, .shift])
        startHotKey.keyDownHandler = {
            Task { await controller.startOrResume() }
        }

        let pauseHotKey = HotKey(key: .p, modifiers: [.command, .shift])
        pauseHotKey.keyDownHandler = {
            Task { await controller.pause() }
        }

        let restartHotKey = HotKey(key: .r, modifiers: [.command, .shift])
        restartHotKey.keyDownHandler = {
            Task { await controller.restart() }
        }

        let skipHotKey = HotKey(key: .k, modifiers: [.command, .shift])
        skipHotKey.keyDownHandler = {
            Task { await controller.skipBreak() }
        }

        hotKeys = [startHotKey, pauseHotKey, restartHotKey, skipHotKey]
    }
}
