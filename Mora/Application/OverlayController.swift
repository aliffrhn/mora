import AppKit
import SwiftUI

@MainActor
final class OverlayController {
    private var windows: [NSWindow] = []
    private var contentFactory: (() -> AnyView)?

    var isPresenting: Bool {
        contentFactory != nil
    }

    func present<Content: View>(view: Content) {
        contentFactory = { AnyView(view) }
        rebuildWindows()
    }

    func refreshScreensIfNeeded() {
        guard contentFactory != nil else { return }
        rebuildWindows()
    }

    func dismiss() {
        teardownWindows()
        contentFactory = nil
    }

    private func rebuildWindows() {
        teardownWindows()
        guard let factory = contentFactory else { return }
        for screen in NSScreen.screens {
            let window = makeWindow(for: screen, content: factory())
            windows.append(window)
        }
    }

    private func teardownWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    private func makeWindow(for screen: NSScreen, content: AnyView) -> NSWindow {
        let rect = screen.frame
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        window.ignoresMouseEvents = false
        window.contentView = NSHostingView(rootView: content)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        return window
    }
}
