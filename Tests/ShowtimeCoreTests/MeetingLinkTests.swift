import Foundation
import Testing
@testable import ShowtimeCore

@Suite struct MeetingLinkTests {
    func links(notes: String? = nil, location: String? = nil, url: String? = nil) -> [MeetingLink] {
        MeetingLinkDetector.links(in: event(location: location, notes: notes, url: url.flatMap(URL.init(string:))))
    }

    @Test func findsZoomInLocation() {
        let found = links(location: "https://acme.zoom.us/j/123456789?pwd=abc")
        #expect(found.count == 1)
        #expect(found.first?.serviceName == "Zoom")
        #expect(found.first?.appURL == URL(string: "zoommtg://acme.zoom.us/join?confno=123456789&pwd=abc"))
    }

    @Test func findsMeetInURLField() {
        #expect(links(url: "https://meet.google.com/abc-defg-hij").first?.serviceName == "Google Meet")
    }

    @Test func findsTeamsInNotes() {
        let found = links(notes: "Join here: https://teams.microsoft.com/l/meetup-join/19%3ameeting_X%40thread.v2/0?context=%7b%7d\nThanks")
        #expect(found.first?.serviceName == "Microsoft Teams")
        #expect(found.first?.appURL?.absoluteString.hasPrefix("msteams:/l/meetup-join/") == true)
    }

    @Test func unwrapsSafeLinks() {
        let wrapped = "https://nam12.safelinks.protection.outlook.com/?url=https%3A%2F%2Fteams.microsoft.com%2Fl%2Fmeetup-join%2Fabc&data=05"
        let found = links(notes: "Click \(wrapped) to join")
        #expect(found.map(\.url.absoluteString) == ["https://teams.microsoft.com/l/meetup-join/abc"])
    }

    @Test func findsLinkInsideAngleBrackets() {
        #expect(links(notes: "Join: <https://zoom.us/j/999>").map(\.url.absoluteString) == ["https://zoom.us/j/999"])
    }

    @Test func findsLinkInHTMLNotes() {
        #expect(links(notes: #"<a href="https://zoom.us/j/555">Join</a>"#).map(\.url.absoluteString) == ["https://zoom.us/j/555"])
    }

    @Test func deduplicatesAcrossFields() {
        #expect(links(notes: "https://zoom.us/j/777", location: "https://zoom.us/j/777").count == 1)
    }

    @Test func multipleServicesKeepOrder() {
        let found = links(notes: "https://zoom.us/j/1", url: "https://meet.google.com/abc-defg-hij")
        #expect(found.map(\.serviceName) == ["Google Meet", "Zoom"])
    }

    @Test func ignoresNonMeetingLinks() {
        #expect(links(notes: "Agenda: https://example.com/agenda").isEmpty)
    }

    @Test func stripsTrailingPunctuation() {
        #expect(links(notes: "(see https://zoom.us/j/123).").first?.url.absoluteString == "https://zoom.us/j/123")
    }

    @Test func recognizesOtherServices() {
        let cases = [
            "https://acme.webex.com/meet/jdoe": "Webex",
            "https://meet.jit.si/MyRoom": "Jitsi",
            "https://whereby.com/team-room": "Whereby",
            "https://global.gotomeeting.com/join/123456789": "GoToMeeting",
            "https://acme.zoomgov.com/j/1612345678": "Zoom",
            "https://teams.live.com/meet/9876543210": "Microsoft Teams",
            "https://chime.aws/1234567890": "Amazon Chime",
        ]
        for (link, name) in cases {
            #expect(links(notes: link).first?.serviceName == name, "\(link)")
        }
    }
}
