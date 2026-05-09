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
///
/// Cancellation: cancelling the awaiting task propagates to the enqueued
/// work via `withTaskCancellationHandler` so cooperative-cancellation
/// inside `work` (e.g. SIGTERM-on-cancel in `PyannoteSidecarDiarizationService`)
/// fires correctly. Without this propagation the unstructured `Task<T, Error>`
/// inside the queue would run to completion regardless of the caller's
/// cancellation state, defeating cancellation handlers in `work`.
/// (EPIC-04b 2026-05-09 — Codex Gate 2 prep finding.)
public final class AsyncTaskQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var tail: Task<Void, Never>?

    public init() {}

    public func enqueue<T: Sendable>(
        _ work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        // The capture of `predecessor` and the install of the new tail
        // MUST happen in a single critical section. If they straddle
        // the lock, two concurrent `enqueue` calls can capture the same
        // predecessor and run concurrently — defeating the queue
        // (Codex Gate 2 P0 finding, EPIC-04b 2026-05-09).
        let outcomeTask: Task<T, Error> = lock.withLock {
            let predecessor = tail
            let task = Task<T, Error> {
                await predecessor?.value
                // Codex Gate 2 P1: check cancellation before running so a
                // cancelled enqueue doesn't waste work.
                try Task.checkCancellation()
                return try await work()
            }
            tail = Task<Void, Never> {
                _ = try? await task.value
            }
            return task
        }

        return try await withTaskCancellationHandler {
            try await outcomeTask.value
        } onCancel: {
            outcomeTask.cancel()
        }
    }
}
