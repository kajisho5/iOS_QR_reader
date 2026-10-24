import Testing
@testable import SeijitsuQR

struct ReviewPromptPolicyTests {
    @Test func waitsUntilMoreThanTenScans() {
        #expect(!ReviewPromptPolicy.shouldRequest(successfulScans: 0, alreadyRequested: false))
        #expect(!ReviewPromptPolicy.shouldRequest(successfulScans: 10, alreadyRequested: false))
        #expect(ReviewPromptPolicy.shouldRequest(successfulScans: 11, alreadyRequested: false))
    }

    @Test func asksOnlyOnce() {
        #expect(!ReviewPromptPolicy.shouldRequest(successfulScans: 50, alreadyRequested: true))
    }
}
