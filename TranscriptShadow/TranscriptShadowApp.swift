// @implements TECH-001, ENV-001, SCR-001, SCR-003, SCR-004, SCR-005
import SwiftUI

@main
struct TranscriptShadowApp: App {
    var body: some Scene {
        WindowGroup("Transcript Shadow") {
            MainWindowView()
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
