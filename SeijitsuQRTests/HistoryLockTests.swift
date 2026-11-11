import Testing
@testable import SeijitsuQR

/// The history lock opens only on a successful check and closes again on `lock()` (docs/DESIGN_1.1.md §3.5).
@MainActor
struct HistoryLockTests {
    @Test func startsLocked() {
        #expect(!HistoryLock(authenticate: { _ in .unlocked }).isUnlocked)
    }

    @Test func successfulCheckUnlocksAndBackgroundLocksAgain() async {
        let lock = HistoryLock(authenticate: { _ in .unlocked })
        #expect(await lock.unlock() == .unlocked)
        #expect(lock.isUnlocked)
        lock.lock()
        #expect(!lock.isUnlocked)
    }

    @Test(arguments: [HistoryLock.Outcome.cancelled, .unavailable])
    func failedCheckStaysLocked(_ outcome: HistoryLock.Outcome) async {
        let lock = HistoryLock(authenticate: { _ in outcome })
        #expect(await lock.unlock() == outcome)
        #expect(!lock.isUnlocked)
    }

    @Test func asksWithAReason() async {
        var reason = ""
        let lock = HistoryLock(authenticate: { text in
            reason = text
            return .cancelled
        })
        await lock.unlock()
        #expect(!reason.isEmpty)
    }
}
