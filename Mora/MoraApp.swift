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
            let (iconName, text): (String?, String) = {
                if appModel.isPaused {
                    return ("pause.fill", appModel.countdownText)
                } else if appModel.isRunning {
                    if appModel.isOnBreak {
                        return ("cup.and.saucer.fill", appModel.countdownText)
                    } else {
                        return (nil, appModel.countdownText)
                    }
                } else {
                    return (nil, "Mora")
                }
            }()

            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(preferences: menuController.preferenceStore)
        }
    }
}
