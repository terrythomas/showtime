import Foundation

public enum ShowtimeInfo {
    public static let version = "0.1.0"
}

/// The current user's relationship to an event.
public enum Participation: String, Codable, Sendable {
    case notInvited, organizer, accepted, declined, tentative, pending
}

public struct Attendee: Hashable, Codable, Sendable {
    public var name: String
    public var email: String?
    public var status: Participation
    public var isOrganizer: Bool

    public init(name: String, email: String? = nil, status: Participation, isOrganizer: Bool = false) {
        self.name = name
        self.email = email
        self.status = status
        self.isOrganizer = isOrganizer
    }
}

/// Identifies one occurrence of a (possibly recurring) event. Every occurrence of a
/// recurring event shares `eventID`, so the start date is part of the key.
public struct OccurrenceKey: Hashable, Codable, Sendable {
    public var eventID: String
    public var start: Date

    public init(eventID: String, start: Date) {
        self.eventID = eventID
        self.start = start
    }
}

public struct CalendarEvent: Hashable, Sendable, Identifiable {
    public var eventID: String
    public var seriesID: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var title: String
    public var location: String?
    public var notes: String?
    public var url: URL?
    public var calendarID: String
    public var calendarTitle: String
    public var calendarColorHex: String
    public var myStatus: Participation
    public var attendees: [Attendee]
    public var travelTime: TimeInterval?

    public init(
        eventID: String, seriesID: String? = nil, start: Date, end: Date, isAllDay: Bool = false,
        title: String, location: String? = nil, notes: String? = nil, url: URL? = nil,
        calendarID: String = "cal", calendarTitle: String = "Calendar", calendarColorHex: String = "#3478F6",
        myStatus: Participation = .notInvited, attendees: [Attendee] = [], travelTime: TimeInterval? = nil
    ) {
        self.eventID = eventID
        self.seriesID = seriesID ?? eventID
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.title = title
        self.location = location
        self.notes = notes
        self.url = url
        self.calendarID = calendarID
        self.calendarTitle = calendarTitle
        self.calendarColorHex = calendarColorHex
        self.myStatus = myStatus
        self.attendees = attendees
        self.travelTime = travelTime
    }

    public var key: OccurrenceKey { OccurrenceKey(eventID: eventID, start: start) }
    public var id: OccurrenceKey { key }
}
