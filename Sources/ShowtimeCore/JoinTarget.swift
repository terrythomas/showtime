import Foundation

public enum JoinTarget {
    /// The event the "join call" shortcut should open: the most recently started ongoing
    /// event with a meeting link, else the next one starting within 15 minutes.
    public static func pick(from events: [CalendarEvent], now: Date) -> CalendarEvent? {
        let withLinks = events.filter { !$0.isAllDay && !MeetingLinkDetector.links(in: $0).isEmpty }
        if let ongoing = withLinks.filter({ $0.start <= now && now < $0.end }).max(by: { $0.start < $1.start }) {
            return ongoing
        }
        return withLinks
            .filter { $0.start > now && $0.start.timeIntervalSince(now) <= 15 * 60 }
            .min { $0.start < $1.start }
    }
}
