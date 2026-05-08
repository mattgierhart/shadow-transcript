// @implements API-101 (EPIC-03 Codex review regression)
import XCTest
@testable import TranscriptShadow

final class AsyncTaskQueueTests: XCTestCase {

    func test_enqueue_runsOperationsSerially_inOrder() async throws {
        let queue = AsyncTaskQueue()
        let recorder = OperationRecorder()

        let task1 = Task {
            try await queue.enqueue { @Sendable in
                recorder.record("a-start")
                try await Task.sleep(nanoseconds: 50_000_000)
                recorder.record("a-end")
                return "a"
            }
        }
        try await Task.sleep(nanoseconds: 5_000_000)
        let task2 = Task {
            try await queue.enqueue { @Sendable in
                recorder.record("b-start")
                try await Task.sleep(nanoseconds: 20_000_000)
                recorder.record("b-end")
                return "b"
            }
        }
        let task3 = Task {
            try await queue.enqueue { @Sendable in
                recorder.record("c-start")
                recorder.record("c-end")
                return "c"
            }
        }

        _ = try await task1.value
        _ = try await task2.value
        _ = try await task3.value

        // Tasks were enqueued from concurrent dispatch sites, so the
        // queue may serialize them in any order. The invariant we care
        // about is no interleaving: every "X-start" is immediately
        // followed by "X-end". Walk pairs and assert.
        let events = recorder.events
        XCTAssertEqual(events.count, 6)
        for i in stride(from: 0, to: events.count, by: 2) {
            let startId = events[i].split(separator: "-").first ?? ""
            let endId = events[i + 1].split(separator: "-").first ?? ""
            XCTAssertEqual(startId, endId,
                "Operations must not interleave; saw \(events)")
            XCTAssertTrue(events[i].hasSuffix("-start"))
            XCTAssertTrue(events[i + 1].hasSuffix("-end"))
        }
    }

    func test_enqueue_propagatesError_andContinuesQueue() async throws {
        struct ExampleError: Error, Equatable {}
        let queue = AsyncTaskQueue()

        let failing = Task<Int, Error> {
            try await queue.enqueue { @Sendable in
                throw ExampleError()
            }
        }
        do {
            _ = try await failing.value
            XCTFail("expected error to propagate")
        } catch {
            XCTAssertTrue(error is ExampleError)
        }

        let next = try await queue.enqueue { 42 }
        XCTAssertEqual(next, 42)
    }
}

private final class OperationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _events: [String] = []
    func record(_ event: String) { lock.withLock { _events.append(event) } }
    var events: [String] { lock.withLock { _events } }
}
