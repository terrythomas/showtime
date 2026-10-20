import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let model: AppModel
    private var window: NSWindow?

    init(model: AppModel) {
        self.model = model
    }

    func show() {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model, calendar: model.calendar)))
            w.title = "Showtime Settings"
            w.styleMask = [.titled, .closable, .miniaturizable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var calendar: CalendarSource

    var body: some View {
        TabView {
            GeneralTab(model: model).tabItem { Label("General", systemImage: "gearshape") }
            AlertsTab(model: model).tabItem { Label("Alerts", systemImage: "bell") }
            CalendarsTab(model: model, calendar: calendar).tabItem { Label("Calendars", systemImage: "calendar") }
            FiltersTab(model: model).tabItem { Label("Filters", systemImage: "line.3.horizontal.decrease.circle") }
            ShortcutsTab(model: model).tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 560, height: 560)
    }
}
