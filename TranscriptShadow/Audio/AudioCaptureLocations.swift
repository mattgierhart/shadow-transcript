// @implements API-001, RISK-006
import Foundation

/// Locations on disk used by the capture service. Centralizing them keeps the
/// crash-recovery story in one place: orphaned WAVs left in the recordings
/// directory after a crash are scanned and either resumed or deleted on the
/// next launch.
public enum AudioCaptureLocations {

    /// `~/Library/Application Support/TranscriptShadow/Recordings/`
    public static func recordingsDirectory(fileManager: FileManager = .default) throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = appSupport
            .appendingPathComponent("TranscriptShadow", isDirectory: true)
            .appendingPathComponent("Recordings", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// File name in the form `recording-2026-05-06T17-42-00Z.wav`.
    public static func newRecordingURL(date: Date = .now, fileManager: FileManager = .default) throws -> URL {
        let directory = try recordingsDirectory(fileManager: fileManager)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let stamp = formatter
            .string(from: date)
            .replacingOccurrences(of: ":", with: "-")
        return directory.appendingPathComponent("recording-\(stamp).wav", isDirectory: false)
    }
}
