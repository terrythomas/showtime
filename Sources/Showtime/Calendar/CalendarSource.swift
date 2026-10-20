import AppKit
import EventKit
import ShowtimeCore

struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let colorHex: String
}

struct CalendarGroup: Identifiable, Hashable {
    let sourceTitle: String
    let calendars: [CalendarInfo]
    var id: String { sourceTitle }
}

/// Read-only bridge from EventKit to `CalendarEvent`. Never saves or removes anything.
@MainActor
final class CalendarSource: ObservableObject {
    @Published private(set) var authorization: CalendarAuthorization = .notDetermined
    @Published private(set) var calendarGroups: [CalendarGroup] = []
    var onChange: (() -> Void)?

    private var store = EKEventStore()
    private var observer: NSObjectProtocol?

    init() {
        refreshAuthorization()
        observer = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshAuthorization()
                self?.onChange?()
            }
        }
    }

    func refreshAuthorization() {
        authorization = switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .writeOnly: .writeOnly
        case .fullAccess, .authorized: .fullAccess
        @unknown default: .denied
        }
        if authorization == .fullAccess { loadCalendars() }
    }

    func requestAccess() async {
        _ = try? await store.requestFullAccessToEvents()
        // A store created before access was granted can keep returning nothing.
        store = EKEventStore()
        refreshAuthorization()
        onChange?()
    }

    private func loadCalendars() {
        let grouped = Dictionary(grouping: store.calendars(for: .event), by: { $0.source.title })
        calendarGroups = grouped.keys.sorted().map { source in
            CalendarGroup(sourceTitle: source, calendars: grouped[source]!
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                .map { CalendarInfo(id: $0.calendarIdentifier, title: $0.title, colorHex: Self.hex($0.cgColor)) })
        }
    }

    func events(from start: Date, to end: Date) -> [CalendarEvent] {
        guard authorization == .fullAccess else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).compactMap(Self.map).sorted { $0.start < $1.start }
    }

    func showInCalendar(_ e: CalendarEvent) {
        let id = e.eventID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? e.eventID
        if let url = URL(string: "ical://ekevent/\(id)?method=show&options=more"), NSWorkspace.shared.open(url) { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
    }

    private static func map(_ ek: EKEvent) -> CalendarEvent? {
        guard let id = ek.eventIdentifier, let start = ek.startDate, let end = ek.endDate else { return nil }
        let participants = ek.attendees ?? []
        let attendees = participants.map { p in
            Attendee(
                name: p.name ?? email(p) ?? "Unknown",
                email: email(p),
                status: participation(p.participantStatus),
                isOrganizer: p.url == ek.organizer?.url
            )
        }
        let myStatus: Participation
        if participants.isEmpty {
            myStatus = .notInvited
        } else if ek.organizer?.isCurrentUser == true {
            myStatus = .organizer
        } else if let me = participants.first(where: \.isCurrentUser) {
            myStatus = participation(me.participantStatus)
        } else {
            myStatus = .notInvited
        }
        return CalendarEvent(
            eventID: id, seriesID: ek.calendarItemIdentifier, start: start, end: end, isAllDay: ek.isAllDay,
            title: ek.title ?? "", location: ek.location, notes: ek.notes, url: ek.url,
            calendarID: ek.calendar?.calendarIdentifier ?? "", calendarTitle: ek.calendar?.title ?? "",
            calendarColorHex: hex(ek.calendar?.cgColor), myStatus: myStatus, attendees: attendees,
            travelTime: travelTime(ek)
        )
    }

    /// Calendar.app's travel time isn't public API; read it only if EventKit still has it.
    private static func travelTime(_ ek: EKEvent) -> TimeInterval? {
        guard ek.responds(to: NSSelectorFromString("travelTime")),
              let value = ek.value(forKey: "travelTime") as? NSNumber, value.doubleValue > 0 else { return nil }
        return value.doubleValue
    }

    private static func participation(_ s: EKParticipantStatus) -> Participation {
        switch s {
        case .accepted: .accepted
        case .declined: .declined
        case .tentative: .tentative
        default: .pending
        }
    }

    private static func email(_ p: EKParticipant) -> String? {
        let s = p.url.absoluteString
        return s.hasPrefix("mailto:") ? String(s.dropFirst(7)) : nil
    }

    private static func hex(_ color: CGColor?) -> String {
        guard let color, let c = NSColor(cgColor: color)?.usingColorSpace(.sRGB) else { return "#8E8E93" }
        return String(format: "#%02X%02X%02X", Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
    }
}
