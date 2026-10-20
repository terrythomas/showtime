import Foundation
@testable import ShowtimeCore

/// New York calendar so tests don't depend on the machine's time zone.
let nyCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/New_York")!
    return c
}()

/// 2026-10-19 is a Monday.
func at(_ hour: Int, _ minute: Int = 0, _ second: Int = 0, day: Int = 19) -> Date {
    nyCalendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute, second: second))!
}

func event(
    id: String = "e1", title: String = "Meeting", start: Date = at(10), minutes: Int = 30,
    location: String? = nil, notes: String? = nil, url: URL? = nil, status: Participation = .notInvited,
    calendarID: String = "cal", allDay: Bool = false, travelTime: TimeInterval? = nil
) -> CalendarEvent {
    CalendarEvent(
        eventID: id, start: start, end: start.addingTimeInterval(TimeInterval(minutes * 60)), isAllDay: allDay,
        title: title, location: location, notes: notes, url: url, calendarID: calendarID,
        myStatus: status, travelTime: travelTime
    )
}
