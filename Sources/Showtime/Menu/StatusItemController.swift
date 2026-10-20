import AppKit
import Combine
import ShowtimeCore
import SwiftUI

/// The menu bar icon, its next-event title, and the dropdown popover.
@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []
    private var timer: Timer?

    init(model: AppModel, openSettings: @escaping () -> Void) {
        self.model = model
        super.init()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuView(
            model: model, calendar: model.calendar, openSettings: openSettings,
            closeMenu: { [weak self] in self?.popover.performClose(nil) }
        ))
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        item.button?.imagePosition = .imageLeading

        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        refresh()
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = item.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func refresh() {
        let now = Date()
        let events = model.events.filter { !$0.isAllDay && !model.isHidden($0) }
        let current = events.first { $0.start <= now && now < $0.end }
        let next = events.first { $0.start > now }
        let title = TimeText.menuBarTitle(next: next, current: current, now: now, settings: model.settings)
        let symbol = model.isPaused ? "pause.circle.fill" : "calendar.badge.clock"
        item.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Showtime")
        item.button?.title = title.map { " \($0)" } ?? ""
    }
}
