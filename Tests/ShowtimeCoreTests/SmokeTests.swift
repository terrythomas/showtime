import Testing
@testable import ShowtimeCore

@Test func versionIsSet() {
    #expect(!ShowtimeInfo.version.isEmpty)
}
