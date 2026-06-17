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
            let text = appModel.isRunning || appModel.isPaused ? appModel.countdownText : nil

            HStack(spacing: 6) {
                Image("MenuBarIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .accessibilityHidden(true)
                if let text {
                    Text(text)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(preferences: menuController.preferenceStore)
        }
    }
}
