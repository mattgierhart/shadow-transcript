// @implements DES-105 (Recording HUD — Notch)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-105
// @see design/visual-prototype/project/src/scr002.jsx :: NotchMenuBar
//
// Borderless NSPanel anchored to the top-center of the main screen at
// .statusBarWindow + 1, sitting in the notch geometry on notch-equipped
// MacBook Pros. Non-activating + can-be-visible-on-all-spaces so the
// user's meeting app keeps focus. RISK-008 fullscreen-occlusion probe
// is deferred to the EPIC-07 Phase D Codex Gate.

import AppKit
import SwiftUI

final class NotchHUDPanel: NSPanel {
    init(content: NSView) {
        let initialRect = NSRect(x: 0, y: 0, width: 320, height: 38)
        super.init(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false  // we draw our own shadow inside the SwiftUI content
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.contentView = content
        self.ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Re-anchor to the top center of the main screen.
    func anchorToTopCenter() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.frame
        let width: CGFloat = 320
        let height: CGFloat = 38
        let x = frame.midX - width / 2
        // NSWindow uses bottom-left origin. `frame.maxY` is the screen top.
        // Sit the panel flush with the menu bar / notch top.
        let y = frame.maxY - height
        setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}

/// Owns the NSPanel + its SwiftUI host. Showing/hiding is idempotent.
@MainActor
final class NotchHUDController {
    private var panel: NotchHUDPanel?

    func show(onStop: @escaping () -> Void) {
        if panel == nil {
            let hosting = NSHostingView(
                rootView: RecordingHUDContent(layout: .compact, onStop: onStop)
            )
            hosting.frame = NSRect(x: 0, y: 0, width: 320, height: 38)
            let p = NotchHUDPanel(content: hosting)
            p.anchorToTopCenter()
            panel = p
        }
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    static var hasNotch: Bool {
        // Notch-equipped MBPs (2021+) report a non-zero top safe-area
        // inset when the menu bar is on the same display. Other Macs
        // report zero.
        guard let screen = NSScreen.main else { return false }
        return screen.safeAreaInsets.top > 0
    }
}
