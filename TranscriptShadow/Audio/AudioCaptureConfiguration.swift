// @implements API-001, BR-402
import Foundation

public struct AudioCaptureConfiguration: Sendable, Equatable {
    public var captureMicrophone: Bool
    public var captureSystemAudio: Bool
    public var maximumDuration: TimeInterval
    public var warningDuration: TimeInterval
    public var sampleRate: Double
    public var channelCount: Int

    public init(
        captureMicrophone: Bool = true,
        captureSystemAudio: Bool = true,
        maximumDuration: TimeInterval = AudioCaptureConfiguration.defaultMaximumDuration,
        warningDuration: TimeInterval = AudioCaptureConfiguration.defaultWarningDuration,
        sampleRate: Double = 48_000,
        channelCount: Int = 1
    ) {
        self.captureMicrophone = captureMicrophone
        self.captureSystemAudio = captureSystemAudio
        self.maximumDuration = maximumDuration
        self.warningDuration = warningDuration
        self.sampleRate = sampleRate
        self.channelCount = channelCount
    }

    /// BR-402: Two-hour hard cap to bound memory + disk on local processing.
    public static let defaultMaximumDuration: TimeInterval = 120 * 60

    /// BR-402: One-hour-fifty warning, ten minutes before the hard cap.
    public static let defaultWarningDuration: TimeInterval = 110 * 60

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
}
