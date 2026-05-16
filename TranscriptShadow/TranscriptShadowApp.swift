// @implements TECH-001, ENV-001, SCR-001
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
    }
}
