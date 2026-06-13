@preconcurrency import AppKit
@preconcurrency import Combine

protocol SystemEventsServiceType {
    var notifications: AnyPublisher<SystemEvent, Never> { get }
}

enum SystemEvent: Sendable {
    case willSleep
    case didWake
    case screensChanged
}

final class SystemEventsService: NSObject, SystemEventsServiceType {
    private let subject = PassthroughSubject<SystemEvent, Never>()
    private let workspaceNotificationCenter: NotificationCenter
    private let appNotificationCenter: NotificationCenter
    private var workspaceObservers: [NSObjectProtocol] = []
    private var appObservers: [NSObjectProtocol] = []
    var notifications: AnyPublisher<SystemEvent, Never> { subject.eraseToAnyPublisher() }

    override init() {
        let workspace = NSWorkspace.shared
        self.workspaceNotificationCenter = workspace.notificationCenter
        self.appNotificationCenter = .default
        super.init()
        workspaceObservers.append(workspaceNotificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: workspace, queue: .main) { [weak subject] _ in
            subject?.send(.willSleep)
        })
        workspaceObservers.append(workspaceNotificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: workspace, queue: .main) { [weak subject] _ in
            subject?.send(.didWake)
        })
        appObservers.append(appNotificationCenter.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak subject] _ in
            subject?.send(.screensChanged)
        })
    }

    deinit {
        workspaceObservers.forEach { workspaceNotificationCenter.removeObserver($0) }
        appObservers.forEach { appNotificationCenter.removeObserver($0) }
    }
}
