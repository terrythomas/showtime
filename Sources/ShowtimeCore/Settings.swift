import Foundation

public enum ScreenMode: Codable, Hashable, Sendable {
    case active
    case all
    case named(String)
}

public enum CountdownStyle: String, Codable, CaseIterable, Sendable {
    case regular, compact, none
}

public enum HotkeyAction: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case showMenu, joinCall, togglePause
}

public struct KeyCombo: Codable, Hashable, Sendable {
    public var keyCode: UInt32
    public var modifiers: UInt32  // Carbon modifier mask

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

public struct ShowtimeSettings: Codable, Equatable, Sendable {
    public var alertOffsetsMinutes: [Int] = [1]
    public var snooze1Minutes = 1
    public var snooze2Minutes = 5
    public var autoCloseEnabled = false
    public var autoCloseMinutes = 15
    public var soundName: String? = "Glass"
    public var repeatSound = false
    public var soundVolume = 1.0
    public var screenMode: ScreenMode = .active
    public var shortcutDelaySeconds = 1.0
    public var activeCalendarIDs: Set<String>? = nil
    public var onlyAccepted = false
    public var onlyWithVideo = false
    public var includeAllDay = false
    public var allDayAlertMinuteOfDay = 540
    public var workHours = WorkHours()
    public var exclusionRules: [ExclusionRule] = []
    public var includeTravelTime = false
    public var menuShowNextTitle = true
    public var menuTitleLength = 20
    public var menuCountdown: CountdownStyle = .regular
    public var menuNextEventWindowHours: Int? = nil
    public var menuShowCurrentEvent = true
    public var upcomingDays = 7
    public var hotkeys: [HotkeyAction: KeyCombo] = [:]

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case alertOffsetsMinutes, snooze1Minutes, snooze2Minutes, autoCloseEnabled, autoCloseMinutes
        case soundName, repeatSound, soundVolume, screenMode, shortcutDelaySeconds, activeCalendarIDs
        case onlyAccepted, onlyWithVideo, includeAllDay, allDayAlertMinuteOfDay, workHours, exclusionRules
        case includeTravelTime, menuShowNextTitle, menuTitleLength, menuCountdown, menuNextEventWindowHours
        case menuShowCurrentEvent, upcomingDays, hotkeys
    }

    /// Every key is optional so settings written by older or newer versions still load.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ShowtimeSettings()
        func v<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decodeIfPresent(T.self, forKey: key)) ?? fallback
        }
        alertOffsetsMinutes = v(.alertOffsetsMinutes, d.alertOffsetsMinutes)
        snooze1Minutes = v(.snooze1Minutes, d.snooze1Minutes)
        snooze2Minutes = v(.snooze2Minutes, d.snooze2Minutes)
        autoCloseEnabled = v(.autoCloseEnabled, d.autoCloseEnabled)
        autoCloseMinutes = v(.autoCloseMinutes, d.autoCloseMinutes)
        // nil is a real choice (no sound), so distinguish "absent" from "null".
        soundName = c.contains(.soundName) ? (try? c.decode(String?.self, forKey: .soundName)) ?? nil : d.soundName
        repeatSound = v(.repeatSound, d.repeatSound)
        soundVolume = v(.soundVolume, d.soundVolume)
        screenMode = v(.screenMode, d.screenMode)
        shortcutDelaySeconds = v(.shortcutDelaySeconds, d.shortcutDelaySeconds)
        activeCalendarIDs = (try? c.decodeIfPresent(Set<String>.self, forKey: .activeCalendarIDs)) ?? nil
        onlyAccepted = v(.onlyAccepted, d.onlyAccepted)
        onlyWithVideo = v(.onlyWithVideo, d.onlyWithVideo)
        includeAllDay = v(.includeAllDay, d.includeAllDay)
        allDayAlertMinuteOfDay = v(.allDayAlertMinuteOfDay, d.allDayAlertMinuteOfDay)
        workHours = v(.workHours, d.workHours)
        exclusionRules = v(.exclusionRules, d.exclusionRules)
        includeTravelTime = v(.includeTravelTime, d.includeTravelTime)
        menuShowNextTitle = v(.menuShowNextTitle, d.menuShowNextTitle)
        menuTitleLength = v(.menuTitleLength, d.menuTitleLength)
        menuCountdown = v(.menuCountdown, d.menuCountdown)
        menuNextEventWindowHours = (try? c.decodeIfPresent(Int.self, forKey: .menuNextEventWindowHours)) ?? nil
        menuShowCurrentEvent = v(.menuShowCurrentEvent, d.menuShowCurrentEvent)
        upcomingDays = v(.upcomingDays, d.upcomingDays)
        hotkeys = v(.hotkeys, d.hotkeys)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(alertOffsetsMinutes, forKey: .alertOffsetsMinutes)
        try c.encode(snooze1Minutes, forKey: .snooze1Minutes)
        try c.encode(snooze2Minutes, forKey: .snooze2Minutes)
        try c.encode(autoCloseEnabled, forKey: .autoCloseEnabled)
        try c.encode(autoCloseMinutes, forKey: .autoCloseMinutes)
        try c.encode(soundName, forKey: .soundName)
        try c.encode(repeatSound, forKey: .repeatSound)
        try c.encode(soundVolume, forKey: .soundVolume)
        try c.encode(screenMode, forKey: .screenMode)
        try c.encode(shortcutDelaySeconds, forKey: .shortcutDelaySeconds)
        try c.encodeIfPresent(activeCalendarIDs, forKey: .activeCalendarIDs)
        try c.encode(onlyAccepted, forKey: .onlyAccepted)
        try c.encode(onlyWithVideo, forKey: .onlyWithVideo)
        try c.encode(includeAllDay, forKey: .includeAllDay)
        try c.encode(allDayAlertMinuteOfDay, forKey: .allDayAlertMinuteOfDay)
        try c.encode(workHours, forKey: .workHours)
        try c.encode(exclusionRules, forKey: .exclusionRules)
        try c.encode(includeTravelTime, forKey: .includeTravelTime)
        try c.encode(menuShowNextTitle, forKey: .menuShowNextTitle)
        try c.encode(menuTitleLength, forKey: .menuTitleLength)
        try c.encode(menuCountdown, forKey: .menuCountdown)
        try c.encodeIfPresent(menuNextEventWindowHours, forKey: .menuNextEventWindowHours)
        try c.encode(menuShowCurrentEvent, forKey: .menuShowCurrentEvent)
        try c.encode(upcomingDays, forKey: .upcomingDays)
        try c.encode(hotkeys, forKey: .hotkeys)
    }
}


