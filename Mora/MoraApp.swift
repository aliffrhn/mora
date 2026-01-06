import SwiftUI
import AppKit

@main
struct MoraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel: AppModel
    private let menuController: MenuBarController
    private let hotKeyCenter: HotKeyCenter

    init() {
        let model = AppModel()
        _appModel = StateObject(wrappedValue: model)
        let controller = MenuBarController(viewModel: model)
        self.menuController = controller
        self.hotKeyCenter = HotKeyCenter(controller: controller)
    }

    var body: some Scene {
        MenuBarExtra {
            StatusMenuContent(viewModel: appModel, preferences: menuController.preferenceStore)
        } label: {
            let labelText: String = {
                if appModel.isPaused {
                    return "⏸︎ \(appModel.countdownText)"
                } else if appModel.isRunning {
                    return appModel.isOnBreak ? "☕︎ \(appModel.countdownText)" : appModel.countdownText
                } else {
                    return "Mora"
                }
            }()

            Text(labelText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(preferences: menuController.preferenceStore)
        }
    }
}
