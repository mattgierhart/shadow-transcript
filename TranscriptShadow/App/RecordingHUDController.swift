// @implements SCR-002 (Recording HUD controller — picks DES-105 or DES-106)
// @see SoT/SoT.USER_JOURNEYS.md SCR-002
// @see design/visual-prototype/README.md :: JSX → SwiftUI map
//
// Decides whether to use the Notch HUD (DES-105) or the Menu Bar Extra
// (DES-106) realization. Per BR-501 + RISK-008, both are designed as peers;
// the controller only picks based on hardware capability.

import AppKit
import Combine
import SwiftUI

@MainActor
final class RecordingHUDController: ObservableObject {
    enum Realization { case notch, menuBar }

    /// True while a recording is conceptually active and the HUD is on screen.
    @Published private(set) var isRecording: Bool = false

    /// Which surface is currently in use. Decided at start().
    @Published private(set) var activeRealization: Realization?

    /// The owning main NSWindow — needed so the controller can hide/restore
    /// it as the user toggles recording. Set from a WindowAccessor on
    /// MainWindowView's .onAppear.
    weak var mainWindow: NSWindow?

    /// Called when the user clicks Stop on the HUD. The owner uses this to
    /// transition the main window's content to SCR-003 (Processing).
    var onStop: (() -> Void)?

    private let notchController = NotchHUDController()
    private let menuBarItem = MenuBarRecordingItem()

    /// Forced override for the Demo menu so the user can preview either
    /// realization regardless of hardware. nil = auto-detect.
    var forcedRealization: Realization?

    // MARK: - Start / Stop

    func startRecording() {
        guard !isRecording else { return }
        let realization = forcedRealization ?? (NotchHUDController.hasNotch ? .notch : .menuBar)
        activeRealization = realization
        isRecording = true

        // Hide main window (BR-501 — main window MUST be hidden during recording).
        mainWindow?.orderOut(nil)

        switch realization {
        case .notch:
            notchController.show { [weak self] in self?.handleStop() }
        case .menuBar:
            menuBarItem.show { [weak self] in self?.handleStop() }
        }
    }

    func stopRecording() {
        handleStop()
    }

    private func handleStop() {
        guard isRecording else { return }
        notchController.hide()
        menuBarItem.hide()
        isRecording = false

        // Restore main window into whatever content state the parent set.
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        onStop?()
        activeRealization = nil
    }
}
