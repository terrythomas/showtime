import Foundation

/// Alerts only show inside work hours. When `endMinute <= startMinute` the span runs
/// overnight and belongs to the weekday it started on.
public struct WorkHours: Codable, Equatable, Sendable {
    public var enabled = false
    /// Calendar weekdays, 1 = Sunday … 7 = Saturday.
    public var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    public var startMinute = 9 * 60
    public var endMinute = 17 * 60

    public init() {}

    public init(enabled: Bool, weekdays: Set<Int>, startMinute: Int, endMinute: Int) {
        self.enabled = enabled
        self.weekdays = weekdays
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    public var isOvernight: Bool { endMinute <= startMinute }

    public func allows(_ date: Date, calendar: Calendar) -> Bool {
        guard enabled else { return true }
        let parts = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let weekday = parts.weekday!
        let minute = parts.hour! * 60 + parts.minute!
        if !isOvernight {
            return weekdays.contains(weekday) && minute >= startMinute && minute < endMinute
        }
        let previousWeekday = weekday == 1 ? 7 : weekday - 1
        return (weekdays.contains(weekday) && minute >= startMinute)
            || (weekdays.contains(previousWeekday) && minute < endMinute)
    }
}
