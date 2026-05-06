import Foundation
@testable import TranscriptShadow

/// Manually-advanced clock used to drive the duration guard deterministically
/// in tests. `now()` returns the current virtual time; `sleep(until:)` parks
/// the caller in a continuation list and only wakes once `advance(to:)` (or
/// `advance(by:)`) crosses that deadline.
final class FakeAudioCaptureClock: AudioCaptureClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    private var pending: [(deadline: Date, continuation: CheckedContinuation<Void, Error>)] = []

    init(start: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.current = start
    }

    func now() -> Date {
        lock.withLock { current }
    }

    func sleep(until deadline: Date) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let resumeImmediately: Bool = lock.withLock {
                if current >= deadline { return true }
                pending.append((deadline, continuation))
                return false
            }
            if resumeImmediately {
                continuation.resume()
            }
        }
    }

    func advance(by interval: TimeInterval) {
        advance(to: now().addingTimeInterval(interval))
    }

    func advance(to date: Date) {
        let due: [(deadline: Date, continuation: CheckedContinuation<Void, Error>)] = lock.withLock {
            current = date
            let firing = pending.filter { $0.deadline <= date }
            pending.removeAll { $0.deadline <= date }
            return firing
        }
        for entry in due {
            entry.continuation.resume()
        }
    }

    func cancelPending() {
        let snapshot: [(deadline: Date, continuation: CheckedContinuation<Void, Error>)] = lock.withLock {
            let s = pending
            pending.removeAll()
            return s
        }
        for entry in snapshot {
            entry.continuation.resume(throwing: CancellationError())
        }
    }
}
