// @implements DES-301 (Color Palette), DES-305 (Status & Feedback Colors)
// @see SoT/SoT.DESIGN_COMPONENTS.md
// @see design/visual-prototype/project/src/tokens.jsx

import SwiftUI

enum DesignColors {

    // MARK: - Backgrounds (DES-301)
    static let bgPrimary   = Color(hex: 0x0A0A0B)
    static let bgSecondary = Color(hex: 0x141415)
    static let bgTertiary  = Color(hex: 0x1A1A1C)

    // MARK: - Accents (DES-301)
    static let accentPrimary      = Color(hex: 0x2DD4BF)
    static let accentPrimaryHover = Color(hex: 0x14B8A6)
    /// Recording red. Only DES-001 (RecordButton) and DES-105/DES-106 (HUD dot)
    /// may use this color. See BR-501.
    static let recordingRed       = Color(hex: 0xEF4444)

    // MARK: - Text (DES-301)
    static let textPrimary   = Color(hex: 0xF5F5F5)
    static let textSecondary = Color(hex: 0xA1A1AA)
    static let textMuted     = Color(hex: 0x52525B)

    // MARK: - Borders (DES-301)
    static let borderDefault = Color(hex: 0x1E1E20)
    static let borderSubtle  = Color(hex: 0x161618)

    // MARK: - Speaker palette (DES-301)
    /// Six muted pastels for speaker labels (DES-101). Index assignment is
    /// first-appearance order from `WordSpeakerAligner` and persisted in
    /// `DBT-002.color_index`; UI must not re-shuffle.
    static let speakerPalette: [Color] = [
        Color(hex: 0x8BB8E8),  // soft blue
        Color(hex: 0xE8A87C),  // soft coral
        Color(hex: 0x82D9A5),  // soft mint
        Color(hex: 0xC4A0E8),  // soft lavender
        Color(hex: 0xE8D482),  // soft gold
        Color(hex: 0xE88B9C),  // soft rose
    ]

    static func speakerColor(index: Int) -> Color {
        speakerPalette[index % speakerPalette.count]
    }

    // MARK: - Status & Feedback (DES-305)
    enum Status {
        static let success = Color(hex: 0x22C55E)
        static let warning = Color(hex: 0xF59E0B)
        /// Same hex as `recordingRed` but semantically distinct — use this
        /// for true error states (pipeline failure, permission denied).
        static let error   = Color(hex: 0xEF4444)
        static let info    = Color(hex: 0x3B82F6)
        static let muted   = Color(hex: 0x52525B)
    }
}
