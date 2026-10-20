import Foundation

public enum OverrideScope: Hashable, Codable, Sendable {
    case occurrence(OccurrenceKey)
    case series(String)
}

public struct EventOverride: Codable, Equatable, Sendable {
    public var hidden = false
    /// Replaces the global alert times when set.
    public var alertOffsetsMinutes: [Int]? = nil
    public var preferredLinkURL: String? = nil

    public init() {}
}

/// Per-event choices, stored for one occurrence or a whole recurring series.
public struct OverrideBook: Codable, Equatable, Sendable {
    public var entries: [OverrideScope: EventOverride] = [:]

    public init() {}

    /// Hidden if either scope hides it; otherwise the occurrence's value wins over the series'.
    public func resolved(for e: CalendarEvent) -> EventOverride {
        let occurrence = entries[.occurrence(e.key)]
        let series = entries[.series(e.seriesID)]
        var result = EventOverride()
        result.hidden = (occurrence?.hidden ?? false) || (series?.hidden ?? false)
        result.alertOffsetsMinutes = occurrence?.alertOffsetsMinutes ?? series?.alertOffsetsMinutes
        result.preferredLinkURL = occurrence?.preferredLinkURL ?? series?.preferredLinkURL
        return result
    }

    public mutating func update(_ scope: OverrideScope, _ change: (inout EventOverride) -> Void) {
        var value = entries[scope] ?? EventOverride()
        change(&value)
        entries[scope] = value == EventOverride() ? nil : value
    }

    public var hiddenScopes: [OverrideScope] {
        entries.filter { $0.value.hidden }.map(\.key)
    }
}
