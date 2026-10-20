import Foundation

public struct MeetingService: Sendable {
    public let name: String
    /// Case-insensitive regex matched against the start of a candidate URL.
    public let pattern: String
}

public struct MeetingLink: Hashable, Sendable {
    public let serviceName: String
    public let url: URL
    /// A URL that opens the service's native app directly, when known.
    public var appURL: URL?
}

public enum MeetingLinkDetector {
    public static let services: [MeetingService] = [
        MeetingService(name: "Zoom", pattern: #"^https?://([a-z0-9-]+\.)*zoom(gov)?\.(us|com)/(j|my|w|s|wc/join)/"#),
        MeetingService(name: "Google Meet", pattern: #"^https?://meet\.google\.com/([a-z]{3,}-[a-z]{4,}-[a-z]{3,}|lookup/|_meet/)"#),
        MeetingService(name: "Microsoft Teams", pattern: #"^https?://([a-z]+\.)?teams\.(microsoft\.(com|us)|live\.com)/(l/meetup-join|meet)/"#),
        MeetingService(name: "Webex", pattern: #"^https?://([a-z0-9-]+\.)*webex(gov)?\.com/(meet/|join/|[^\s]*j\.php)"#),
        MeetingService(name: "GoToMeeting", pattern: #"^https?://([a-z0-9-]+\.)*(gotomeeting\.com|gotomeet\.me|meet\.goto\.com)/"#),
        MeetingService(name: "Jitsi", pattern: #"^https?://meet\.jit\.si/."#),
        MeetingService(name: "Whereby", pattern: #"^https?://(www\.)?whereby\.com/."#),
        MeetingService(name: "BlueJeans", pattern: #"^https?://([a-z0-9-]+\.)*bluejeans\.com/\d+"#),
        MeetingService(name: "Amazon Chime", pattern: #"^https?://(app\.)?chime\.aws/\d+"#),
        MeetingService(name: "Slack Huddle", pattern: #"^https?://app\.slack\.com/huddle/"#),
        MeetingService(name: "Around", pattern: #"^https?://(meet\.)?around\.co/r/"#),
        MeetingService(name: "Gather", pattern: #"^https?://app\.gather\.town/(app|invite)"#),
        MeetingService(name: "Dialpad", pattern: #"^https?://meetings\.dialpad\.com/"#),
        MeetingService(name: "Vonage", pattern: #"^https?://meetings\.vonage\.com/"#),
        MeetingService(name: "Zoho Meeting", pattern: #"^https?://(meeting|cliq)\.zoho\.[a-z.]+/meetings?/"#),
        MeetingService(name: "LiveKit", pattern: #"^https?://meet[a-z0-9.-]*\.livekit\.io/rooms/"#),
        MeetingService(name: "Proton Meet", pattern: #"^https?://meet\.proton\.me/"#),
        MeetingService(name: "Lifesize", pattern: #"^https?://call\.lifesizecloud\.com/"#),
        MeetingService(name: "RingCentral", pattern: #"^https?://(meetings|v)\.ringcentral\.com/"#),
        MeetingService(name: "Skype", pattern: #"^https?://join\.skype\.com/"#),
    ]

    private static let compiled: [(MeetingService, NSRegularExpression)] = services.map {
        ($0, try! NSRegularExpression(pattern: $0.pattern, options: .caseInsensitive))
    }
    private static let urlPattern = try! NSRegularExpression(pattern: #"https?://[^\s<>"']+"#, options: .caseInsensitive)
    private static let trailingJunk = CharacterSet(charactersIn: ".,;:!?)]}>'\"")

    /// Meeting links in the event's URL, location and notes, in that order, without duplicates.
    public static func links(in e: CalendarEvent) -> [MeetingLink] {
        var result: [MeetingLink] = []
        var seen = Set<String>()
        for text in [e.url?.absoluteString, e.location, e.notes].compactMap({ $0 }) {
            for candidate in candidates(in: text) {
                guard let link = classify(candidate) else { continue }
                let key = link.url.absoluteString.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if seen.insert(key).inserted { result.append(link) }
            }
        }
        return result
    }

    static func candidates(in text: String) -> [String] {
        let text = text.replacingOccurrences(of: "&amp;", with: "&")
        let range = NSRange(text.startIndex..., in: text)
        return urlPattern.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]).trimmingCharacters(in: trailingJunk) }
        }
    }

    static func classify(_ candidate: String) -> MeetingLink? {
        let unwrapped = unwrapRedirect(candidate)
        let range = NSRange(unwrapped.startIndex..., in: unwrapped)
        guard let url = URL(string: unwrapped),
              let service = compiled.first(where: { $0.1.firstMatch(in: unwrapped, range: range) != nil })?.0
        else { return nil }
        return MeetingLink(serviceName: service.name, url: url, appURL: appURL(for: service.name, url: url))
    }

    /// Outlook SafeLinks and Google redirect wrappers hide the real link in a query item.
    static func unwrapRedirect(_ candidate: String) -> String {
        guard let comps = URLComponents(string: candidate), let host = comps.host?.lowercased() else { return candidate }
        let item: String? = if host.hasSuffix("safelinks.protection.outlook.com") {
            "url"
        } else if host.hasSuffix("google.com"), comps.path == "/url" {
            "q"
        } else {
            nil
        }
        guard let item, let inner = comps.queryItems?.first(where: { $0.name == item })?.value else { return candidate }
        return inner
    }

    static func appURL(for service: String, url: URL) -> URL? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false), let host = comps.host else { return nil }
        switch service {
        case "Zoom":
            let parts = comps.path.split(separator: "/")
            guard parts.count >= 2, parts[0] == "j" else { return nil }
            var query = "confno=\(parts[1])"
            if let pwd = comps.queryItems?.first(where: { $0.name == "pwd" })?.value {
                query += "&pwd=\(pwd)"
            }
            return URL(string: "zoommtg://\(host)/join?\(query)")
        case "Microsoft Teams":
            let query = comps.percentEncodedQuery.map { "?\($0)" } ?? ""
            return URL(string: "msteams:\(comps.percentEncodedPath)\(query)")
        default:
            return nil
        }
    }
}
