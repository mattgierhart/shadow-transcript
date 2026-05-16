// @implements DES-303 (Spacing and Sizing), DES-203 (Density Modes)
// @see SoT/SoT.DESIGN_COMPONENTS.md
// Base unit: 4pt. Scale: 4, 8, 12, 16, 24, 32, 48, 64.

import SwiftUI

enum DesignSpacing {

    // MARK: - 4pt scale
    static let xs: CGFloat   = 4
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 12
    static let base: CGFloat = 16
    static let lg: CGFloat   = 24
    static let xl: CGFloat   = 32
    static let xxl: CGFloat  = 48
    static let xxxl: CGFloat = 64

    // MARK: - Layout constants (DES-201)
    enum Layout {
        static let sidebarDefault: CGFloat = 240
        static let sidebarMin: CGFloat = 180
        static let sidebarMax: CGFloat = 320
        /// Spacious-mode content max width — SCR-001, SCR-003, SCR-005.
        static let spaciousMaxWidth: CGFloat = 600
        /// Settings sheet width.
        static let settingsWidth: CGFloat = 560
        /// Window dimensions.
        static let windowMinWidth: CGFloat = 800
        static let windowMinHeight: CGFloat = 600
        static let windowDefaultWidth: CGFloat = 1100
        static let windowDefaultHeight: CGFloat = 700
    }

    // MARK: - Density modes (DES-203)
    /// SCR-001 / SCR-003 / SCR-005 — ambient, peripheral-friendly.
    enum Spacious {
        static let sectionPadding: CGFloat = 48
        static let elementGap: CGFloat = 24
        static let contentMaxWidth: CGFloat = 600
    }

    /// SCR-004 / SCR-006 — focused, information-rich.
    enum Dense {
        static let sectionPadding: CGFloat = 16
        static let blockGap: CGFloat = 8
        static let sidebarRowPaddingV: CGFloat = 8
        static let sidebarRowPaddingH: CGFloat = 12
    }

    // MARK: - Component-specific (DES-303)
    enum Component {
        static let toolbarHeight: CGFloat = 44  // matches MacWindow in JSX prototype
        static let buttonPaddingV: CGFloat = 8
        static let buttonPaddingH: CGFloat = 16
        static let pillPaddingV: CGFloat = 4
        static let pillPaddingH: CGFloat = 12
        /// 80pt circular Record button (DES-001). The SoT initially specified
        /// 64pt; the Claude Design prototype landed on 80pt and was visually
        /// approved. Sized to feel like a "primary CTA" on the spacious SCR-001.
        static let recordButtonSize: CGFloat = 80
    }
}
