import Foundation

public enum EventFilter {
    /// Whether the event appears in the menu at all.
    public static func isListed(_ e: CalendarEvent, settings: ShowtimeSettings) -> Bool {
        if let active = settings.activeCalendarIDs, !active.contains(e.calendarID) { return false }
        if e.myStatus == .declined { return false }
        if settings.onlyAccepted, ![.accepted, .organizer, .notInvited].contains(e.myStatus) { return false }
        if e.isAllDay, !settings.includeAllDay { return false }
        if settings.exclusionRules.contains(where: { $0.matches(e) }) { return false }
        if settings.onlyWithVideo, MeetingLinkDetector.links(in: e).isEmpty { return false }
        return true
    }

    /// Whether the event can raise an alert.
    public static func isAlertable(_ e: CalendarEvent, settings: ShowtimeSettings, overrides: OverrideBook) -> Bool {
        isListed(e, settings: settings) && !overrides.resolved(for: e).hidden
    }
}
