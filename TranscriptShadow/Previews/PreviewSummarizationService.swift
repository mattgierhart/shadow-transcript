// @implements API-401
// In-memory `SummarizationService` for SwiftUI previews + view-model unit
// tests. Returns a canned `MeetingSummary` (or a configured one) without
// touching any model. Records whether it was called.

import Foundation

public final class PreviewSummarizationService: SummarizationService, @unchecked Sendable {
    private let lock = NSLock()
    public private(set) var callCount = 0
    public var nextError: Error?
    public var nextResult: MeetingSummary

    public init(nextResult: MeetingSummary = .preview) {
        self.nextResult = nextResult
    }

    public func summarize(transcript: FormattedTranscript) async throws -> MeetingSummary {
        lock.withLock { callCount += 1 }
        if let nextError { throw nextError }
        return nextResult
    }
}

public extension MeetingSummary {
    /// Canned summary for previews + tests.
    static let preview = MeetingSummary(
        overview: "The team reviewed Q3 planning and aligned on the launch timeline.",
        keyPoints: [
            "Engineering and design agreed on the v0.8 scope",
            "Diarization accuracy is the top validation risk"
        ],
        actionItems: [
            "Run the no-network privacy probe on a Mac",
            "Capture KPI-001 and KPI-002 baselines"
        ],
        generator: "Preview"
    )
}
