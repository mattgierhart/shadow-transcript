// @implements API-101
import Foundation

/// Serializes async operations so only one runs at a time. Used by
/// `WhisperKitEngine` to keep concurrent `load` / `transcribe` calls from
/// driving the same non-Sendable `WhisperKit` instance simultaneously
/// (Codex P2 review finding 2026-05-08).
///
/// Each `enqueue` creates a new task that first awaits the previous queue
/// tail before running. The tail is then advanced so that the next enqueue
/// chains behind this one.
public final class AsyncTaskQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var tail: Task<Void, Never>?

    public init() {}

    public func enqueue<T: Sendable>(
        _ work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let predecessor = lock.withLock { tail }

        let outcomeTask = Task<T, Error> {
            await predecessor?.value
            return try await work()
        }

        // The tail must continue regardless of this task's success/failure.
        let voidTail = Task<Void, Never> {
            _ = try? await outcomeTask.value
        }
        lock.withLock { tail = voidTail }

        return try await outcomeTask.value
    }
}
