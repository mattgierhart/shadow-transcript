// @implements API-001
import Foundation

public enum AudioCaptureError: Error, Equatable, Sendable {
    case microphonePermissionDenied
    case screenRecordingPermissionDenied
    case captureAlreadyInProgress
    case noActiveCapture
    case noAudioCaptured
    case audioEngineFailedToStart(reason: String)
    case systemAudioCaptureFailedToStart(reason: String)
    case audioFileWriteFailed(reason: String)
    case durationLimitReached
    case unsupportedSystemConfiguration(reason: String)
}

extension AudioCaptureError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access was denied. Open System Settings → Privacy & Security → Microphone and grant access."
        case .screenRecordingPermissionDenied:
            return "Screen Recording access was denied. The app will continue with microphone-only capture."
        case .captureAlreadyInProgress:
            return "An audio capture is already in progress."
        case .noActiveCapture:
            return "There is no active audio capture to stop."
        case .noAudioCaptured:
            return "No audio data was captured during this session."
        case .audioEngineFailedToStart(let reason):
            return "The audio engine failed to start: \(reason)"
        case .systemAudioCaptureFailedToStart(let reason):
            return "System audio capture failed to start: \(reason)"
        case .audioFileWriteFailed(let reason):
            return "Failed to write audio file: \(reason)"
        case .durationLimitReached:
            return "The maximum recording duration was reached."
        case .unsupportedSystemConfiguration(let reason):
            return "Unsupported system configuration: \(reason)"
        }
    }
}
