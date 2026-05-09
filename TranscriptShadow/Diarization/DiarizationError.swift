// @implements API-102, INT-102
import Foundation

/// Public error surface for `DiarizationService`. Exit-code-driven cases
/// match the EPIC-04a Phase A Decision 2 matrix; the rest cover Swift-side
/// concerns (binary location, cancellation, timeout, JSON decode).
///
/// Cancellation is its own case — never collapse it into `.binaryFailed`
/// (EPIC-03 P2 lesson). The pre-catch order in
/// `PyannoteSidecarDiarizationService` enforces this.
public enum DiarizationError: Error, Equatable, Sendable {
    /// Sidecar exit code 1 — audio file unreadable, missing, or the
    /// bookmark hand-off path is unsupported by the binary.
    case audioFileMissing(reason: String)

    /// Sidecar exit code 2 — pyannote could not load the requested model
    /// for a non-auth reason (corrupted cache, missing weights, etc.).
    case modelLoadFailed(reason: String)

    /// Sidecar exit code 3 — the gated community-1 model needs a HF token
    /// or terms acceptance and we do not have a cached copy.
    case huggingFaceAuthRequired

    /// Sidecar exit code 4 — pyannote ran out of memory mid-pipeline.
    case outOfMemory

    /// The bundled `diarize` binary was not found at the resolved URL.
    /// Almost always means the build failed to embed
    /// `sidecar/dist/diarize/` under `Resources/diarize/`.
    case binaryMissing(URL)

    /// Sidecar exited non-zero with a code we do not have a typed mapping
    /// for, or the stderr ERROR line was missing/malformed. `stderr`
    /// captures the raw stderr output for diagnostics.
    case binaryFailed(exitCode: Int32, stderr: String)

    /// `Task.cancel()` propagated to the subprocess via SIGTERM
    /// (EPIC-03 P2 — must NOT collapse into `.binaryFailed`).
    case cancelled

    /// The subprocess ran past `timeoutSeconds` without exiting and was
    /// killed.
    case timeout(seconds: TimeInterval)

    /// The sidecar wrote a JSON file that does not parse against the
    /// `DiarizationResult` Codable type. Almost always indicates a schema
    /// drift between `sidecar/diarize.py` and the Swift types — bump the
    /// schema version on both sides if intentional, fix the emitter
    /// otherwise.
    case decodeFailed(reason: String)
}

extension DiarizationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .audioFileMissing(let reason):
            return "Diarization audio file missing or unreadable: \(reason)"
        case .modelLoadFailed(let reason):
            return "Diarization model load failed: \(reason)"
        case .huggingFaceAuthRequired:
            return "Hugging Face authentication required for the gated community-1 model. Provide HF_TOKEN and accept terms once at huggingface.co/pyannote/speaker-diarization-community-1."
        case .outOfMemory:
            return "Diarization ran out of memory. Try a shorter recording or close other apps."
        case .binaryMissing(let url):
            return "Diarization binary not found at \(url.path). The app bundle may be corrupted."
        case .binaryFailed(let exitCode, let stderr):
            return "Diarization sidecar failed with exit code \(exitCode): \(stderr)"
        case .cancelled:
            return "Diarization was cancelled."
        case .timeout(let seconds):
            return "Diarization timed out after \(Int(seconds))s and was stopped."
        case .decodeFailed(let reason):
            return "Diarization output JSON could not be decoded: \(reason)"
        }
    }
}

internal extension DiarizationError {
    /// Map a sidecar exit code + captured stderr into a typed error. The
    /// `ERROR:<code>:<message>` line on stderr (regex `^ERROR:(\d+):(.+)$`)
    /// is the source of truth for the message.
    static func from(exitCode: Int32, stderr: String) -> DiarizationError {
        let trimmedStderr = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = parseErrorMessage(from: trimmedStderr) ?? trimmedStderr

        switch exitCode {
        case 1:
            return .audioFileMissing(reason: message)
        case 2:
            return .modelLoadFailed(reason: message)
        case 3:
            return .huggingFaceAuthRequired
        case 4:
            return .outOfMemory
        default:
            return .binaryFailed(exitCode: exitCode, stderr: trimmedStderr)
        }
    }

    /// Extract the `<message>` from an `ERROR:<code>:<message>` line, if
    /// present. Searches stderr top-down for the first matching line so
    /// banner / log lines before the typed error are skipped.
    static func parseErrorMessage(from stderr: String) -> String? {
        for raw in stderr.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("ERROR:") else { continue }
            let body = line.dropFirst("ERROR:".count)
            // body looks like "<code>:<message>" — strip the leading digits + colon
            guard let colonIdx = body.firstIndex(of: ":") else { continue }
            return String(body[body.index(after: colonIdx)...])
        }
        return nil
    }
}
