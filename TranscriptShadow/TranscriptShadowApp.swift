// @implements TECH-001, ENV-001, SCR-001, SCR-003, SCR-004, SCR-005, ARC-001, ARC-003, API-301
import AppKit
import SwiftUI

@main
struct TranscriptShadowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let env: AppEnvironment

    init() {
        // Try the real services; fall back to in-memory previews if the
        // database can't open or WhisperKit fails to construct. The
        // fallback keeps the UI usable in degraded modes (read-only) — a
        // future EPIC may surface this as a first-launch error.
        let resolvedEnv: AppEnvironment
        do {
            resolvedEnv = try AppEnvironment.live()
        } catch {
            print("TranscriptShadow: AppEnvironment.live() failed (\(error)) — falling back to preview env.")
            resolvedEnv = .preview()
        }
        self.env = resolvedEnv
        // Hand the AppDelegate a cleanup reference so it can run the
        // orphan scan on launch and the partial cleanup on terminate
        // (ARC-003 + API-301).
        AppDelegate.sharedCleanup = resolvedEnv.cleanup
    }

    var body: some Scene {
        // Single-window scene — no `New Window` menu item, no second
        // MainWindowView instance, no duplicate HUD state.
        // See Codex Gate 5a (2026-05-17): WindowGroup permitted multiple
        // windows whose per-instance @StateObject HUD controllers would
        // fan out the demo notifications and stamp out duplicate
        // NSPanel / NSStatusItem surfaces, breaking BR-501.
        Window("Transcript Shadow", id: "main") {
            MainWindowView(env: env)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: DesignSpacing.Layout.windowDefaultWidth,
                     height: DesignSpacing.Layout.windowDefaultHeight)
        .commands {
            // Standard macOS Settings entry — Cmd+,
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // Demo menu — remove when EPIC-08 wires real state transitions.
            CommandMenu("Demo") {
                Button("Pre-flight (SCR-001)") {
                    NotificationCenter.default.post(name: .demoNavPreFlight, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Processing (SCR-003)") {
                    NotificationCenter.default.post(name: .demoNavProcessing, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Transcript (SCR-004)") {
                    NotificationCenter.default.post(name: .demoNavTranscript, object: nil)
                }
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Button("Start recording → HUD (auto-detect)") {
                    NotificationCenter.default.post(name: .demoStartRecording, object: nil)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Force Notch HUD (DES-105)") {
                    NotificationCenter.default.post(name: .demoForceNotchHUD, object: nil)
                }
                .keyboardShortcut("5", modifiers: .command)

                Button("Force Menu Bar HUD (DES-106)") {
                    NotificationCenter.default.post(name: .demoForceMenuBarHUD, object: nil)
                }
                .keyboardShortcut("6", modifiers: .command)
            }
        }
    }
}

// MARK: - AppDelegate (ARC-003 cleanup hooks)

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Set by `TranscriptShadowApp.init` after the live `AppEnvironment`
    /// is built. Allows the delegate (whose own init takes no args) to
    /// reach the cleanup service for launch + terminate hooks.
    static var sharedCleanup: (any TempAudioCleanup)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Orphan scan (RISK-006 mitigation). Runs once at launch; deletes
        // every leftover WAV in the recordings dir per EPIC-08 scope
        // (silent delete, no recoverable UX in v0.7).
        Task { @MainActor in
            await AppDelegate.sharedCleanup?.scanForOrphans()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Best-effort terminal cleanup of any in-flight partials.
        // applicationWillTerminate is synchronous from AppKit's view —
        // we cap the wait at 2 s so a slow file-system can't hold the
        // process up indefinitely.
        //
        // Codex Gate 6 P1: capture the cleanup reference up front. The
        // static is @MainActor-isolated, so reading it inside a Task
        // running off-main while the main actor is blocked in
        // `group.wait` would deadlock until the wait times out, and
        // cleanupAll() would never run.
        guard let cleanup = AppDelegate.sharedCleanup else { return }
        let group = DispatchGroup()
        group.enter()
        Task.detached {
            await cleanup.cleanupAll()
            group.leave()
        }
        _ = group.wait(timeout: .now() + 2)
    }
}
