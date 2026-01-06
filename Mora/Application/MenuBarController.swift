import AppKit
import Combine
import Foundation

@MainActor
final class MenuBarController {
    let viewModel: AppModel
    let preferenceStore: PreferenceStore

    private let cycleMachine: CycleStateMachine
    private var audioService: AudioServiceType
    private let overlayController: OverlayController
    private let systemEventsService: SystemEventsServiceType
    private let persistence: PersistenceServiceType
    private let progressTracker: ProgressTracker
    private let idleMonitor: IdleActivityMonitor

    private var cancellables: Set<AnyCancellable> = []
    private var breakOverlayModel: BreakOverlayModel?
    private var suppressedOverlayPhase: TimerPhase?
    private var pendingIdleEventID: UUID?

    init(viewModel: AppModel = AppModel(),
         timerEngine: TimerEngineType = TimerEngine(),
         preferenceStore: PreferenceStore = PreferenceStore(),
         audioService: AudioServiceType = AudioService(),
         overlayController: OverlayController = OverlayController(),
         systemEventsService: SystemEventsServiceType = SystemEventsService(),
         persistence: PersistenceServiceType = PersistenceService(),
         calendar: Calendar = .current,
         now: Date = Date()) {
        self.viewModel = viewModel
        self.preferenceStore = preferenceStore
        self.audioService = audioService
        self.overlayController = overlayController
        self.systemEventsService = systemEventsService
        self.persistence = persistence
        self.idleMonitor = IdleActivityMonitor(settings: preferenceStore.currentIdleSettings)

        if let storedProgress = persistence.loadProgress() {
            self.progressTracker = ProgressTracker(progress: storedProgress, calendar: calendar, referenceDate: now)
        } else {
            self.progressTracker = ProgressTracker(calendar: calendar, referenceDate: now)
        }

        let persistedState = persistence.loadTimerState()
        self.cycleMachine = CycleStateMachine(timerEngine: timerEngine, restoredState: persistedState, now: now)
        viewModel.controller = self
        viewModel.apply(progress: progressTracker.progress)
        if preferenceStore.currentIdleSettings.enabled {
            idleMonitor.startMonitoring()
        }
        bind()
    }

    func startOrResume() {
        if viewModel.isPaused {
            resume()
        } else {
            start()
        }
    }

    func start() {
        clearPendingIdleEvent()
        cycleMachine.startInitialFocus()
    }

    func pause() {
        cycleMachine.pause()
    }

    func resume() {
        clearPendingIdleEvent()
        cycleMachine.resume()
    }

    func restart() {
        clearPendingIdleEvent()
        cycleMachine.restartPhase()
    }

    func skipBreak() {
        cycleMachine.skipBreak()
        hideBreakOverlay()
        clearPendingIdleEvent()
    }

    func dismissBreakOverlay() {
        overlayController.dismiss()
        breakOverlayModel = nil
        suppressedOverlayPhase = unwrapped(phase: cycleMachine.timerState.phase)
    }

    func pauseFor(duration: TimeInterval, now: Date = Date()) {
        clearPendingIdleEvent()
        cycleMachine.pause(now: now)
    }

    func pauseUntilTomorrow(now: Date = Date()) {
        clearPendingIdleEvent()
        cycleMachine.pause(now: now)
    }

    func startShortBreak(now: Date = Date()) {
        clearPendingIdleEvent()
        cycleMachine.startManualShortBreak(now: now)
    }

    func startLongBreak(now: Date = Date()) {
        clearPendingIdleEvent()
        cycleMachine.startManualLongBreak(now: now)
    }

    private func bind() {
        cycleMachine.$timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.viewModel.apply(timerState: state)
                self.updateOverlay(for: state)
                self.persist(state: state)
            }
            .store(in: &cancellables)

