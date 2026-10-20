import Foundation
import Testing
@testable import ShowtimeCore

@Suite struct TimeTextTests {
    let start = at(10)

    @Test func alertCountdown() {
        #expect(TimeText.alertCountdown(start: start, now: at(9, 55)) == "starts in 5 min")
        #expect(TimeText.alertCountdown(start: start, now: at(9, 55, 20)) == "starts in 5 min")  // 4:40 rounds up
        #expect(TimeText.alertCountdown(start: start, now: at(8, 55)) == "starts in 1 hr 5 min")
        #expect(TimeText.alertCountdown(start: start, now: at(8)) == "starts in 2 hr")
        #expect(TimeText.alertCountdown(start: start, now: at(9, 59, 45)) == "starting now")
        #expect(TimeText.alertCountdown(start: start, now: at(10, 0, 20)) == "starting now")
        #expect(TimeText.alertCountdown(start: start, now: at(10, 2)) == "started 2 min ago")
        #expect(TimeText.alertCountdown(start: start, now: at(9, 59)) == "starts in 1 min")
    }

    @Test func menuCountdown() {
        let end = at(10, 30)
        #expect(TimeText.menuCountdown(start: start, end: end, now: at(9, 48), style: .regular) == "in 12 min")
        #expect(TimeText.menuCountdown(start: start, end: end, now: at(9, 48), style: .compact) == "12m")
        #expect(TimeText.menuCountdown(start: start, end: end, now: at(10, 18), style: .regular) == "12 min left")
        #expect(TimeText.menuCountdown(start: start, end: end, now: at(10, 18), style: .compact) == "12m left")
        #expect(TimeText.menuCountdown(start: start, end: end, now: at(8, 30), style: .regular) == "in 1 hr 30 min")
        #expect(TimeText.menuCountdown(start: start, end: end, now: at(8, 30), style: .compact) == "1h30m")
        #expect(TimeText.menuCountdown(start: start, end: end, now: at(9, 48), style: .none) == nil)
    }

    @Test func truncate() {
        #expect(TimeText.truncate("Quarterly planning", to: 9) == "Quarterly…")
        #expect(TimeText.truncate("Standup", to: 9) == "Standup")
        #expect(TimeText.truncate("Café ☕️ chat", to: 6) == "Café ☕️…")
    }

    @Test func menuBarTitleNext() {
        let next = event(title: "Standup", start: at(10))
        #expect(TimeText.menuBarTitle(next: next, current: nil, now: at(9, 48), settings: ShowtimeSettings()) == "Standup · in 12 min")
    }

    @Test func menuBarTitlePrefersCurrent() {
        let current = event(title: "Design review", start: at(9, 30), minutes: 60)
        let next = event(title: "Standup", start: at(10, 45))
        #expect(TimeText.menuBarTitle(next: next, current: current, now: at(10), settings: ShowtimeSettings()) == "Design review · 30 min left")
        var s = ShowtimeSettings()
        s.menuShowCurrentEvent = false
        #expect(TimeText.menuBarTitle(next: next, current: current, now: at(10), settings: s) == "Standup · in 45 min")
    }

    @Test func menuBarTitleWindowAndDisabled() {
        let next = event(title: "Standup", start: at(15))
        var s = ShowtimeSettings()
        s.menuNextEventWindowHours = 4
        #expect(TimeText.menuBarTitle(next: next, current: nil, now: at(10), settings: s) == nil)
        #expect(TimeText.menuBarTitle(next: next, current: nil, now: at(11, 30), settings: s) != nil)
        s.menuShowNextTitle = false
        #expect(TimeText.menuBarTitle(next: next, current: nil, now: at(11, 30), settings: s) == nil)
    }

    @Test func menuBarTitleTruncatesAndHonorsNoneStyle() {
        let next = event(title: "Quarterly business review", start: at(10))
        var s = ShowtimeSettings()
        s.menuTitleLength = 9
        s.menuCountdown = .none
        #expect(TimeText.menuBarTitle(next: next, current: nil, now: at(9), settings: s) == "Quarterly…")
    }
}
