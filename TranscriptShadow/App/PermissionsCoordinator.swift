// @implements RISK-002, RISK-004, BR-101
// Wraps mic + Screen Recording permission status checks + request flows.
// Mic permissions can be requested at runtime; Screen Recording can't —
// the user must grant in System Settings, so we surface a deep link.

import AVFoundation
import CoreGraphics
import Foundation

@MainActor
public struct PermissionsCoordinator {
    public enum Status: Equatable {
        case granted
        case denied
        case notDetermined
        /// `Not requested` distinct from `.notDetermined` so callers can
        /// differentiate "system says we haven't asked" vs "we haven't
        /// surfaced the prompt yet in our flow." Treated the same as
        /// `.notDetermined` everywhere it matters.
        case unavailable  // restricted by parental controls or MDM
    }

    public init() {}

    // MARK: - Microphone

    public var microphoneStatus: Status {
        Self.mapAV(AVCaptureDevice.authorizationStatus(for: .audio))
    }

    /// Requests microphone access. Returns the status AFTER the user
    /// responds (so callers can act on the new state without re-reading).
    public func requestMicrophone() async -> Status {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        return granted ? .granted : .denied
    }

    // MARK: - Screen Recording (ScreenCaptureKit / system audio)

    public var screenRecordingStatus: Status {
        // CGPreflight is the supported way to check ScreenCaptureKit
        // permission without prompting. Returns true once granted +
        // after the user restarts the app per macOS's gate.
        CGPreflightScreenCaptureAccess() ? .granted : .denied
    }

    /// macOS does NOT provide a programmatic grant. Calling this opens
    /// System Settings to the Screen Recording pane (and adds the app
    /// to the list if it's missing). The user must toggle it on AND
    /// restart the app for the change to take effect.
    @discardableResult
    public func requestScreenRecording() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    // MARK: - Helpers

    private static func mapAV(_ status: AVAuthorizationStatus) -> Status {
        switch status {
        case .authorized: return .granted
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .unavailable
        @unknown default: return .denied
        }
    }
}