        preferenceStore.$soundEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.audioService.soundEnabled = enabled
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(preferenceStore.$idleEnabled, preferenceStore.$idleThresholdSeconds)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled, threshold in
                let settings = IdleSettings(enabled: enabled, thresholdSeconds: threshold)
                self?.idleMonitor.updateSettings(settings)
            }
            .store(in: &cancellables)

        idleMonitor.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleIdleMonitorEvent(event)
            }
            .store(in: &cancellables)

        systemEventsService.notifications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .screensChanged:
                    self.overlayController.refreshScreensIfNeeded()
                case .willSleep:
                    self.persist(state: self.cycleMachine.timerState)
                    self.autoPauseForIdle(idleDuration: 0, timestamp: Date(), reason: .systemSleep)
                case .didWake:
                    self.cycleMachine.refreshAfterWake()
                }
            }
            .store(in: &cancellables)

        cycleMachine.onFocusBlockComplete = { [weak self] block in
            guard let self else { return }
            self.progressTracker.recordFocusCompletion(blockIndex: block)
            self.audioService.play(event: .focusEnd)
        }

        cycleMachine.onBreakComplete = { [weak self] phase, wasManual in
            guard let self else { return }
            self.audioService.play(event: .breakEnd)
            if case .longBreak = phase, !wasManual {
                if self.progressTracker.recordLongBreakCompletion() {
                    self.audioService.play(event: .cycleComplete)
                }
            }
            self.hideBreakOverlay()
        }

        progressTracker.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self else { return }
                self.viewModel.apply(progress: progress)
                self.persistence.save(progress: progress)
            }
            .store(in: &cancellables)
    }

    private func updateOverlay(for state: TimerState) {
        let effectivePhase = unwrapped(phase: state.phase)
        switch effectivePhase {
        case .shortBreak, .longBreak:
            if suppressedOverlayPhase == effectivePhase {
                breakOverlayModel?.update(remaining: state.remaining)
                return
            }
            if breakOverlayModel == nil {
                suppressedOverlayPhase = nil
                showBreakOverlay(for: state)
            }
            breakOverlayModel?.update(remaining: state.remaining)
        default:
            suppressedOverlayPhase = nil
            if breakOverlayModel != nil {
                hideBreakOverlay()
            }
        }
    }

    private func showBreakOverlay(for state: TimerState) {
        let phase = unwrapped(phase: state.phase)
        switch phase {
        case .shortBreak, .longBreak:
            break
        default:
            return
        }
        let totalDuration = max(1, state.targetDate.timeIntervalSince(state.startedAt))
        let model = BreakOverlayModel(
            phase: phase,
            totalDuration: totalDuration,
            skipAction: { [weak self] in self?.skipBreak() },
            dismissAction: { [weak self] in self?.dismissBreakOverlay() }
        )
        model.update(remaining: state.remaining)
        breakOverlayModel = model
        overlayController.present(view: BreakOverlayView(viewModel: model))
    }

    private func hideBreakOverlay() {
        overlayController.dismiss()
        breakOverlayModel = nil
        suppressedOverlayPhase = nil
    }

    private func unwrapped(phase: TimerPhase) -> TimerPhase {
        if case let .paused(original) = phase {
            return original
        }
        return phase
    }

    private func persist(state: TimerState) {
        switch state.phase {
        case .idle:
            persistence.clearTimerState()
        default:
            persistence.save(timerState: state)
        }
    }

    private func handleIdleMonitorEvent(_ event: IdleActivityMonitor.Event) {
        switch event.kind {
        case .systemWake:
            cycleMachine.refreshAfterWake()
        case .systemSleep:
            autoPauseForIdle(idleDuration: 0, timestamp: event.timestamp, reason: .systemSleep)
        case .thresholdExceeded(let idleDuration):
            autoPauseForIdle(idleDuration: idleDuration, timestamp: event.timestamp, reason: .threshold)
        }
    }

    private enum IdlePauseReason {
        case threshold
        case systemSleep
    }

    private func autoPauseForIdle(idleDuration: TimeInterval, timestamp: Date, reason: IdlePauseReason) {
        guard pendingIdleEventID == nil else { return }
        let effectivePhase = unwrapped(phase: cycleMachine.timerState.phase)
        guard case .focus = effectivePhase else { return }
        guard !viewModel.isPaused else { return }
        cycleMachine.pause()
        let startTimestamp = timestamp.addingTimeInterval(-max(0, idleDuration))
        let event = IdleEvent(
            startTimestamp: startTimestamp,
            resumeTimestamp: nil,
            idleDuration: max(0, idleDuration),
            decision: nil,
            phaseContext: effectivePhase
        )
        pendingIdleEventID = event.id
        progressTracker.appendIdleEvent(event)
        persistence.save(progress: progressTracker.progress)
    }

    private func clearPendingIdleEvent() {
        pendingIdleEventID = nil
    }

}
