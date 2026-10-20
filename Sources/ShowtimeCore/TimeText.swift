import Foundation

public enum TimeText {
    /// Live countdown on the alert, e.g. "starts in 5 min" or "started 2 min ago".
    public static func alertCountdown(start: Date, now: Date) -> String {
        let seconds = start.timeIntervalSince(now)
        if abs(seconds) < 30 { return "starting now" }
        if seconds > 0 { return "starts in \(duration(minutesUntil(seconds), compact: false))" }
        return "started \(duration(Int(-seconds / 60), compact: false)) ago"
    }

    /// Menu bar countdown: before the event "in 12 min" / "12m", during it "12 min left" / "12m left".
    public static func menuCountdown(start: Date, end: Date, now: Date, style: CountdownStyle) -> String? {
        let compact = style == .compact
        switch style {
        case .none:
            return nil
        case .regular, .compact:
            if now < start {
                let text = duration(minutesUntil(start.timeIntervalSince(now)), compact: compact)
                return compact ? text : "in \(text)"
            }
            if now < end {
                return "\(duration(minutesUntil(end.timeIntervalSince(now)), compact: compact)) left"
            }
            return nil
        }
    }

    public static func truncate(_ s: String, to n: Int) -> String {
        s.count <= n ? s : String(s.prefix(n)) + "…"
    }

    /// Text beside the menu bar icon, or nil for icon only.
    public static func menuBarTitle(next: CalendarEvent?, current: CalendarEvent?, now: Date, settings: ShowtimeSettings) -> String? {
        guard settings.menuShowNextTitle else { return nil }
        let shown: CalendarEvent
        if settings.menuShowCurrentEvent, let current, current.start <= now, now < current.end {
            shown = current
        } else if let next {
            if let hours = settings.menuNextEventWindowHours,
               next.start.timeIntervalSince(now) > TimeInterval(hours * 3600) { return nil }
            shown = next
        } else {
            return nil
        }
        let title = truncate(shown.title, to: settings.menuTitleLength)
        guard let countdown = menuCountdown(start: shown.start, end: shown.end, now: now, style: settings.menuCountdown) else {
            return title
        }
        return "\(title) · \(countdown)"
    }

    private static func minutesUntil(_ seconds: TimeInterval) -> Int {
        Int((seconds / 60).rounded(.up))
    }

    private static func duration(_ minutes: Int, compact: Bool) -> String {
        let h = minutes / 60, m = minutes % 60
        if compact {
            if h == 0 { return "\(m)m" }
            return m == 0 ? "\(h)h" : "\(h)h\(m)m"
        }
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}
