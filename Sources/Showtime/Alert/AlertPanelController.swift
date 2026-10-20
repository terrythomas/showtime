import AppKit
import ShowtimeCore
import SwiftUI

/// The events currently on screen, shared by every screen's panel.
@MainActor
final class AlertGroup: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var shortcutsActive = false
}

private final class AlertPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Shows the full-screen alert on the configured screens.
@MainActor
final class AlertPanelController {
    private let model: AppModel
    private let group = AlertGroup()
    private var panels: [NSPanel] = []
    private var keyMonitor: Any?
    private var autoCloseTimer: Timer?
    private var shortcutTimer: Timer?

    init(model: AppModel) {
        self.model = model
    }

    var isVisible: Bool { !panels.isEmpty }

    func present(_ events: [CalendarEvent]) {
        let known = Set(group.events.map(\.key))
        group.events += events.filter { !known.contains($0.key) }
        group.events.sort { $0.start < $1.start }
        guard !isVisible else { return }

        let settings = model.settings
        for screen in targetScreens(settings.screenMode) {
            let panel = AlertPanel(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false, screen: screen)
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.isReleasedWhenClosed = false
            panel.contentView = NSHostingView(rootView: AlertView(group: group, actions: self, settings: settings))
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()
            panels.append(panel)
        }
        NSApp.activate(ignoringOtherApps: true)
        panels.first?.makeKey()

        SoundPlayer.shared.play(settings.soundName, volume: settings.soundVolume, repeating: settings.repeatSound)
        group.shortcutsActive = false
        shortcutTimer = Timer.scheduledTimer(withTimeInterval: settings.shortcutDelaySeconds, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.group.shortcutsActive = true }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let key = KeyPress(code: event.keyCode, characters: event.charactersIgnoringModifiers?.lowercased(),
                               hasCommandModifiers: !event.modifierFlags.intersection([.command, .control, .option]).isEmpty)
            let handled = MainActor.assumeIsolated { self?.handleKey(key) ?? false }
            return handled ? nil : event
        }
        if settings.autoCloseEnabled {
            autoCloseTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.autoCloseMinutes * 60), repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.close() }
            }
        }
    }

    /// Hides the alert without dismissing, so later alert times still fire.
    func close() {
        SoundPlayer.shared.stop()
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        autoCloseTimer?.invalidate()
        shortcutTimer?.invalidate()
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        group.events.removeAll()
    }

    // MARK: Actions

    func join(_ e: CalendarEvent) {
        guard LinkOpener.join(e, model: model) else { return }
        model.dismiss(e)
        remove(e)
    }

    func showInCalendar(_ e: CalendarEvent) {
        close()
        model.calendar.showInCalendar(e)
    }

    func dismissAll() {
        group.events.forEach(model.dismiss)
        close()
    }

    func snoozeAll(minutes: Int) {
        group.events.forEach { model.snooze($0, minutes: minutes) }
        close()
    }

    func snoozeAllUntilStart() {
        group.events.forEach(model.snoozeUntilStart)
        close()
    }

    private func remove(_ e: CalendarEvent) {
        group.events.removeAll { $0.key == e.key }
        if group.events.isEmpty { close() }
    }

    private struct KeyPress: Sendable {
        let code: UInt16
        let characters: String?
        let hasCommandModifiers: Bool
    }

    private func handleKey(_ key: KeyPress) -> Bool {
        guard group.shortcutsActive, group.events.count == 1, let e = group.events.first, !key.hasCommandModifiers else { return false }
        switch key.code {
        case 36, 76: join(e)  // Return, Enter
        case 53: dismissAll()  // Esc
        default:
            switch key.characters {
            case "1": snoozeAll(minutes: model.settings.snooze1Minutes)
            case "2": snoozeAll(minutes: model.settings.snooze2Minutes)
            case "s": snoozeAllUntilStart()
            case "c": showInCalendar(e)
            default: return false
            }
        }
        return true
    }

    private func targetScreens(_ mode: ScreenMode) -> [NSScreen] {
        let mouse = NSEvent.mouseLocation
        let active = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        switch mode {
        case .active: return [active]
        case .all: return NSScreen.screens
        case .named(let name): return [NSScreen.screens.first { $0.localizedName == name } ?? active]
        }
    }
}
