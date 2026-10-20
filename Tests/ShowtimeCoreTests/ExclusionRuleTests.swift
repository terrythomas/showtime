import Testing
@testable import ShowtimeCore

@Suite struct WildcardTests {
    @Test func prefixStarIgnoresCase() {
        #expect(wildcardMatches(pattern: "Lunch*", text: "lunch with Bob", caseSensitive: false))
        #expect(!wildcardMatches(pattern: "Lunch*", text: "lunch with Bob", caseSensitive: true))
    }
    @Test func starsBothSides() { #expect(wildcardMatches(pattern: "*1:1*", text: "Weekly 1:1 – Sam", caseSensitive: false)) }
    @Test func questionMarkIsOneChar() {
        #expect(wildcardMatches(pattern: "Stand?p", text: "Standup", caseSensitive: false))
        #expect(!wildcardMatches(pattern: "Stand?p", text: "Standuup", caseSensitive: false))
    }
    @Test func backtracking() { #expect(wildcardMatches(pattern: "a*b*c", text: "aXXbYYc", caseSensitive: true)) }
    @Test func starMatchesEmpty() { #expect(wildcardMatches(pattern: "*", text: "", caseSensitive: true)) }
    @Test func wholeStringOnly() { #expect(!wildcardMatches(pattern: "Lunch", text: "Lunch time", caseSensitive: false)) }
}

@Suite struct ExclusionRuleTests {
    func rule(_ field: ExclusionRule.Field = .title, _ cmp: ExclusionRule.Comparison, _ value: String, caseSensitive: Bool = false) -> ExclusionRule {
        ExclusionRule(field: field, comparison: cmp, value: value, caseSensitive: caseSensitive)
    }

    @Test func contains() { #expect(rule(.title, .contains, "focus").matches(event(title: "Focus time"))) }
    @Test func beginsWith() {
        #expect(rule(.title, .beginsWith, "OOO").matches(event(title: "OOO - Sam")))
        #expect(!rule(.title, .beginsWith, "OOO").matches(event(title: "Sam OOO")))
    }
    @Test func endsWith() {
        #expect(rule(.title, .endsWith, "(optional)").matches(event(title: "Town hall (Optional)")))
        #expect(!rule(.title, .endsWith, "town").matches(event(title: "Town hall")))
    }
    @Test func equalsIsExact() {
        #expect(rule(.title, .equals, "lunch").matches(event(title: "Lunch")))
        #expect(!rule(.title, .equals, "lunch", caseSensitive: true).matches(event(title: "Lunch")))
        #expect(!rule(.title, .equals, "lunch").matches(event(title: "Lunch break")))
    }
    @Test func matchesPattern() { #expect(rule(.title, .matches, "*standup*").matches(event(title: "Team Standup"))) }
    @Test func nilFieldDoesNotMatchContains() { #expect(!rule(.location, .contains, "x").matches(event(location: nil))) }
    @Test func notesField() { #expect(rule(.notes, .contains, "optional").matches(event(notes: "This is OPTIONAL"))) }
    @Test func emptyValueNeverMatches() {
        #expect(!rule(.title, .contains, "").matches(event(title: "Anything")))
        #expect(!rule(.title, .matches, "").matches(event(title: "")))
    }
}
