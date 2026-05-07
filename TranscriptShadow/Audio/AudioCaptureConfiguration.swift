// @implements API-001, BR-402
import Foundation

public struct AudioCaptureConfiguration: Sendable, Equatable {
    public var captureMicrophone: Bool
    public var captureSystemAudio: Bool
    public var maximumDuration: TimeInterval
    public var warningDuration: TimeInterval
    public var sampleRate: Double

    public init(
        captureMicrophone: Bool = true,
        captureSystemAudio: Bool = true,
        maximumDuration: TimeInterval = AudioCaptureConfiguration.defaultMaximumDuration,
        warningDuration: TimeInterval = AudioCaptureConfiguration.defaultWarningDuration,
        sampleRate: Double = 48_000
    ) {
        self.captureMicrophone = captureMicrophone
        self.captureSystemAudio = captureSystemAudio
        self.maximumDuration = maximumDuration
        self.warningDuration = warningDuration
        self.sampleRate = sampleRate
    }

    /// BR-402: Two-hour hard cap to bound memory + disk on local processing.
    public static let defaultMaximumDuration: TimeInterval = 120 * 60

    /// BR-402: One-hour-fifty warning, ten minutes before the hard cap.
    public static let defaultWarningDuration: TimeInterval = 110 * 60

    /// Output is always mono (channels = 1). Mono is the only format the
    /// downstream transcription pipeline accepts, so a public knob would be
    /// half-supported. Internal sources may capture multi-channel and downmix.
    public static let outputChannelCount: Int = 1

    public static let `default` = AudioCaptureConfiguration()
    public static let microphoneOnly = AudioCaptureConfiguration(
        captureMicrophone: true,
        captureSystemAudio: false
    )
}

public enum AudioCaptureMilestone: Sendable, Equatable {
    case durationWarningReached
    case durationLimitReached
    case systemAudioFellBackToMicOnly(reason: String)
    /// Fired after the WAV is finalized on disk. Carries the URL of the
    /// produced file so a UI subscribed to `milestones()` can react to both
    /// user-initiated stops and BR-402 auto-stops without polling
    /// `stopCapture()`'s synchronous return value.
    case recordingFinalized(url: URL, reason: AudioCaptureFinalizationReason)
}

public enum AudioCaptureFinalizationReason: Sendable, Equatable {
    case userRequested
    case durationLimitReached
}
