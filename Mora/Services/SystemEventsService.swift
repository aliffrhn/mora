@preconcurrency import AppKit
@preconcurrency import Combine

protocol SystemEventsServiceType {
    var notifications: AnyPublisher<SystemEvent, Never> { get }
}

enum SystemEvent {
    case willSleep
    case didWake
    case screensChanged
}

final class SystemEventsService: NSObject, SystemEventsServiceType {
    private let subject = PassthroughSubject<SystemEvent, Never>()
    private var observers: [NSObjectProtocol] = []
    var notifications: AnyPublisher<SystemEvent, Never> { subject.eraseToAnyPublisher() }

    override init() {
        super.init()
        let notificationCenter = NotificationCenter.default
        let workspace = NSWorkspace.shared
        observers.append(notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: workspace, queue: .main) { [weak subject] _ in
            subject?.send(.willSleep)
        })
        observers.append(notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: workspace, queue: .main) { [weak subject] _ in
            subject?.send(.didWake)
        })
        observers.append(notificationCenter.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak subject] _ in
            subject?.send(.screensChanged)
        })
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
