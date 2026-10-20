import AppKit
import ShowtimeCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusItemController?
    let model = AppModel()
    private var alertController: AlertPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusController = StatusItemController(model: model, openSettings: { [weak self] in self?.openSettings() })
        let alerts = AlertPanelController(model: model)
        alertController = alerts
        model.onShowAlerts = { events in
            NSLog("Showtime alert: %@", events.map(\.title).joined(separator: ", "))
            alerts.present(events)
        }
        model.start()
    }

    private lazy var settingsController = SettingsWindowController(model: model)

    func openSettings() {
        settingsController.show()
    }
}
