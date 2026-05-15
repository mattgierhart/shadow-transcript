// @implements API-101, INT-101
import Foundation

/// Owns the on-disk location for downloaded Whisper models.
///
/// Models live under
/// `~/Library/Application Support/TranscriptShadow/Models/` so they survive
/// app launches and don't compete with the transient `Recordings/` directory.
/// WhisperKit handles the actual download/cache when initialized with this
/// path.
public struct TranscriptionModelStore: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public static func makeDefault(fileManager: FileManager = .default) throws -> TranscriptionModelStore {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = appSupport
            .appendingPathComponent("TranscriptShadow", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return TranscriptionModelStore(directory: directory)
    }

    /// Path WhisperKit will check for an already-downloaded model variant
    /// before pulling from Hugging Face. WhisperKit canonicalizes the model
    /// directory as `<root>/<model.rawValue>/`.
    public func directoryURL(for model: WhisperModel) -> URL {
        directory.appendingPathComponent(model.rawValue, isDirectory: true)
    }

    /// Best-effort check used by the cache test. WhisperKit's actual
    /// "is model present" check is internal — we treat the directory as
    /// "downloaded" if it exists and is non-empty.
    public func isCached(model: WhisperModel, fileManager: FileManager = .default) -> Bool {
        let url = directoryURL(for: model)
        guard let contents = try? fileManager.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return !contents.isEmpty
    }
}
