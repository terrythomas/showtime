import Foundation

/// An event matching any exclusion rule gets no alert and isn't listed.
public struct ExclusionRule: Codable, Hashable, Sendable, Identifiable {
    public enum Field: String, Codable, CaseIterable, Sendable { case title, location, notes }
    public enum Comparison: String, Codable, CaseIterable, Sendable { case contains, beginsWith, endsWith, equals, matches }

    public var id: UUID
    public var field: Field
    public var comparison: Comparison
    public var value: String
    public var caseSensitive: Bool

    public init(id: UUID = UUID(), field: Field = .title, comparison: Comparison = .contains, value: String = "", caseSensitive: Bool = false) {
        self.id = id
        self.field = field
        self.comparison = comparison
        self.value = value
        self.caseSensitive = caseSensitive
    }

    public func matches(_ e: CalendarEvent) -> Bool {
        guard !value.isEmpty else { return false }
        let raw: String? = switch field {
        case .title: e.title
        case .location: e.location
        case .notes: e.notes
        }
        if comparison == .matches {
            return wildcardMatches(pattern: value, text: raw ?? "", caseSensitive: caseSensitive)
        }
        let text = caseSensitive ? (raw ?? "") : (raw ?? "").lowercased()
        let needle = caseSensitive ? value : value.lowercased()
        switch comparison {
        case .contains: return text.contains(needle)
        case .beginsWith: return text.hasPrefix(needle)
        case .endsWith: return text.hasSuffix(needle)
        case .equals: return text == needle
        case .matches: return false
        }
    }
}
