import Testing
@testable import ShowtimeCore

@Suite struct AlertOffsetsTests {
    @Test func acceptsNewOffset() { #expect(AlertOffsets.problem(adding: 5, to: [1]) == nil) }
    @Test func rejectsDuplicate() { #expect(AlertOffsets.problem(adding: 1, to: [1]) == "That alert time already exists.") }
    @Test func rejectsOutOfRange() {
        #expect(AlertOffsets.problem(adding: -1, to: []) == "Choose between 0 minutes and 24 hours before.")
        #expect(AlertOffsets.problem(adding: 1441, to: []) == "Choose between 0 minutes and 24 hours before.")
        #expect(AlertOffsets.problem(adding: 1440, to: []) == nil)
    }
    @Test func rejectsMoreThanTen() {
        #expect(AlertOffsets.problem(adding: 99, to: Array(0..<10)) == "You can have up to 10 alert times.")
    }
    @Test func cannotRemoveLast() {
        #expect(!AlertOffsets.canRemove(from: [1]))
        #expect(AlertOffsets.canRemove(from: [1, 5]))
    }
    @Test func sortedLargestFirst() { #expect(AlertOffsets.sorted([1, 30, 10]) == [30, 10, 1]) }
    @Test func describes() {
        #expect(AlertOffsets.describe(0) == "At start")
        #expect(AlertOffsets.describe(5) == "5 min before")
        #expect(AlertOffsets.describe(90) == "1 hr 30 min before")
        #expect(AlertOffsets.describe(120) == "2 hr before")
    }
}
