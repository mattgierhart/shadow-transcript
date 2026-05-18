// @implements ARC-001
// SwiftUI EnvironmentKey + .environment injection so every screen view-model
// can pull services through `@Environment(\.appEnvironment)`.

import SwiftUI

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .preview()
}

public extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
