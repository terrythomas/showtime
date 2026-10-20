import AppKit
import ShowtimeCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    let model = AppModel()
    private var alertController: AlertPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: "Showtime")
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit Showtime", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
        let alerts = AlertPanelController(model: model)
        alertController = alerts
        model.onShowAlerts = { events in
            NSLog("Showtime alert: %@", events.map(\.title).joined(separator: ", "))
            alerts.present(events)
        }
        model.start()
    }
}
