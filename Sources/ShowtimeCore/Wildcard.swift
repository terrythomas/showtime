import Foundation

/// Whole-string wildcard match: `*` matches any run of characters (including none),
/// `?` matches exactly one. No regex, so user text never needs escaping.
public func wildcardMatches(pattern: String, text: String, caseSensitive: Bool) -> Bool {
    let p = Array(caseSensitive ? pattern : pattern.lowercased())
    let t = Array(caseSensitive ? text : text.lowercased())
    var pi = 0, ti = 0
    var starPi = -1, starTi = 0
    while ti < t.count {
        if pi < p.count, p[pi] == "?" || p[pi] == t[ti] {
            pi += 1; ti += 1
        } else if pi < p.count, p[pi] == "*" {
            starPi = pi; starTi = ti; pi += 1
        } else if starPi >= 0 {
            pi = starPi + 1; starTi += 1; ti = starTi
        } else {
            return false
        }
    }
    while pi < p.count, p[pi] == "*" { pi += 1 }
    return pi == p.count
}
