// @implements DES-302 (Typography System)
// @see SoT/SoT.DESIGN_COMPONENTS.md
// @see design/visual-prototype/project/src/tokens.jsx (FONT_UI, FONT_MONO)

import SwiftUI

enum DesignFonts {

    // MARK: - Size scale (DES-302)
    enum Size {
        static let xs: CGFloat   = 11   // badges, minor labels
        static let sm: CGFloat   = 12   // sidebar secondary text, speaker labels
        static let base: CGFloat = 14   // UI body, buttons, sidebar primary
        static let md: CGFloat   = 16   // content headings, transcript default
        static let lg: CGFloat   = 20   // screen titles (rare)
        static let xl: CGFloat   = 24   // empty-state messaging
    }

    // MARK: - UI font (SF Pro)
    /// macOS system font. Falls back to .system if SF Pro is unavailable.
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .default)
    }

    // MARK: - Mono font (SF Mono)
    /// Timestamps, durations, technical metadata.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: - Semantic roles
    static let bodyText   = ui(Size.base)
    static let bodyMedium = ui(Size.base, weight: .medium)
    static let label      = ui(Size.sm, weight: .medium)
    static let caption    = ui(Size.xs)
    static let heading    = ui(Size.md, weight: .semibold)
    static let screenTitle = ui(Size.lg, weight: .semibold)

    /// Timestamp pill ([HH:MM:SS]) inside DES-003 TranscriptBlock.
    static let timestamp = mono(Size.xs)
    /// Sidebar row secondary line (date · duration · speaker count).
    static let sidebarMeta = mono(Size.xs)
}
