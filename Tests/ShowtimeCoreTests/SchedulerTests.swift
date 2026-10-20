import Foundation
import Testing
@testable import ShowtimeCore

@Suite struct SchedulerTests {
    func ctx(offsets: [Int] = [1], configure: (inout SchedulingContext) -> Void = { _ in }) -> SchedulingContext {
        var s = ShowtimeSettings()
        s.alertOffsetsMinutes = offsets
        var c = SchedulingContext(settings: s, overrides: OverrideBook(), state: HandledStateBook(), pausedUntil: nil, calendar: nyCalendar)
        configure(&c)
        return c
    }

    func shown(_ events: [CalendarEvent], _ now: Date, _ c: SchedulingContext) -> [String] {
        AlertScheduler.evaluate(events: events, now: now, ctx: c).show.map(\.title)
    }

    let meeting = event(title: "Standup", start: at(10))

    @Test func firesAtOffset() {
        var c = ctx(offsets: [10, 1])
        #expect(shown([meeting], at(9, 49), c).isEmpty)
        #expect(shown([meeting], at(9, 50), c) == ["Standup"])
        c.state.markFired(meeting, at: at(9, 50))
        #expect(shown([meeting], at(9, 55), c).isEmpty)
        #expect(shown([meeting], at(9, 59), c) == ["Standup"])
    }

    @Test func nextFireDateIsEarliestPending() {
        var c = ctx(offsets: [10, 1])
        #expect(AlertScheduler.nextFireDate(events: [meeting], now: at(9), ctx: c) == at(9, 50))
        c.state.markFired(meeting, at: at(9, 50))
        #expect(AlertScheduler.nextFireDate(events: [meeting], now: at(9, 50), ctx: c) == at(9, 59))
    }

    @Test func catchUpAfterSleepShowsOnce() {
        var c = ctx(offsets: [10, 1])
        #expect(shown([meeting], at(9, 59, 30), c) == ["Standup"])
        c.state.markFired(meeting, at: at(9, 59, 30))
        #expect(shown([meeting], at(9, 59, 45), c).isEmpty)
        #expect(AlertScheduler.nextFireDate(events: [meeting], now: at(9, 59, 45), ctx: c) == nil)
    }

    @Test func endedEventsNeverShow() {
        let past = event(start: at(9), minutes: 30)
        #expect(shown([past], at(9, 31), ctx()).isEmpty)
    }

    @Test func ongoingEventStillCatchesUp() {
        #expect(shown([meeting], at(10, 5), ctx()) == ["Standup"])
    }

    @Test func dismissStopsLaterAlerts() {
        var c = ctx(offsets: [10, 1])
        c.state.markFired(meeting, at: at(9, 50))
        c.state.dismiss(meeting)
        #expect(shown([meeting], at(9, 59), c).isEmpty)
        #expect(AlertScheduler.nextFireDate(events: [meeting], now: at(9, 50), ctx: c) == nil)
    }

    @Test func snoozeSkipsEarlierAndKeepsLater() {
        var c = ctx(offsets: [10, 5, 1])
        c.state.markFired(meeting, at: at(9, 50))
        c.state.snooze(meeting, until: at(9, 57))
        #expect(shown([meeting], at(9, 55), c).isEmpty)
        #expect(shown([meeting], at(9, 57), c) == ["Standup"])
        c.state.markFired(meeting, at: at(9, 57))
        #expect(shown([meeting], at(9, 58), c).isEmpty)
        #expect(shown([meeting], at(9, 59), c) == ["Standup"])
    }

    @Test func snoozeUntilStart() {
        var c = ctx()
        c.state.markFired(meeting, at: at(9, 59))
        c.state.snooze(meeting, until: at(10))
        #expect(AlertScheduler.nextFireDate(events: [meeting], now: at(9, 59), ctx: c) == at(10))
    }

    @Test func snoozeAfterStartStillFires() {
        var c = ctx()
        c.state.markFired(meeting, at: at(10, 2))
        c.state.snooze(meeting, until: at(10, 3))
        #expect(shown([meeting], at(10, 3), c) == ["Standup"])
    }

