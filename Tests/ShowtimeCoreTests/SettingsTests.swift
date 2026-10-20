import Foundation
import Testing
@testable import ShowtimeCore

@Suite struct SettingsTests {
    @Test func decodingEmptyObjectGivesDefaults() throws {
        let s = try JSONDecoder().decode(ShowtimeSettings.self, from: Data("{}".utf8))
        #expect(s == ShowtimeSettings())
        #expect(s.alertOffsetsMinutes == [1])
        #expect(s.snooze1Minutes == 1)
        #expect(s.snooze2Minutes == 5)
        #expect(s.autoCloseMinutes == 15)
        #expect(s.soundName == "Glass")
        #expect(s.screenMode == .active)
        #expect(s.activeCalendarIDs == nil)
        #expect(s.allDayAlertMinuteOfDay == 540)
        #expect(s.workHours.enabled == false)
        #expect(s.menuCountdown == .regular)
        #expect(s.upcomingDays == 7)
    }

    @Test func unknownKeysAndMissingKeysTolerated() throws {
        let json = #"{"snooze1Minutes":3,"futureKey":true}"#
        let s = try JSONDecoder().decode(ShowtimeSettings.self, from: Data(json.utf8))
        var expected = ShowtimeSettings()
        expected.snooze1Minutes = 3
        #expect(s == expected)
    }

    @Test func roundTrip() throws {
        var s = ShowtimeSettings()
        s.alertOffsetsMinutes = [10, 1]
        s.snooze1Minutes = 2
        s.snooze2Minutes = 10
        s.autoCloseEnabled = true
        s.autoCloseMinutes = 3
        s.soundName = nil
        s.repeatSound = true
        s.soundVolume = 0.5
        s.screenMode = .named("DELL U2720Q")
        s.shortcutDelaySeconds = 2
        s.activeCalendarIDs = ["a", "b"]
        s.onlyAccepted = true
        s.onlyWithVideo = true
        s.includeAllDay = true
        s.allDayAlertMinuteOfDay = 600
        s.workHours.enabled = true
        s.exclusionRules = []
        s.includeTravelTime = true
        s.menuShowNextTitle = false
        s.menuTitleLength = 30
        s.menuCountdown = .compact
        s.menuNextEventWindowHours = 4
        s.menuShowCurrentEvent = false
        s.upcomingDays = 3
        s.hotkeys = [.joinCall: KeyCombo(keyCode: 38, modifiers: 6144)]
        let data = try JSONEncoder().encode(s)
        #expect(try JSONDecoder().decode(ShowtimeSettings.self, from: data) == s)
    }
}

@Suite struct JSONFileStoreTests {
    func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("nested/state.json")
    }

    @Test func fileStoreReturnsDefaultWhenMissing() {
        let store = JSONFileStore(url: tempURL(), default: [1, 2])
        #expect(store.load() == [1, 2])
    }

    @Test func fileStoreRoundTrips() throws {
        let url = tempURL()
        let store = JSONFileStore(url: url, default: [Int]())
        try store.save([7, 8])
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(JSONFileStore(url: url, default: [Int]()).load() == [7, 8])
    }

    @Test func fileStoreReturnsDefaultWhenCorrupt() throws {
        let url = tempURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("garbage".utf8).write(to: url)
        #expect(JSONFileStore<[Int]>(url: url, default: [9]).load() == [9])
    }
}

@Test func authorizationBannerState() {
    #expect(accessBanner(for: .notDetermined) == .requestAccess)
    #expect(accessBanner(for: .denied) == .openSystemSettings)
    #expect(accessBanner(for: .writeOnly) == .openSystemSettings)
    #expect(accessBanner(for: .restricted) == .restricted)
    #expect(accessBanner(for: .fullAccess) == .none)
}
