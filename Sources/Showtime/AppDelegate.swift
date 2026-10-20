import AppKit
import Combine
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
        applyHotkeys()
        hotkeyObserver = model.$settings.map(\.hotkeys).removeDuplicates().dropFirst()
            .sink { [weak self] _ in DispatchQueue.main.async { self?.applyHotkeys() } }
    }

    private var hotkeyObserver: AnyCancellable?

    private func applyHotkeys() {
        HotkeyCenter.shared.apply(model.settings.hotkeys) { [weak self] action in
            guard let self else { return }
            switch action {
            case .showMenu:
                statusController?.togglePopover()
            case .joinCall:
                if let e = JoinTarget.pick(from: model.events, now: Date()) {
                    LinkOpener.join(e, model: model)
                } else {
                    NSSound.beep()
                }
            case .togglePause:
                if model.isPaused { model.resume() } else { model.pause(until: .distantFuture) }
            }
        }
    }

    private lazy var settingsController = SettingsWindowController(model: model)

    func openSettings() {
        settingsController.show()
    }
}
