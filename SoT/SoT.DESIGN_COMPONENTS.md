---
version: 1.0
purpose: Source of Truth for UI components, design tokens, and pattern library.
id_prefix: DES-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by SoT.USER_JOURNEYS.md, EPICs, and code
---

# Design Components (SoT File)

> **Purpose**: Catalog of UI components, design tokens, and reusable patterns for Transcript Shadow.
> **ID Prefix**: DES-XXX
> **Status**: Active SoT file
> **Cross-References**: Referenced by SoT.USER_JOURNEYS.md, PRD.md, EPICs
> **Design Reference**: [ElevenLabs UI](https://ui.elevenlabs.io/docs/) — dark, minimal, audio-centric aesthetic

## Navigation by Category

**Core Components** (DES-001 to DES-099):

- [DES-001](#des-001-record-button) - Record Button
- [DES-002](#des-002-audio-level-indicator) - Audio Level Indicator
- [DES-003](#des-003-transcript-block) - Transcript Block

**Feature Components** (DES-101 to DES-199):

- [DES-101](#des-101-speaker-label) - Speaker Label
- [DES-102](#des-102-progress-pipeline) - Progress Pipeline

**Ambient / HUD Surfaces** (DES-201 to DES-299):

- [DES-201](#des-201-recording-hud-notch) - Recording HUD — Notch
- [DES-202](#des-202-recording-hud-menu-bar-extra) - Recording HUD — Menu Bar Extra

**Design Tokens** (DES-301 to DES-399):

- [DES-301](#des-301-color-system) - Color System

---

## DES-001: Record Button

**ID**: DES-001
**Category**: Core
**Status**: Planned
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-04-24

### Description

Primary action button to **start** a recording. Lives only on SCR-001 (Main Window). Large, centered, with clear state changes. Inspired by ElevenLabs UI audio controls — minimal, dark theme, high contrast accent.

> **Note**: Stopping a recording happens from the Recording HUD (DES-201 / DES-202), **not** from this button. Once recording starts the main window hides (BR-501), so this component is never shown in a "stop" state.

### Specifications

**Dimensions**: 64px circular
**Variants**: Idle (red circle), Disabled (gray — missing permissions or vault path)
**States**: idle → (on click: initiates recording, main window dismisses) → idle (on next app open)

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window) - Only surface this component appears on
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Step 3 (Start Recording)
- [DES-201](#des-201-recording-hud-notch) / [DES-202](#des-202-recording-hud-menu-bar-extra) - Own the Stop affordance
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Reason the stop state is not here

---

## DES-002: Audio Level Indicator

**ID**: DES-002
**Category**: Core
**Status**: Planned (deferred to post-MVP)
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-04-24

### Description

Real-time audio waveform or level meter for pre-record source verification on SCR-001 (e.g., "tap to test mic"). **Not used on the Recording HUD** — per BR-501, the recording surface shows only a recording indicator and Stop.

### Specifications

**Dimensions**: Full-width, 48px height
**Variants**: Waveform (animated bars), Simple (single level bar)
**States**: Active (during pre-record preview), Silent (no input detected — warning color)

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window) - Pre-record source verification (if shipped)
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Excluded from Recording HUD

---

## DES-003: Transcript Block

**ID**: DES-003
**Category**: Core
**Status**: Planned
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Rendered transcript segment showing speaker label, timestamp, and spoken text. Each speaker turn is a distinct block with visual separation.

### Specifications

**Layout**: Speaker label (bold, colored) + timestamp (muted) on left, text block on right
**Variants**: Compact (inline labels), Expanded (stacked labels)
**States**: Read-only, Editable (speaker name editing)

### Related IDs

- [SCR-004](SoT.USER_JOURNEYS.md#scr-004-transcript-view) - Transcript view
- [DES-101](#des-101-speaker-label) - Speaker label sub-component
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Review journey

---

## DES-101: Speaker Label

**ID**: DES-101
**Category**: Feature
**Status**: Planned
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Clickable label showing speaker identity. Displays auto-assigned name ("Speaker 1") that user can click to rename. Each speaker gets a distinct color.

### Specifications

**Dimensions**: Auto-width pill/chip
**Variants**: Auto-named (default), User-renamed (shows custom name)
**States**: Display, Hover (shows edit hint), Editing (inline text field)

### Related IDs

- [DES-003](#des-003-transcript-block) - Parent component
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Step 2

---

## DES-102: Progress Pipeline

**ID**: DES-102
**Category**: Feature
**Status**: Planned
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Multi-stage progress indicator showing pipeline stages: Transcribing → Diarizing → Formatting. Each stage shows completion percentage.

### Specifications

**Layout**: Horizontal segmented progress bar with stage labels
**Variants**: Linear (3 segments), Compact (single bar with stage label)
**States**: Waiting, Active (animating), Complete, Error

### Related IDs

- [SCR-003](SoT.USER_JOURNEYS.md#scr-003-processing-view) - Processing view
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Step 6

---

## DES-201: Recording HUD — Notch

**ID**: DES-201
**Category**: Ambient / HUD
**Status**: Planned
**Platform**: macOS (notch-equipped MacBook Pro — 14" and 16", M1 Pro/Max and later)
**Created**: 2026-04-24
**Last Updated**: 2026-04-24

### Description

Primary recording surface on notch-equipped Macs. Treats the hardware display notch as an ambient HUD, similar in spirit to iOS Dynamic Island but constrained to this app's recording state. Stays out of the user's way while they run a meeting in another app; surfaces a single action — Stop — on demand.

### Specifications

**Mount**: Borderless, always-on-top panel (NSPanel with `.hud` style mask, `.statusBar + 1` level) positioned flush with the physical notch on the active screen.

**Collapsed (resting)**
- Dimensions: ~180 × 32 px, hugging notch geometry
- Content: solid black background matching the bezel (blends with notch), a pulsing red dot (recording indicator), and a compact "● REC" label
- No timer, waveform, or controls visible

**Expanded (on hover / click)**
- Dimensions: ~260 × 64 px, drops below the notch
- Content: recording indicator + Stop button (pill, red fill, white glyph). Optional secondary text "Recording… tap Stop when done."
- Expansion is a spring-animated transition (~180ms)
- Collapses on pointer-leave after a 600ms delay, or immediately after Stop

**States**: Appearing, Collapsed, Expanded, Dismissing, Error
**Variants**: None — this is a single, opinionated surface.

### Interaction

- Hover → expand
- Click on collapsed surface → also expands (for trackpad users who don't hover)
- Click Stop → triggers recording stop; HUD dismisses; main window restores into SCR-003
- Right-click → reveals tiny context menu: "Open Transcript Shadow", "Cancel recording (discard audio)"

### Constraints & Fallbacks

- **Required hardware**: Notch-equipped MacBook Pro with the app's window currently on that display's screen. If the user moves focus to an external display mid-recording, the HUD remains on the notch display (does not follow the cursor).
- **If notch is not present on the active screen**: auto-swap to DES-202 (Menu Bar Extra).
- **Menu bar hidden** (fullscreen meeting apps on the notch display): HUD remains visible — it is layered above the menu bar, so fullscreen apps do not cover it by default. Revisit this during implementation (may need display-link tricks).

### Related IDs

- [SCR-002](SoT.USER_JOURNEYS.md#scr-002-recording-hud) - Primary surface
- [DES-202](#des-202-recording-hud-menu-bar-extra) - Fallback realization
- [DES-301](#des-301-color-system) - Uses accent red
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Steps 3–5
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Enforces single-action constraint
- [RISK-007 in PRD](../PRD.md) - Hardware fragmentation risk

---

## DES-202: Recording HUD — Menu Bar Extra

**ID**: DES-202
**Category**: Ambient / HUD
**Status**: Planned
**Platform**: macOS (all — fallback for non-notch Macs, plus explicit opt-in)
**Created**: 2026-04-24
**Last Updated**: 2026-04-24

### Description

Fallback recording surface for Macs without a visible notch (MacBook Air, Intel MBP, iMac, Mac mini/Studio on any display, or any Mac with the app on an external display). An NSStatusItem in the system menu bar, with a compact popover that exposes Stop.

### Specifications

**Status Item (menu bar icon)**
- Template icon: a red-filled circle (8px) overlaid on a monochrome app glyph, pulsing ~1Hz while recording
- States: Recording (pulsing red dot), Idle (hidden — the status item only exists during a recording session)

**Popover (on click)**
- Dimensions: 240 × 96 px, standard NSPopover with arrow anchored to status item
- Content (single column, centered): "Recording" label + Stop button (pill, red fill). Optional elapsed-time text is **not** shown (BR-501).
- Dismissal: click Stop, click outside popover, or press Escape

**States**: Recording (pulsing), Popover-open, Error
**Variants**: None.

### Interaction

- Click status item → popover opens with Stop
- Click Stop → recording stops; status item removed from menu bar; main window restores into SCR-003
- Right-click status item → context menu: "Open Transcript Shadow", "Cancel recording (discard audio)"

### Constraints & Fallbacks

- Works on every Mac macOS 14+ supports. No hardware prerequisites beyond BR-401.
- Persists across Spaces and fullscreen apps (standard macOS menu bar behavior).

### Related IDs

- [SCR-002](SoT.USER_JOURNEYS.md#scr-002-recording-hud) - Primary surface
- [DES-201](#des-201-recording-hud-notch) - Preferred realization when available
- [DES-301](#des-301-color-system) - Uses accent red
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Steps 3–5
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Enforces single-action constraint

---

## DES-301: Color System

**ID**: DES-301
**Category**: Design Token
**Status**: Planned
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Color palette following ElevenLabs-inspired dark theme aesthetic. Dark backgrounds with high-contrast accents for audio/recording UI.

### Specifications

**Background**: Dark (#0A0A0B primary, #141415 secondary)
**Accent**: Recording red (#EF4444), Success green (#22C55E)
**Text**: Primary (#F5F5F5), Secondary (#A1A1AA), Muted (#52525B)
**Speaker Colors**: Array of 6 distinct hues for speaker differentiation

### Related IDs

- [DES-001](#des-001-record-button) - Uses accent red
- [DES-101](#des-101-speaker-label) - Uses speaker color array

---

## Deprecated Components

_No deprecated components._

---

## Cross-Reference Index

**Components by Screen**:

- SCR-001 uses: DES-001, DES-002 (optional pre-record preview)
- SCR-002 uses: DES-201 (notch primary) or DES-202 (menu bar fallback)
- SCR-003 uses: DES-102
- SCR-004 uses: DES-003, DES-101

**Components by Journey**:

- UJ-001 uses: DES-001, DES-201 / DES-202, DES-102
- UJ-002 uses: DES-003, DES-101, DES-301 (speaker palette)

---

## Update Protocol

### When to Add New DES-XXX IDs

1. **New UI Component**: Distinct, reusable interface element
2. **Design Token Update**: New color, typography, or spacing token
3. **Pattern Library Addition**: Recurring design solution

### Bidirectional Reference Checklist

When adding a new DES-XXX:

- [ ] Update SoT.USER_JOURNEYS.md "Design Components" section
- [ ] Update EPIC Section 2 "Context & IDs" list
- [ ] Create corresponding component file in codebase

---

*End of SoT.DESIGN_COMPONENTS.md - Authoritative source for all DES-XXX IDs*
