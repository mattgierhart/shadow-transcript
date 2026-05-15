// @implements API-001, RISK-006
import Foundation

/// Locations on disk used by the capture service.
///
/// Per BR-103, audio is **transient** — captured WAVs stage here only long
/// enough for transcription + diarization to consume them, then get deleted.
/// This module only owns directory creation and unique URL generation; the
/// scan-and-cleanup of orphans (after a crash, after a successful pipeline
/// run, after user cancel) is `TempAudioCleanup` (API-301), implemented in
/// EPIC-08 against this same directory contract.
public enum AudioCaptureLocations {

    /// `~/Library/Application Support/TranscriptShadow/Recordings/`
    ///
    /// Backed by `Application Support` (not `NSTemporaryDirectory`) so that a
    /// crash mid-capture leaves the partially-written WAV in a predictable
    /// place for EPIC-08 to recover or remove on next launch (RISK-006).
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

    /// Returns a fresh URL for a new recording. The filename embeds an
    /// ISO-8601 timestamp with millisecond precision plus a short UUID
    /// suffix so two captures started in the same second cannot collide
    /// (`recording-2026-05-07T17-42-00.123Z-8C5F.wav`). `AudioFileWriter`
    /// also refuses to overwrite an existing file as a defense-in-depth.
    public static func newRecordingURL(date: Date = .now, fileManager: FileManager = .default) throws -> URL {
        let directory = try recordingsDirectory(fileManager: fileManager)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let stamp = formatter
            .string(from: date)
            .replacingOccurrences(of: ":", with: "-")
        // 8 hex chars (32 bits) keeps collision risk negligible even at
        // hundreds of same-millisecond calls. The 4-char form (16 bits) hit
        // the birthday-paradox edge in stress tests.
        let suffix = String(UUID().uuidString.prefix(8))
        return directory.appendingPathComponent("recording-\(stamp)-\(suffix).wav", isDirectory: false)
    }
}
