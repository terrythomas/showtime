import Testing
@testable import ShowtimeCore

@Suite struct NotesTextTests {
    @Test func stripsTagsAndKeepsLineBreaks() {
        #expect(NotesText.plain("<p>Hello&nbsp;team</p>Agenda: <b>Q4</b> &amp; plans") == "Hello team\nAgenda: Q4 & plans")
    }
    @Test func plainTextUnchanged() {
        #expect(NotesText.plain("Line 1\nLine 2") == "Line 1\nLine 2")
    }
    @Test func collapsesBlankLines() {
        #expect(NotesText.plain("A\n\n\n\nB") == "A\n\nB")
    }
}
