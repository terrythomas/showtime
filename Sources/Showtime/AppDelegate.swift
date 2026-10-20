import AppKit
import ShowtimeCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    let model = AppModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: "Showtime")
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit Showtime", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
        model.onShowAlerts = { events in
            NSLog("Showtime ALERT: %@", events.map(\.title).joined(separator: ", "))
        }
        model.start()
    }
}
