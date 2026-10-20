import Foundation
import Testing
@testable import ShowtimeCore

@Suite struct WorkHoursTests {
    // 2026-10-19 is Monday, 10-20 Tuesday, 10-24 Saturday.
    func hours(_ start: Int, _ end: Int, days: Set<Int> = [2, 3, 4, 5, 6]) -> WorkHours {
        WorkHours(enabled: true, weekdays: days, startMinute: start, endMinute: end)
    }

    @Test func daytimeSpan() {
        let w = hours(9 * 60, 17 * 60)
        #expect(w.allows(at(10), calendar: nyCalendar))
        #expect(!w.allows(at(17), calendar: nyCalendar))
        #expect(!w.allows(at(8, 59), calendar: nyCalendar))
        #expect(!w.allows(at(10, day: 24), calendar: nyCalendar))
    }

    @Test func disabledAllowsAnything() {
        #expect(WorkHours().allows(at(3, day: 24), calendar: nyCalendar))
    }

    @Test func defaultsAreWeekdayNineToFive() {
        let w = WorkHours()
        #expect(w.weekdays == [2, 3, 4, 5, 6])
        #expect(w.startMinute == 540 && w.endMinute == 1020)
    }

    @Test func overnightSpanBelongsToStartDay() {
        let w = hours(22 * 60, 2 * 60, days: [2])  // Monday only
        #expect(w.allows(at(23, day: 19), calendar: nyCalendar))
        #expect(w.allows(at(1, day: 20), calendar: nyCalendar))
        #expect(!w.allows(at(23, day: 20), calendar: nyCalendar))
        #expect(!w.allows(at(1, day: 19), calendar: nyCalendar))  // Sunday night's span; Sunday not enabled
    }
}

@Suite struct OverrideTests {
    let monday = event(id: "standup", start: at(10))
    let tuesday = event(id: "standup", start: at(10, day: 20))

    @Test func occurrenceHideLeavesNextOccurrence() {
        var book = OverrideBook()
        book.update(.occurrence(monday.key)) { $0.hidden = true }
        #expect(book.resolved(for: monday).hidden)
        #expect(!book.resolved(for: tuesday).hidden)
    }

    @Test func seriesHideHidesAll() {
        var book = OverrideBook()
        book.update(.series(monday.seriesID)) { $0.hidden = true }
        #expect(book.resolved(for: monday).hidden && book.resolved(for: tuesday).hidden)
    }

    @Test func occurrenceOffsetsBeatSeries() {
        var book = OverrideBook()
        book.update(.series(monday.seriesID)) { $0.alertOffsetsMinutes = [10] }
        book.update(.occurrence(monday.key)) { $0.alertOffsetsMinutes = [5] }
        #expect(book.resolved(for: monday).alertOffsetsMinutes == [5])
        #expect(book.resolved(for: tuesday).alertOffsetsMinutes == [10])
    }

    @Test func resettingRemovesEntry() {
        var book = OverrideBook()
        book.update(.occurrence(monday.key)) { $0.hidden = true }
        book.update(.occurrence(monday.key)) { $0.hidden = false }
        #expect(book.entries.isEmpty)
    }

    @Test func hiddenScopesListed() {
        var book = OverrideBook()
        book.update(.series("s")) { $0.hidden = true }
        book.update(.occurrence(monday.key)) { $0.alertOffsetsMinutes = [3] }
        #expect(book.hiddenScopes == [.series("s")])
    }

    @Test func roundTripsJSON() throws {
        var book = OverrideBook()
        book.update(.occurrence(monday.key)) { $0.hidden = true }
        book.update(.series("s")) { $0.preferredLinkURL = "https://zoom.us/j/1" }
        let back = try JSONDecoder().decode(OverrideBook.self, from: JSONEncoder().encode(book))
        #expect(back == book)
    }
}

@Suite struct EventFilterTests {
    let settings = ShowtimeSettings()

    @Test func declinedNotListed() { #expect(!EventFilter.isListed(event(status: .declined), settings: settings)) }

    @Test func onlyAccepted() {
        var s = settings
        s.onlyAccepted = true
        #expect(!EventFilter.isListed(event(status: .tentative), settings: s))
        #expect(!EventFilter.isListed(event(status: .pending), settings: s))
        #expect(EventFilter.isListed(event(status: .accepted), settings: s))
        #expect(EventFilter.isListed(event(status: .notInvited), settings: s))
        #expect(EventFilter.isListed(event(status: .organizer), settings: s))
    }

    @Test func onlyWithVideo() {
        var s = settings
        s.onlyWithVideo = true
        #expect(!EventFilter.isListed(event(), settings: s))
        #expect(EventFilter.isListed(event(location: "https://zoom.us/j/1"), settings: s))
    }

    @Test func allDayExcludedByDefault() {
        #expect(!EventFilter.isListed(event(allDay: true), settings: settings))
        var s = settings
        s.includeAllDay = true
        #expect(EventFilter.isListed(event(allDay: true), settings: s))
    }

    @Test func exclusionRuleExcludes() {
        var s = settings
        s.exclusionRules = [ExclusionRule(field: .title, comparison: .contains, value: "lunch")]
        #expect(!EventFilter.isListed(event(title: "Lunch"), settings: s))
        #expect(EventFilter.isListed(event(title: "Standup"), settings: s))
    }

    @Test func inactiveCalendarExcluded() {
        var s = settings
        s.activeCalendarIDs = ["work"]
        #expect(!EventFilter.isListed(event(calendarID: "home"), settings: s))
        #expect(EventFilter.isListed(event(calendarID: "work"), settings: s))
    }

    @Test func hiddenListedButNotAlertable() {
        let e = event()
        var book = OverrideBook()
        book.update(.occurrence(e.key)) { $0.hidden = true }
        #expect(EventFilter.isListed(e, settings: settings))
        #expect(!EventFilter.isAlertable(e, settings: settings, overrides: book))
        #expect(EventFilter.isAlertable(e, settings: settings, overrides: OverrideBook()))
    }
}
