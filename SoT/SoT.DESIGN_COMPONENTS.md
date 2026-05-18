---
version: 2.1
purpose: Source of Truth for UI components, design tokens, layout principles, and pattern library.
id_prefix: DES-XXX
last_updated: 2026-05-16
authority: This is a SoT file - IDs here are referenced by SoT.USER_JOURNEYS.md, EPICs, and code
---

# Design Components (SoT File)

> **Purpose**: Catalog of UI components, design tokens, layout principles, and reusable patterns for Transcript Shadow.
> **ID Prefix**: DES-XXX
> **Status**: Active SoT file
> **Cross-References**: Referenced by SoT.USER_JOURNEYS.md, PRD.md, EPICs
> **Design References**: [ElevenLabs UI](https://ui.elevenlabs.io/docs/) — dark, minimal, audio-centric aesthetic; [Obsidian](https://obsidian.md) — sidebar+content layout, markdown-native, dark theme

## Navigation by Category

**Core Components** (DES-001 to DES-099):

- [DES-001](#des-001-record-button) - Record Button
- [DES-002](#des-002-audio-level-indicator) - Audio Level Indicator
- [DES-003](#des-003-transcript-block) - Transcript Block
- [DES-004](#des-004-sidebar-transcript-list) - Sidebar Transcript List
- [DES-005](#des-005-toolbar) - Toolbar

**Feature Components** (DES-101 to DES-199):

- [DES-101](#des-101-speaker-label) - Speaker Label
- [DES-102](#des-102-progress-pipeline) - Progress Pipeline
- [DES-103](#des-103-permission-prompt) - Permission Prompt
- [DES-104](#des-104-empty-state) - Empty State
- [DES-105](#des-105-recording-hud-notch) - Recording HUD — Notch
- [DES-106](#des-106-recording-hud-menu-bar-extra) - Recording HUD — Menu Bar Extra

**Layout Principles** (DES-201 to DES-299):

- [DES-201](#des-201-page-layout-system) - Page Layout System
- [DES-202](#des-202-navigation-pattern) - Navigation Pattern
- [DES-203](#des-203-density-modes) - Density Modes

**Design Tokens** (DES-301 to DES-399):

- [DES-301](#des-301-color-palette) - Color Palette
- [DES-302](#des-302-typography-system) - Typography System
- [DES-303](#des-303-spacing-and-sizing) - Spacing and Sizing
- [DES-304](#des-304-borders-and-elevation) - Borders and Elevation
- [DES-305](#des-305-status-and-feedback-colors) - Status and Feedback Colors

---

## DES-001: Record Button

**ID**: DES-001
**Category**: Core
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-05-16

### Description

Primary action button for **starting** a recording. Per BR-501, the main window is hidden during active recording — so this button has no Stop responsibility. Stop lives on the Recording HUD (DES-105 Notch, DES-106 Menu Bar Extra). DES-001 is the only red element on the main window; recording red is reserved exclusively for this control.

### Specifications

**Dimensions**: 64px circular
**Color**: Recording red (#EF4444) only — sole use of red as a brand element
**Variants**: Idle (red circle, default), Disabled (gray, 30% opacity — shown when mic permission missing)
**States**: idle → (click) → main window hides + HUD appears (per BR-501). No "recording" state lives on this control.
**Animation**: Subtle hover glow only. No pulse — the button is unmounted during recording.

### Accessibility

- VoiceOver: "Start recording"
- Keyboard: Space bar to start

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window-idle) - Main window placement (pre-record only)
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Why this button has no Stop state
- [DES-105](#des-105-recording-hud-notch) / [DES-106](#des-106-recording-hud-menu-bar-extra) - Where Stop lives
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Step 3 (click → hide main → show HUD)
- [DES-301](#des-301-color-palette) - Uses recording red (only component to use red)

---

## DES-002: Audio Level Preview

**ID**: DES-002
**Category**: Core
**Status**: Implemented (2026-05-17, EPIC-07 — visual only; live levels stream wiring deferred to v0.8)
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-05-16

### Description

Pre-record audio level preview shown beneath the Record button on SCR-001 (Main Window — Idle). Lets the user confirm the mic is hearing them and that system audio is wired up **before** they click Record. Per BR-501, no audio-level visualization is shown during active recording — once the user clicks Record, the main window hides and the only surface visible is the Recording HUD (DES-105/DES-106).

### Specifications

**Dimensions**: Full-width of content area, 40px height
**Style**: Minimal waveform bars (not a full spectrogram). Teal accent color (DES-301 primary accent) with low opacity for inactive bars, bright for active peaks.
**Variants**: Waveform (animated bars, default), Minimal (thin horizontal line with amplitude)
**States**:
- Active: Bars animate with live mic + system audio, teal accent (only visible on SCR-001)
- Silent: Bars flatline, amber warning tint if no input detected for 5s (encourages user to check mic before recording)
- Disabled: Gray, no animation (no mic permission)

### Design Notes

This is a **pre-flight check**, not a recording indicator. The audio source toggles (mic + system audio) sit above it on SCR-001 so the user can see both inputs registering. After Record is clicked, this component is unmounted along with the rest of the main window per BR-501.

### Accessibility

- VoiceOver: "Audio input level: active" / "Audio input level: no input detected"

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window-idle) - Pre-record preview surface (only place this appears)
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Why this is excluded from the recording surface
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Step 2 (pre-flight check)
- [DES-301](#des-301-color-palette) - Teal accent for bars

---

## DES-003: Transcript Block

**ID**: DES-003
**Category**: Core
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Description

Rendered transcript segment showing speaker label, timestamp, and spoken text. Each speaker turn is a distinct block with visual separation. This is the densest component — used in post-recording review mode where the user is focused.

### Specifications

**Layout**: Vertical stack per turn — speaker label pill (colored) + timestamp (muted, SF Mono) on one line, text block below
**Font**: Transcript text uses system font at user-adjustable size (respects macOS System Settings > Accessibility > Display > Text Size)
**Variants**:
- Compact (default): Tight line spacing, minimal padding between turns — optimized for scanning long transcripts
- Expanded: More generous spacing, used when fewer turns visible
**States**: Read-only (default), Hover (shows copy icon per block), Editable (speaker name editing active)

### Accessibility

- Keyboard navigation between blocks (up/down arrow)
- VoiceOver reads speaker name then text content

### Related IDs

- [SCR-004](SoT.USER_JOURNEYS.md#scr-004-transcript-view) - Transcript view
- [DES-101](#des-101-speaker-label) - Speaker label sub-component
- [DES-302](#des-302-typography-system) - Text sizing rules
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Review journey

---

## DES-004: Sidebar Transcript List

**ID**: DES-004
**Category**: Core
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Left sidebar listing past transcripts, modeled after Obsidian's file explorer. Shows transcript history with date, title, duration, and speaker count. Always visible, providing persistent navigation context.

### Specifications

**Width**: 240px default, resizable (180-320px range), collapsible
**Layout**: Vertical list, grouped by date (Today, Yesterday, This Week, Older)
**Row Content**: Title (primary text), date + duration (secondary text), speaker count badge
**States**:
- Default: Idle list
- Selected: Highlighted row (teal accent tint on background)
- Hover: Subtle highlight
- Empty: DES-104 empty state with "Record your first meeting" prompt
**Search**: Search bar at top (filters list inline, like Obsidian's search)

### Design Notes

Follows Obsidian's sidebar pattern. Dark surface (#141415) slightly lighter than main background. Thin right border (#1E1E20) separating from content area.

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window) - Sidebar in main window
- [SCR-006](SoT.USER_JOURNEYS.md#scr-006-transcript-history) - History is the sidebar
- [DES-202](#des-202-navigation-pattern) - Sidebar+content pattern
- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts) - Data source

---

## DES-005: Toolbar

**ID**: DES-005
**Category**: Core
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

macOS native toolbar at top of window. Contains record button (centered), audio source toggles (left), and settings gear (right). Uses NSToolbar for native macOS integration (traffic lights, title bar).

### Specifications

**Height**: Standard macOS toolbar height
**Layout**: Left: audio source indicator (mic + system icons) | Center: record button (DES-001) | Right: settings gear, sidebar toggle
**Style**: Native macOS toolbar with material background (follows system appearance)
**States**:
- Idle: Record button prominent, sources shown
- Recording: Timer replaces title, stop button replaces record
- Processing: Progress replaces timer

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window) - Top of window
- [DES-001](#des-001-record-button) - Embedded in toolbar
- [DES-304](#des-304-borders-and-elevation) - Native macOS surface treatment

---

## DES-101: Speaker Label

**ID**: DES-101
**Category**: Feature
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Description

Clickable pill showing speaker identity. Displays auto-assigned name ("Speaker 1") that user can click to rename. Each speaker gets a distinct muted pastel color from DES-301 speaker palette.

### Specifications

**Dimensions**: Auto-width pill, 24px height, 12px horizontal padding
**Font**: SF Pro Medium, 12px
**Color**: Muted pastel background (10% opacity of speaker color), text in speaker color
**Variants**: Auto-named ("Speaker 1", default), User-renamed (custom name, checkmark icon)
**States**:
- Display: Pill with name
- Hover: Cursor changes, subtle border appears (edit affordance)
- Editing: Inline text field replaces pill, teal focus ring
- Saved: Brief flash animation confirming rename

### Accessibility

- VoiceOver: "Speaker label: [name]. Double-click to rename."
- Keyboard: Enter to edit, Escape to cancel

### Related IDs

- [DES-003](#des-003-transcript-block) - Parent component
- [DES-301](#des-301-color-palette) - Speaker color array
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Step 2

---

## DES-102: Progress Pipeline

**ID**: DES-102
**Category**: Feature
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Description

Multi-stage progress indicator showing pipeline stages: Transcribing → Diarizing → Formatting. Each stage shows completion percentage. This view appears after recording stops — the "living" quality should carry over (processing is happening, the app is working).

### Specifications

**Layout**: Vertical stack, centered in content area (spacious — same density as recording view)
**Stages**: 3 connected nodes with progress bars between:
1. "Transcribing..." (WhisperKit)
2. "Identifying speakers..." (pyannote)
3. "Formatting transcript..." (merge + markdown)
**Style**: Each stage is a row: icon (SF Symbol) + label + progress percentage. Active stage has teal accent. Completed stages show checkmark in green.
**Variants**: Linear (3 rows, default), Compact (single progress bar with rotating label)
**States**: Waiting (gray), Active (teal, animating), Complete (green check), Error (red, retry button)

### Design Notes

Centered, spacious layout with generous whitespace. The user just finished a call — this is a brief interlude before they focus on the transcript. Show estimated time remaining below the pipeline.

### Related IDs

- [SCR-003](SoT.USER_JOURNEYS.md#scr-003-processing-view) - Processing view
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Step 6
- [DES-203](#des-203-density-modes) - Uses spacious mode

---

## DES-103: Permission Prompt

**ID**: DES-103
**Category**: Feature
**Status**: Partially Implemented (2026-05-17, EPIC-07 — inline banners on SCR-001 + Settings request chip; full first-launch prompt card deferred to v0.8)
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

First-launch permission request card explaining why microphone and Screen Recording permissions are needed. Friendly, non-technical language. Appears in main content area before first recording.

### Specifications

**Layout**: Centered card (max-width 480px), icon + title + explanation + CTA button
**Content**:
- Mic permission: "Transcript Shadow needs your microphone to record meetings. All audio stays on your Mac."
- Screen Recording: "To capture what others say in video calls, we need Screen Recording access. No screen content is captured — audio only."
**Style**: Card with subtle border on dark surface. Teal CTA button.
**States**: Pending (show prompt), Granted (hidden), Denied (show guidance to System Settings)

### Related IDs

- [RISK-004 in PRD](../PRD.md) - Permission friction mitigation
- [UJ-003](SoT.USER_JOURNEYS.md#uj-003-configure-app-settings) - First-launch
- [INT-201](SoT.INTEGRATIONS.md#int-201-macos-audio-capture) - Mic permission
- [INT-202](SoT.INTEGRATIONS.md#int-202-screencapturekit-system-audio) - Screen Recording permission

---

## DES-104: Empty State

**ID**: DES-104
**Category**: Feature
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Shown when no transcripts exist (first launch, or sidebar is empty). Welcoming, guides user toward first action.

### Specifications

**Layout**: Centered in content area, icon + message + subtle arrow pointing to record button
**Content**: "No transcripts yet. Hit record to capture your first meeting."
**Style**: Muted text, minimal. Not flashy — just helpful.
**Variants**: Sidebar empty (compact, in sidebar area), Content empty (full content area)

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window-idle) - First-launch state
- [DES-004](#des-004-sidebar-transcript-list) - Sidebar empty variant

---

## DES-105: Recording HUD — Notch

**ID**: DES-105
**Category**: Feature
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS (notch-equipped MacBook Pro 14"/16", 2021+)
**Created**: 2026-05-15
**Last Updated**: 2026-05-16

### Description

Primary realization of SCR-002 (Recording HUD) on notch-equipped MacBook Pros. A persistent panel anchored at the display notch that hosts the only app-owned UI visible while recording is active. Per BR-501, exposes exactly one user-facing action: **Stop**. Sits at window level `.statusBar + 1` so it survives over fullscreen meeting apps (Zoom, Teams, Meet). Implemented as an `NSPanel` with non-activating + can-be-visible-on-all-spaces behavior.

### Specifications

**Surface**: Borderless `NSPanel` clamped to display notch geometry (top-center, ≈ notch width when collapsed, expandable left/right to ~280pt when revealed)
**Window Level**: `.statusBar + 1` (above fullscreen apps)
**Collected State** (default during recording):
- Width: ≈ display notch width
- Height: notch height
- Content: small red dot indicator (recording active) — no text, no timer
**Expanded State** (on hover or single click):
- Width: 280pt, Height: 36pt
- Content (left → right): small red dot · "Recording" label (SF Pro Medium 12px, DES-302) · **Stop** button (red square, DES-001 recording red, 24pt)
- Stop is the only interactive element. No timer, audio level, source toggle, pause/resume, or settings.
**Material**: NSVisualEffectView `.hudWindow` material (dark vibrancy that reads over any background)
**Transitions**:
- Appearing: fade + scale-down-from-notch (~150ms ease-out) when Record clicked on SCR-001
- Stopping: collapse + fade-out (~120ms ease-in) before SCR-003 restores the main window
- Hover expand: width tween 100ms ease-out
**Animation**: red dot has a 1Hz subtle opacity oscillation (0.6 → 1.0) to confirm liveness without demanding attention.

### Accessibility

- VoiceOver: collapsed announces "Recording. Click to expand."; expanded announces "Recording. Stop button."
- Keyboard: global hotkey (configurable, default Cmd+Shift+. ) sends Stop without needing to hover.

### Design Notes

The notch HUD is the **primary** realization, not a luxury alternative — design with feature parity to DES-106 (Menu Bar Extra). If the notch HUD cannot stay above fullscreen meeting apps reliably, RISK-008's mitigation plan promotes DES-106 to primary.

### Related IDs

- [SCR-002](SoT.USER_JOURNEYS.md#scr-002-recording-hud) - The screen this realizes
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Mandate (single Stop action, no other UI)
- [DES-106](#des-106-recording-hud-menu-bar-extra) - Peer realization for non-notch Macs
- [DES-301](#des-301-color-palette) - Recording red, teal disallowed here
- [DES-302](#des-302-typography-system) - "Recording" label uses SF Pro Medium 12px
- [RISK-008 in PRD](../PRD.md) - Fullscreen-occlusion risk this HUD must clear

---

## DES-106: Recording HUD — Menu Bar Extra

**ID**: DES-106
**Category**: Feature
**Status**: Implemented (2026-05-17, EPIC-07)
**Platform**: macOS (all Macs without a display notch; also fallback when DES-105 cannot stay above fullscreen)
**Created**: 2026-05-15
**Last Updated**: 2026-05-16

### Description

Peer realization of SCR-002 (Recording HUD) on non-notch Macs. An `NSStatusItem` in the system menu bar serves as the always-visible recording indicator. Per BR-501, exposes exactly one user-facing action: **Stop**. Designed as a **peer**, not a degraded fallback — feature-parity with DES-105.

### Specifications

**Surface**: `NSStatusItem` in the system menu bar (`.variableLength`), accompanied by an `NSPopover` on click
**Status Item (always visible during recording)**:
- Icon: small filled red circle (16x16, recording red #EF4444) — same 1Hz opacity oscillation as DES-105
- No text in the menu bar (icon-only to respect macOS conventions)
**Popover (on click)**:
- Size: 220pt x 80pt
- Layout: vertical stack — "Recording" label (SF Pro Medium 14px) · **Stop** button (full-width, red, 36pt tall)
- Stop is the only interactive element. No timer, audio level, source toggle, pause/resume, or settings.
- Material: standard `.popover` background, no custom chrome
**Transitions**:
- Appearing: status item slides in from menu-bar-right (system default)
- Stopping: status item fades + removes (~120ms) before SCR-003 restores the main window
- Popover: standard macOS popover animation
**Window Level**: status items are always above other windows by macOS design — no level juggling required (this is why DES-106 is the safety net when DES-105 fails fullscreen occlusion)

### Accessibility

- VoiceOver: status item announces "Recording. Click to show Stop button."; popover announces "Stop recording button."
- Keyboard: same global hotkey as DES-105 (configurable, default Cmd+Shift+. ) sends Stop directly.

### Design Notes

Reliability advantage: macOS guarantees status items appear above fullscreen apps. This is why DES-106 is the safety net for the fullscreen-occlusion risk that motivates RISK-008. Visual treatment should NOT mark this as the "degraded" version — same red dot, same single Stop action, same liveness oscillation.

### Related IDs

- [SCR-002](SoT.USER_JOURNEYS.md#scr-002-recording-hud) - The screen this realizes
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Mandate (single Stop action, no other UI)
- [DES-105](#des-105-recording-hud-notch) - Peer realization for notch Macs
- [DES-301](#des-301-color-palette) - Recording red
- [DES-302](#des-302-typography-system) - "Recording" label typography
- [RISK-008 in PRD](../PRD.md) - Promoted to primary if DES-105 fullscreen risk materializes

---

## DES-201: Page Layout System

**ID**: DES-201
**Category**: Layout Principle
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Sidebar + content layout following Obsidian's pattern. Persistent sidebar on left, main content area on right. Single-window app.

### Specification

**Window**: Minimum 800x600, default 1100x700
**Sidebar**: 240px default width (resizable 180-320px), collapsible via toolbar button or Cmd+\
**Content Area**: Fills remaining width. Content max-width varies by screen:
- Recording/Processing views: 600px centered (spacious)
- Transcript view: Full width (dense, uses all space)
- Settings: 560px centered
**Divider**: 1px border (#1E1E20) between sidebar and content

### Related IDs

- [DES-004](#des-004-sidebar-transcript-list) - Sidebar component
- [DES-202](#des-202-navigation-pattern) - Navigation within layout
- [DES-203](#des-203-density-modes) - Content area density

---

## DES-202: Navigation Pattern

**ID**: DES-202
**Category**: Layout Principle
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Sidebar + content navigation modeled after Obsidian. Sidebar provides persistent transcript history and search. Content area transitions between views based on app state (idle, recording, processing, viewing transcript, settings).

### Specification

**Primary Navigation**: Sidebar transcript list (DES-004) — click to open past transcripts
**State-Driven Content**: Content area shows the active view based on pipeline state:
- Idle (no recording): Last transcript or empty state
- Recording: SCR-002 recording view
- Processing: SCR-003 processing view
- Viewing: SCR-004 transcript view
**Secondary Navigation**: Toolbar (DES-005) — settings gear opens settings as a sheet/panel overlay
**Keyboard Shortcuts**:
- Cmd+R: Start/stop recording
- Cmd+E: Export current transcript to Obsidian
- Cmd+,: Open settings
- Cmd+\: Toggle sidebar
- Cmd+F: Focus search in sidebar

### Related IDs

- [DES-004](#des-004-sidebar-transcript-list) - Sidebar
- [DES-005](#des-005-toolbar) - Toolbar
- [DES-201](#des-201-page-layout-system) - Layout context

---

## DES-203: Density Modes

**ID**: DES-203
**Category**: Layout Principle
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Adaptive density across the app's two distinct usage modes. The design interview established: recording/processing should feel spacious and "alive but not demanding attention" (user is in a meeting). Post-processing transcript review should feel denser (user is focused, call is over).

### Specification

**Spacious Mode** — Used for: SCR-001 (idle), SCR-002 (recording), SCR-003 (processing)
- Content max-width: 600px, centered
- Generous vertical padding (32-48px between elements)
- Large touch targets, minimal information
- The "listening" mode — ambient, peripheral-friendly

**Dense Mode** — Used for: SCR-004 (transcript view), SCR-006 (transcript history via sidebar)
- Content fills available width
- Tight line spacing (1.4-1.5 line height for transcript text)
- Compact padding (8-12px between transcript blocks)
- The "reading" mode — focused, information-rich

**Transition**: Animate density change when transitioning from processing → transcript view (expand content width, tighten spacing)

### Related IDs

- [DES-201](#des-201-page-layout-system) - Layout context
- [DES-003](#des-003-transcript-block) - Dense mode primary component
- [DES-102](#des-102-progress-pipeline) - Spacious mode primary component

---

## DES-301: Color Palette

**ID**: DES-301
**Category**: Design Token
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Description

Dark theme palette. ElevenLabs-inspired dark backgrounds with teal accent. Red is reserved exclusively for the record button (DES-001). Obsidian-informed surface hierarchy for sidebar+content layout.

### Specification

**Background**:
- Primary: #0A0A0B (main content background)
- Secondary: #141415 (sidebar, elevated surfaces)
- Tertiary: #1A1A1C (hover states, subtle highlights)

**Accent**:
- Primary Accent: #2DD4BF (teal — CTAs, active states, links, audio level bars, focus rings)
- Primary Accent Hover: #14B8A6 (darker teal for hover)
- Recording Red: #EF4444 (ONLY for record button DES-001 — no other use)

**Text**:
- Primary: #F5F5F5 (headings, body text)
- Secondary: #A1A1AA (labels, captions, timestamps)
- Muted: #52525B (placeholders, disabled text)

**Borders**:
- Default: #1E1E20 (dividers, card borders, sidebar border)
- Subtle: #161618 (inner separators)

**Speaker Colors** (muted pastels on dark, low saturation):
1. #8BB8E8 (soft blue)
2. #E8A87C (soft coral)
3. #82D9A5 (soft mint)
4. #C4A0E8 (soft lavender)
5. #E8D482 (soft gold)
6. #E88B9C (soft rose)

### Why

- Teal accent because: ElevenLabs vibrant feel, distinct from recording red, works well on dark backgrounds
- Red reserved for record only because: Creates clear visual hierarchy — red = "recording is happening"
- Muted pastels for speakers because: Readable on dark without competing with UI chrome; professional, not childish

### Related IDs

- [DES-001](#des-001-record-button) - Only user of recording red
- [DES-101](#des-101-speaker-label) - Uses speaker color array
- [DES-002](#des-002-audio-level-indicator) - Teal accent for bars
- [DES-305](#des-305-status-and-feedback-colors) - Extends this palette

---

## DES-302: Typography System

**ID**: DES-302
**Category**: Design Token
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Native macOS typography using SF Pro for UI and SF Mono for technical content. Transcript text respects macOS System Settings for text size accessibility.

### Specification

**Typefaces**:
- UI: SF Pro (system font) — all interface text, labels, buttons, navigation
- Mono: SF Mono — timestamps ([HH:MM:SS]), duration displays, technical metadata
- Transcript: SF Pro — transcript body text, user-adjustable size

**Size Scale** (base 14px):
- XS: 11px — badges, minor labels
- SM: 12px — sidebar secondary text, speaker labels
- Base: 14px — UI body, buttons, sidebar primary text
- MD: 16px — content headings, transcript default size
- LG: 20px — screen titles (rare, only processing stage)
- XL: 24px — empty state messaging

**Transcript Text**: Respects `NSFont.preferredFont(forTextStyle:)` mapped to macOS Dynamic Type. User controls size via System Settings > Accessibility > Display > Text Size. Default maps to MD (16px).

**Weights**:
- Regular (400): Body text, labels
- Medium (500): Speaker labels, sidebar items, buttons
- Semibold (600): Headings, emphasized content

### Why

SF Pro because: Native macOS feel — the app should feel like it belongs on the system, not a ported web app. Adjustable transcript size because: Users read long transcripts; accessibility matters.

### Related IDs

- [DES-003](#des-003-transcript-block) - Transcript text sizing
- [DES-004](#des-004-sidebar-transcript-list) - Sidebar text sizing
- [DES-101](#des-101-speaker-label) - Label text

---

## DES-303: Spacing and Sizing

**ID**: DES-303
**Category**: Design Token
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Spacing system with two modes: spacious (recording/processing) and dense (transcript review). Base unit of 4px.

### Specification

**Base Unit**: 4px
**Scale**: 4, 8, 12, 16, 24, 32, 48, 64

**Spacious Mode** (recording, processing, idle):
- Section padding: 48px
- Element gap: 24-32px
- Content max-width: 600px

**Dense Mode** (transcript view):
- Section padding: 16px
- Transcript block gap: 8px
- Content fills available width (no max-width)
- Sidebar item padding: 8px vertical, 12px horizontal

**Common**:
- Toolbar height: Standard macOS NSToolbar
- Sidebar width: 240px default
- Button padding: 8px vertical, 16px horizontal
- Pill padding: 4px vertical, 12px horizontal

### Related IDs

- [DES-201](#des-201-page-layout-system) - Layout dimensions
- [DES-203](#des-203-density-modes) - Density context

---

## DES-304: Borders and Elevation

**ID**: DES-304
**Category**: Design Token
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Follows macOS Human Interface Guidelines for native feel. Uses system-provided materials and vibrancy where appropriate.

### Specification

**Corners**: Follow macOS system radius (continuous corners, ~10px for cards/panels, ~6px for buttons, ~12px for pills)
**Elevation**: Use native macOS approaches:
- Toolbar: NSToolbar with system material background (automatic vibrancy)
- Sidebar: NSVisualEffectView with `.sidebar` material
- Sheets/Panels: System-provided sheet presentation (settings)
- Cards (permission prompt): Subtle 1px border (#1E1E20), no shadow on dark backgrounds
**Borders**: Thin (1px) using border colors from DES-301. Used for sidebar divider, transcript block separators.
**Vibrancy**: Sidebar uses macOS sidebar vibrancy material. Content area is opaque dark background.

### Why

macOS native because: User requested the app feel native. NSVisualEffectView and system materials ensure the app adapts to macOS appearance changes and accessibility settings.

### Related IDs

- [DES-005](#des-005-toolbar) - Native toolbar treatment
- [DES-004](#des-004-sidebar-transcript-list) - Sidebar vibrancy
- [DES-301](#des-301-color-palette) - Border colors

---

## DES-305: Status and Feedback Colors

**ID**: DES-305
**Category**: Design Token
**Status**: Active
**Platform**: macOS
**Created**: 2026-03-20
**Last Updated**: 2026-03-20

### Description

Standard status colors for pipeline feedback, errors, and confirmations. Red overlaps with recording red (DES-301) — this is intentional and acceptable since status errors and recording states never co-occur on the same screen.

### Specification

**Success**: #22C55E (green) — pipeline stage complete, export confirmed
**Warning**: #F59E0B (amber) — silence detected during recording, approaching duration limit
**Error**: #EF4444 (red) — pipeline failure, permission denied, sidecar crash
**Info**: #3B82F6 (blue) — general information, first-launch guidance
**Muted**: #52525B (gray) — disabled states, inactive elements

### Usage Context

- Success green: Checkmarks on completed pipeline stages (DES-102)
- Warning amber: Audio level indicator silence warning (DES-002), duration approaching limit
- Error red: Processing failure in DES-102 error state, permission denied in DES-103
- Info blue: Tooltip content, help text

### Related IDs

- [DES-301](#des-301-color-palette) - Base palette (extends)
- [DES-102](#des-102-progress-pipeline) - Uses success/error states
- [DES-002](#des-002-audio-level-indicator) - Uses warning for silence

---

## Deprecated Components

_No deprecated components._

---

## Cross-Reference Index

**Components by Screen**:

- SCR-001 uses: DES-001 (start), DES-002 (pre-record preview), DES-004, DES-005, DES-104
- SCR-002 uses: DES-105 (Notch HUD) OR DES-106 (Menu Bar Extra) — hardware-conditional; main window is hidden per BR-501
- SCR-003 uses: DES-004, DES-005, DES-102 (main window restored to host processing)
- SCR-004 uses: DES-003, DES-004, DES-005, DES-101
- SCR-005 uses: DES-004, DES-005 (settings as sheet overlay)
- SCR-006 uses: DES-004 (sidebar IS the history view)

**Components by Journey**:

- UJ-001 uses: DES-001 (start), DES-002 (pre-flight), DES-105/106 (recording), DES-102 (processing)
- UJ-002 uses: DES-003, DES-004, DES-101
- UJ-003 uses: DES-103 (first-launch permissions)

**Tokens by Component**:

- DES-001 uses: DES-301 (recording red)
- DES-002 uses: DES-301 (teal accent), DES-305 (warning amber)
- DES-003 uses: DES-302 (transcript typography), DES-303 (dense spacing)
- DES-004 uses: DES-301 (teal selection), DES-304 (sidebar vibrancy)
- DES-101 uses: DES-301 (speaker colors), DES-302 (label font)
- DES-102 uses: DES-305 (success/error states)
- DES-105 uses: DES-301 (recording red), DES-302 (label typography)
- DES-106 uses: DES-301 (recording red), DES-302 (label typography)

---

## Update Protocol

### When to Add New DES-XXX IDs

1. **New UI Component**: Distinct, reusable interface element
2. **Design Token Update**: New color, typography, or spacing token
3. **Layout Principle**: Structural decision about page organization
4. **Pattern Library Addition**: Recurring design solution

### Bidirectional Reference Checklist

When adding a new DES-XXX:

- [ ] Update SoT.USER_JOURNEYS.md "Design Components" section
- [ ] Update EPIC Section 2 "Context & IDs" list
- [ ] Create corresponding component file in codebase

---

*End of SoT.DESIGN_COMPONENTS.md - Authoritative source for all DES-XXX IDs*
