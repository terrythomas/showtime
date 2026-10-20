import AppKit
import ShowtimeCore

/// Opens an event's video call, asking which link to use when there are several.
@MainActor
enum LinkOpener {
    /// Returns false when the event has no meeting link (or the chooser was cancelled).
    @discardableResult
    static func join(_ e: CalendarEvent, model: AppModel) -> Bool {
        let links = MeetingLinkDetector.links(in: e)
        guard !links.isEmpty else { return false }
        if links.count == 1 {
            open(links[0])
            return true
        }
        if let preferred = model.overrides.resolved(for: e).preferredLinkURL,
           let link = links.first(where: { $0.url.absoluteString == preferred }) {
            open(link)
            return true
        }
        guard let (link, remember) = choose(from: links, title: e.title) else { return false }
        if remember {
            model.overrides.update(.series(e.seriesID)) { $0.preferredLinkURL = link.url.absoluteString }
        }
        open(link)
        return true
    }

    static func open(_ link: MeetingLink) {
        if let app = link.appURL, NSWorkspace.shared.urlForApplication(toOpen: app) != nil {
            NSWorkspace.shared.open(app)
        } else {
            NSWorkspace.shared.open(link.url)
        }
    }

    private static func choose(from links: [MeetingLink], title: String) -> (MeetingLink, Bool)? {
        let alert = NSAlert()
        alert.messageText = "This event has more than one video call link"
        alert.informativeText = "Which one should Showtime open for “\(title)”?"
        for link in links {
            alert.addButton(withTitle: "\(link.serviceName) — \(link.url.host ?? link.url.absoluteString)")
        }
        alert.addButton(withTitle: "Cancel")
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Remember for this event"
        alert.window.level = .screenSaver + 1
        NSApp.activate(ignoringOtherApps: true)
        let index = alert.runModal().rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        guard index >= 0, index < links.count else { return nil }
        return (links[index], alert.suppressionButton?.state == .on)
    }
}
