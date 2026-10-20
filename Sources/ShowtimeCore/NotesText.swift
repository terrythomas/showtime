import Foundation

public enum NotesText {
    /// Event notes as plain text. Exchange and Google often deliver HTML.
    public static func plain(_ notes: String) -> String {
        var s = notes
        let replacements: [(String, String)] = [
            (#"(?i)<br\s*/?>"#, "\n"), (#"(?i)</(p|div|li|tr|h[1-6])>"#, "\n"), (#"<[^>]+>"#, ""),
        ]
        for (pattern, template) in replacements {
            s = s.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
        }
        let entities = ["&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'"]
        for (entity, char) in entities { s = s.replacingOccurrences(of: entity, with: char) }
        s = s.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
