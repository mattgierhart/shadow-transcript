// @implements DES-106 (Recording HUD — Menu Bar Extra)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-106
// @see design/visual-prototype/project/src/scr002.jsx :: PlainMenuBar
//
// NSStatusItem in the system menu bar. Icon is a small filled red circle
// with the same 1Hz oscillation as the notch HUD (drawn by SwiftUI inside
// a custom view, rather than a static template image, so visual parity
// with DES-105 holds). Click opens an NSPopover containing the same
// Recording/Stop layout in popover form.

import AppKit
import SwiftUI

@MainActor
final class MenuBarRecordingItem {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func show(onStop: @escaping () -> Void) {
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: 28)
            if let button = item.button {
                // SwiftUI-backed icon view so we get the same red dot +
                // pulse animation as DES-105 — not a static template image.
                let icon = NSHostingView(rootView: MenuBarIconView())
                icon.frame = NSRect(x: 0, y: 0, width: 28, height: 22)
                button.subviews.forEach { $0.removeFromSuperview() }
                button.addSubview(icon)
                button.action = #selector(togglePopover(_:))
                button.target = self
            }

            let pop = NSPopover()
            pop.behavior = .transient
            pop.contentSize = NSSize(width: 220, height: 80)
            pop.contentViewController = NSHostingController(
                rootView: RecordingHUDContent(layout: .popover, onStop: { [weak pop] in
                    pop?.performClose(nil)
                    onStop()
                })
            )

            statusItem = item
            popover = pop
        }
    }

    func hide() {
        popover?.performClose(nil)
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        popover = nil
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

/// The 1Hz-oscillating red dot drawn inside the menu-bar status item.
private struct MenuBarIconView: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(DesignColors.recordingRed)
            .frame(width: 9, height: 9)
            .shadow(color: DesignColors.recordingRed, radius: 4)
            .opacity(pulse ? 1.0 : 0.55)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulse)
            .frame(width: 28, height: 22)
            .onAppear { pulse = true }
    }
}