    @Test func pausedSuppressesAndDrops() {
        var c = ctx(offsets: [10, 1]) { $0.pausedUntil = at(9, 58) }
        let result = AlertScheduler.evaluate(events: [meeting], now: at(9, 50), ctx: c)
        #expect(result.show.isEmpty)
        #expect(result.suppressed.map(\.title) == ["Standup"])
        c.state.markFired(meeting, at: at(9, 50))
        #expect(shown([meeting], at(9, 58, 30), c).isEmpty)
        #expect(shown([meeting], at(9, 59), c) == ["Standup"])
    }

    @Test func nextFireDateIncludesPauseEnd() {
        let c = ctx(offsets: [1]) { $0.pausedUntil = at(9, 30) }
        #expect(AlertScheduler.nextFireDate(events: [meeting], now: at(9), ctx: c) == at(9, 30))
    }

    @Test func outsideWorkHoursSuppressed() {
        let late = event(title: "Late", start: at(18))
        let c = ctx { $0.settings.workHours = WorkHours(enabled: true, weekdays: [2, 3, 4, 5, 6], startMinute: 540, endMinute: 1020) }
        let result = AlertScheduler.evaluate(events: [late], now: at(17, 59), ctx: c)
        #expect(result.show.isEmpty && result.suppressed.map(\.title) == ["Late"])
    }

    @Test func occurrencesAreIndependent() {
        let monday = event(id: "standup", title: "Mon", start: at(10))
        let tuesday = event(id: "standup", title: "Tue", start: at(10, day: 20))
        var c = ctx()
        c.state.dismiss(monday)
        #expect(shown([monday, tuesday], at(9, 59, day: 20), c) == ["Tue"])
    }

    @Test func movedEventAlertsAgain() {
        var c = ctx()
        c.state.dismiss(meeting)
        var moved = meeting
        moved.start = at(11)
        moved.end = at(11, 30)
        #expect(shown([moved], at(10, 59), c) == ["Standup"])
    }

    @Test func perEventOffsetsOverrideGlobal() {
        var c = ctx()
        c.overrides.update(.series(meeting.seriesID)) { $0.alertOffsetsMinutes = [15] }
        #expect(AlertScheduler.fireTimes(for: meeting, ctx: c) == [at(9, 45)])
    }

    @Test func hiddenNeverFires() {
        var c = ctx()
        c.overrides.update(.occurrence(meeting.key)) { $0.hidden = true }
        #expect(shown([meeting], at(9, 59), c).isEmpty)
        #expect(AlertScheduler.fireTimes(for: meeting, ctx: c).isEmpty)
    }

    @Test func declinedNeverFires() {
        #expect(shown([event(start: at(10), status: .declined)], at(9, 59), ctx()).isEmpty)
    }

    @Test func travelTimeShiftsWhenEnabled() {
        let trip = event(start: at(10), travelTime: 1800)
        #expect(AlertScheduler.fireTimes(for: trip, ctx: ctx()) == [at(9, 59)])
        let c = ctx { $0.settings.includeTravelTime = true }
        #expect(AlertScheduler.fireTimes(for: trip, ctx: c) == [at(9, 29)])
    }

    @Test func allDayFiresAtConfiguredMinute() {
        let holiday = event(start: at(0), minutes: 24 * 60, allDay: true)
        let c = ctx { $0.settings.includeAllDay = true }
        #expect(AlertScheduler.fireTimes(for: holiday, ctx: c) == [at(9)])
    }

    @Test func duplicateOffsetsCollapse() {
        #expect(AlertScheduler.fireTimes(for: meeting, ctx: ctx(offsets: [1, 1])) == [at(9, 59)])
    }

    @Test func pruneDropsEnded() {
        var book = HandledStateBook()
        book.dismiss(meeting)
        book.prune(now: at(10, 29))
        #expect(book.states.count == 1)
        book.prune(now: at(10, 31))
        #expect(book.states.isEmpty)
    }

    @Test func stateBookRoundTripsJSON() throws {
        var book = HandledStateBook()
        book.markFired(meeting, at: at(9, 59))
        book.snooze(meeting, until: at(10, 1))
        let back = try JSONDecoder().decode(HandledStateBook.self, from: JSONEncoder().encode(book))
        #expect(back == book)
    }
}
