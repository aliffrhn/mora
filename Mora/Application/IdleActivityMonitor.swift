import AppKit
import Combine

/// Monitors global user activity and emits idle/active/system events.
final class IdleActivityMonitor {
    enum EventKind {
        case thresholdExceeded(idleDuration: TimeInterval)
        case systemSleep
        case systemWake
    }

    struct Event {
        let kind: EventKind
        let timestamp: Date
    }

    private let subject = PassthroughSubject<Event, Never>()
    var events: AnyPublisher<Event, Never> { subject.eraseToAnyPublisher() }

    private var monitors: [Any] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "app.mora.idle-monitor")
    private var lastActivityDate: Date = Date()
    private var isIdleEventPending = false
    private var monitoringActive = false

    private var settings: IdleSettings
    private let workspace: NSWorkspace
    private let notificationCenter: NotificationCenter

    init(settings: IdleSettings = .default,
         workspace: NSWorkspace = .shared,
         notificationCenter: NotificationCenter = .default) {
        self.settings = settings
        self.workspace = workspace
        self.notificationCenter = notificationCenter
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard settings.enabled else { return }
        if !monitoringActive {
            installEventMonitors()
            installWorkspaceObservers()
            monitoringActive = true
        }
        scheduleIdleTimer()
    }

    func stopMonitoring() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
        workspaceObservers.forEach { notificationCenter.removeObserver($0) }
        workspaceObservers.removeAll()
        timer?.cancel()
        timer = nil
        monitoringActive = false
    }

    func updateSettings(_ newSettings: IdleSettings) {
        settings = newSettings
        if settings.enabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func installEventMonitors() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown, .scrollWheel]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            guard let self else { return }
            self.handleActivity()
        }) {
            monitors.append(monitor)
        }
    }

    private func installWorkspaceObservers() {
        let center = workspace.notificationCenter
        let willSleep = center.addObserver(forName: NSWorkspace.willSleepNotification, object: workspace, queue: .main) { [weak self] _ in
            self?.handleSystemSleep()
        }
        let didWake = center.addObserver(forName: NSWorkspace.didWakeNotification, object: workspace, queue: .main) { [weak self] _ in
            self?.handleSystemWake()
        }
        workspaceObservers.append(contentsOf: [willSleep, didWake])
    }

    private func handleActivity() {
        lastActivityDate = Date()
        isIdleEventPending = false
        scheduleIdleTimer()
    }

    private func scheduleIdleTimer() {
        timer?.cancel()
        timer = nil
        guard settings.enabled else { return }
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now() + .seconds(settings.thresholdSeconds))
        timer.setEventHandler { [weak self] in
            self?.handleIdleThreshold()
        }
        timer.resume()
        self.timer = timer
    }

    private func handleIdleThreshold() {
        guard settings.enabled else { return }
        if isIdleEventPending { return }
        isIdleEventPending = true
        let now = Date()
        let idleDuration = max(0, now.timeIntervalSince(lastActivityDate))
        subject.send(Event(kind: .thresholdExceeded(idleDuration: idleDuration), timestamp: now))
    }

    private func handleSystemSleep() {
        isIdleEventPending = true
        timer?.cancel()
        timer = nil
        subject.send(Event(kind: .systemSleep, timestamp: Date()))
    }

    private func handleSystemWake() {
        lastActivityDate = Date()
        subject.send(Event(kind: .systemWake, timestamp: lastActivityDate))
        scheduleIdleTimer()
    }
}
