import Foundation

/// What has already happened to one occurrence's alerts.
public struct OccurrenceState: Codable, Equatable, Sendable {
    public var dismissed = false
    public var snoozedUntil: Date?
    /// Every alert time at or before this has been shown (or deliberately dropped).
    public var lastFired: Date?
    public var eventEnd: Date

    public init(eventEnd: Date) {
        self.eventEnd = eventEnd
    }
}

/// Persisted so a relaunch doesn't repeat alerts that were already handled.
public struct HandledStateBook: Codable, Equatable, Sendable {
    public var states: [OccurrenceKey: OccurrenceState] = [:]

    public init() {}

    public subscript(e: CalendarEvent) -> OccurrenceState? { states[e.key] }

    public mutating func dismiss(_ e: CalendarEvent) {
        modify(e) { $0.dismissed = true }
    }

    public mutating func snooze(_ e: CalendarEvent, until: Date) {
        modify(e) { $0.snoozedUntil = until }
    }

    public mutating func markFired(_ e: CalendarEvent, at time: Date) {
        modify(e) { s in
            s.lastFired = max(s.lastFired ?? time, time)
            if let snooze = s.snoozedUntil, time >= snooze { s.snoozedUntil = nil }
        }
    }

    public mutating func prune(now: Date) {
        states = states.filter { $0.value.eventEnd >= now }
    }

    private mutating func modify(_ e: CalendarEvent, _ change: (inout OccurrenceState) -> Void) {
        var s = states[e.key] ?? OccurrenceState(eventEnd: e.end)
        s.eventEnd = e.end
        change(&s)
        states[e.key] = s
    }
}
