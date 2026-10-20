import AppKit
import ShowtimeCore

/// Decides when alerts fire. Timing lives in `AlertScheduler`; this class only
/// wakes up at the right moments and persists what has been handled.
@MainActor
final class AlertEngine {
    private weak var model: AppModel?
    private var state: HandledStateBook
    private let store = JSONFileStore(url: AppModel.supportURL("handled-state.json"), default: HandledStateBook())
    private var fireTimer: Timer?
    private var safetyTimer: Timer?
    private var refreshTimer: Timer?

    init(model: AppModel) {
        self.model = model
        state = store.load()
        // Backstops in case a one-shot timer is delayed by sleep or App Nap.
        safetyTimer = schedule(every: 30) { $0.tick() }
        refreshTimer = schedule(every: 300) { $0.model?.refreshEvents() }
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model?.refreshEvents() }
        }
        NotificationCenter.default.addObserver(forName: .NSSystemClockDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    func update(_ change: (inout HandledStateBook) -> Void) {
        change(&state)
        save()
        reschedule()
    }

    func reschedule() {
        tick()
    }

    func tick() {
        guard let model else { return }
        let now = Date()
        model.expirePauseIfNeeded(now: now)
        state.prune(now: now)

        let result = AlertScheduler.evaluate(events: model.allEvents, now: now, ctx: context())
        for e in result.show + result.suppressed {
            state.markFired(e, at: now)
        }
        save()
        if !result.show.isEmpty {
            model.onShowAlerts?(result.show)
        }

        fireTimer?.invalidate()
        if let next = AlertScheduler.nextFireDate(events: model.allEvents, now: now, ctx: context()) {
            let delay = max(next.timeIntervalSince(now), 0.5)
            fireTimer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            }
            RunLoop.main.add(fireTimer!, forMode: .common)
        }
    }

    func context() -> SchedulingContext {
        SchedulingContext(settings: model?.settings ?? ShowtimeSettings(), overrides: model?.overrides ?? OverrideBook(),
                          state: state, pausedUntil: model?.pausedUntil, calendar: .current)
    }

    private func save() {
        do { try store.save(state) } catch { NSLog("Showtime: couldn't save alert state: \(error)") }
    }

    private func schedule(every seconds: TimeInterval, _ action: @escaping @MainActor (AlertEngine) -> Void) -> Timer {
        let timer = Timer(timeInterval: seconds, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                if let self { action(self) }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }
}
