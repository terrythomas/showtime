import Foundation

public struct SchedulingContext: Sendable {
    public var settings: ShowtimeSettings
    public var overrides: OverrideBook
    public var state: HandledStateBook
    /// `.distantFuture` means paused indefinitely.
    public var pausedUntil: Date?
    public var calendar: Calendar

    public init(settings: ShowtimeSettings, overrides: OverrideBook, state: HandledStateBook, pausedUntil: Date?, calendar: Calendar) {
        self.settings = settings
        self.overrides = overrides
        self.state = state
        self.pausedUntil = pausedUntil
        self.calendar = calendar
    }
}

public struct Evaluation: Equatable, Sendable {
    /// Due events to alert about now.
    public var show: [CalendarEvent]
    /// Due events whose alert is dropped because alerts are paused or it's outside work hours.
    public var suppressed: [CalendarEvent]
}

/// Pure alert timing. The caller marks every due event (shown or suppressed) as fired.
public enum AlertScheduler {
    /// Pending alert times for the event, sorted.
    public static func fireTimes(for e: CalendarEvent, ctx: SchedulingContext) -> [Date] {
        guard EventFilter.isAlertable(e, settings: ctx.settings, overrides: ctx.overrides) else { return [] }
        let state = ctx.state[e]
        if state?.dismissed == true { return [] }

        var times: Set<Date>
        if e.isAllDay {
            let day = ctx.calendar.startOfDay(for: e.start)
            times = [day.addingTimeInterval(TimeInterval(ctx.settings.allDayAlertMinuteOfDay * 60))]
        } else {
            let offsets = ctx.overrides.resolved(for: e).alertOffsetsMinutes ?? ctx.settings.alertOffsetsMinutes
            let travel = ctx.settings.includeTravelTime ? (e.travelTime ?? 0) : 0
            times = Set(offsets.map { e.start.addingTimeInterval(-TimeInterval($0 * 60) - travel) })
        }
        if let snooze = state?.snoozedUntil {
            times = times.filter { $0 >= snooze }
            times.insert(snooze)
        }
        if let last = state?.lastFired {
            times = times.filter { $0 > last }
        }
        return times.sorted()
    }

    public static func evaluate(events: [CalendarEvent], now: Date, ctx: SchedulingContext) -> Evaluation {
        let paused = ctx.pausedUntil.map { $0 > now } ?? false
        let quiet = paused || !ctx.settings.workHours.allows(now, calendar: ctx.calendar)
        var result = Evaluation(show: [], suppressed: [])
        for e in events where e.end > now {
            guard let first = fireTimes(for: e, ctx: ctx).first, first <= now else { continue }
            if quiet { result.suppressed.append(e) } else { result.show.append(e) }
        }
        return result
    }

    public static func nextFireDate(events: [CalendarEvent], now: Date, ctx: SchedulingContext) -> Date? {
        var candidates = events.filter { $0.end > now }.compactMap { e in
            fireTimes(for: e, ctx: ctx).first(where: { $0 > now })
        }
        if let pause = ctx.pausedUntil, pause > now { candidates.append(pause) }
        return candidates.min()
    }

    /// True when work hours will drop every remaining alert for the event, so the menu can say so.
    public static func allAlertsOutsideWorkHours(_ e: CalendarEvent, ctx: SchedulingContext) -> Bool {
        guard ctx.settings.workHours.enabled else { return false }
        let times = fireTimes(for: e, ctx: ctx)
        return !times.isEmpty && times.allSatisfy { !ctx.settings.workHours.allows($0, calendar: ctx.calendar) }
    }
}
