import Testing
@testable import ShowtimeCore

@Suite struct JoinTargetTests {
    let zoom = "https://zoom.us/j/1"

    @Test func prefersOngoingWithLink() {
        let ongoing = event(id: "a", title: "Ongoing", start: at(9, 30), minutes: 60, location: zoom)
        let soon = event(id: "b", title: "Soon", start: at(10, 5), location: zoom)
        #expect(JoinTarget.pick(from: [ongoing, soon], now: at(10))?.title == "Ongoing")
    }

    @Test func fallsBackToNextWithin15Minutes() {
        let noLink = event(id: "a", title: "No link", start: at(9, 30), minutes: 60)
        let soon = event(id: "b", title: "Soon", start: at(10, 15), location: zoom)
        #expect(JoinTarget.pick(from: [noLink, soon], now: at(10))?.title == "Soon")
    }

    @Test func nothingWhenNextIsLater() {
        let later = event(title: "Later", start: at(10, 16), location: zoom)
        #expect(JoinTarget.pick(from: [later], now: at(10)) == nil)
    }

    @Test func latestStartedOngoingWins() {
        let long = event(id: "a", title: "All-hands", start: at(9), minutes: 120, location: zoom)
        let recent = event(id: "b", title: "1:1", start: at(9, 55), minutes: 30, location: zoom)
        #expect(JoinTarget.pick(from: [long, recent], now: at(10))?.title == "1:1")
    }
}
