// @implements API-202
// In-memory `ObsidianExporter` used for SwiftUI previews + view-model
// unit tests. Records call arguments and returns a fixed URL; never
// touches the filesystem.

import Foundation

public final class PreviewObsidianExporter: ObsidianExporter, @unchecked Sendable {
    public struct Call: Sendable {
        public let transcript: FormattedTranscript
        public let title: String
        public let date: Date
        public let vaultPath: URL
        public let subfolder: String?
    }

    private let lock = NSLock()
    public private(set) var calls: [Call] = []
    public var nextError: Error?
    /// What `export(...)` returns on success. Defaults to a stable
    /// deterministic path.
    public var nextReturnURL: URL = URL(fileURLWithPath: "/tmp/preview-export.md")

    public init() {}

    public func export(
        transcript: FormattedTranscript,
        title: String,
        date: Date,
        vaultPath: URL,
        subfolder: String?
    ) throws -> URL {
        if let nextError { throw nextError }
        lock.withLock {
            calls.append(Call(
                transcript: transcript,
                title: title,
                date: date,
                vaultPath: vaultPath,
                subfolder: subfolder
            ))
        }
        return nextReturnURL
    }
}
