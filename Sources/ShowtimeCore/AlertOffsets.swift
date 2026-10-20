import Foundation

/// Rules for alert times ("minutes before start"), shared by Settings and per-event customization.
public enum AlertOffsets {
    public static let maxCount = 10
    public static let range = 0...1440

    /// A message explaining why `minutes` can't be added, or nil if it can.
    public static func problem(adding minutes: Int, to offsets: [Int]) -> String? {
        if !range.contains(minutes) { return "Choose between 0 minutes and 24 hours before." }
        if offsets.contains(minutes) { return "That alert time already exists." }
        if offsets.count >= maxCount { return "You can have up to \(maxCount) alert times." }
        return nil
    }

    public static func canRemove(from offsets: [Int]) -> Bool { offsets.count > 1 }

    public static func sorted(_ offsets: [Int]) -> [Int] { offsets.sorted(by: >) }

    public static func describe(_ minutes: Int) -> String {
        if minutes == 0 { return "At start" }
        let h = minutes / 60, m = minutes % 60
        let text = h == 0 ? "\(m) min" : (m == 0 ? "\(h) hr" : "\(h) hr \(m) min")
        return "\(text) before"
    }
}
