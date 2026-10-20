import AppKit
import ShowtimeCore

/// App-wide state: settings, the current events, per-event overrides and pause.
@MainActor
final class AppModel: ObservableObject {
    @Published var settings: ShowtimeSettings {
        didSet {
            guard settings != oldValue else { return }
            saveSettings()
            refreshEvents()
        }
    }
    /// Every fetched event in the window, before filtering. The scheduler filters for itself.
    @Published private(set) var allEvents: [CalendarEvent] = []
    @Published var overrides: OverrideBook {
        didSet {
            try? overridesStore.save(overrides)
            engine.reschedule()
        }
    }
    @Published private(set) var pausedUntil: Date?

    let calendar = CalendarSource()
    private(set) lazy var engine = AlertEngine(model: self)
    var onShowAlerts: (([CalendarEvent]) -> Void)?

    private let overridesStore = JSONFileStore(url: AppModel.supportURL("overrides.json"), default: OverrideBook())
    private static let settingsKey = "settings.v1"
    private static let pausedKey = "pausedUntil"

    init() {
        let defaults = UserDefaults.standard
        settings = defaults.data(forKey: Self.settingsKey)
            .flatMap { try? JSONDecoder().decode(ShowtimeSettings.self, from: $0) } ?? ShowtimeSettings()
        overrides = overridesStore.load()
        let paused = defaults.double(forKey: Self.pausedKey)
        pausedUntil = paused > 0 ? Date(timeIntervalSince1970: paused) : nil
        if let p = pausedUntil, p <= Date() { pausedUntil = nil }
        calendar.onChange = { [weak self] in self?.refreshEvents() }
    }

    static func supportURL(_ name: String) -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Showtime", isDirectory: true)
            .appendingPathComponent(name)
    }

    func start() {
        refreshEvents()
        if calendar.authorization == .notDetermined {
            Task { await calendar.requestAccess() }
        }
    }

    /// Events shown in the menu.
    var events: [CalendarEvent] {
        allEvents.filter { EventFilter.isListed($0, settings: settings) }
    }

    func isHidden(_ e: CalendarEvent) -> Bool { overrides.resolved(for: e).hidden }

    func refreshEvents() {
        let now = Date()
        allEvents = calendar.events(from: now.addingTimeInterval(-6 * 3600),
                                    to: now.addingTimeInterval(TimeInterval(settings.upcomingDays) * 86400))
        #if DEBUG
        allEvents += Self.debugEvents()
        #endif
        engine.reschedule()
    }

    // MARK: Pause

    var isPaused: Bool { pausedUntil.map { $0 > Date() } ?? false }

    func pause(until date: Date) {
        setPaused(date)
    }

    func resume() {
        setPaused(nil)
    }

    private func setPaused(_ date: Date?) {
        pausedUntil = date
        if let date {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.pausedKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.pausedKey)
        }
        engine.reschedule()
    }

    /// Called when a timed pause runs out.
    func expirePauseIfNeeded(now: Date) {
        if let p = pausedUntil, p <= now { setPaused(nil) }
    }

    // MARK: Alert actions

    func dismiss(_ e: CalendarEvent) {
        engine.update { $0.dismiss(e) }
    }

    func snooze(_ e: CalendarEvent, minutes: Int) {
        engine.update { $0.snooze(e, until: Date().addingTimeInterval(TimeInterval(minutes * 60))) }
    }

    func snoozeUntilStart(_ e: CalendarEvent) {
        engine.update { $0.snooze(e, until: max(e.start, Date().addingTimeInterval(60))) }
    }

    #if DEBUG
    /// SHOWTIME_DEBUG_EVENTS="Title@<unix start>[@<link>];…" injects 2-minute fake events (debug builds only).
    private static func debugEvents() -> [CalendarEvent] {
        guard let spec = ProcessInfo.processInfo.environment["SHOWTIME_DEBUG_EVENTS"] else { return [] }
        return spec.split(separator: ";").compactMap { item in
            let parts = item.split(separator: "@", maxSplits: 2).map(String.init)
            guard parts.count >= 2, let epoch = Double(parts[1]) else { return nil }
            let start = Date(timeIntervalSince1970: epoch)
            return CalendarEvent(eventID: "debug-\(parts[0])", start: start, end: start.addingTimeInterval(120),
                                 title: parts[0], location: parts.count > 2 ? parts[2] : nil,
                                 calendarTitle: "Debug", myStatus: .accepted)
        }
    }
    #endif

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        }
    }
}
