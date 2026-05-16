// @implements TECH-001, ENV-001, SCR-001, SCR-003, SCR-004
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
            }
        }
    }
}
