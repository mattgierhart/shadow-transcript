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

**Design Tokens** (DES-301 to DES-399):

- [DES-301](#des-301-color-system) - Color System

---

## DES-001: Record Button

**ID**: DES-001
**Category**: Core
**Status**: Planned
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Primary action button for starting/stopping audio recording. Large, centered, with clear state changes. Inspired by ElevenLabs UI audio controls — minimal, dark theme, high contrast accent.

### Specifications

**Dimensions**: 64px circular (idle), 56px rounded-square (recording)
**Variants**: Idle (red circle), Recording (red square, pulsing), Disabled (gray)
**States**: idle → recording → processing (transitions to progress view)

### Related IDs

- [SCR-001](SoT.USER_JOURNEYS.md#scr-001-main-window) - Main window placement
- [SCR-002](SoT.USER_JOURNEYS.md#scr-002-recording-view) - Recording state
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Step 3

---

## DES-002: Audio Level Indicator

**ID**: DES-002
**Category**: Core
**Status**: Planned
**Platform**: macOS
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Real-time audio waveform or level meter showing input volume during recording. Provides visual confirmation that audio is being captured.

### Specifications

**Dimensions**: Full-width, 48px height
**Variants**: Waveform (animated bars), Simple (single level bar)
**States**: Active (during recording), Silent (no input detected — warning color)

### Related IDs

- [SCR-002](SoT.USER_JOURNEYS.md#scr-002-recording-view) - Recording view
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Step 4

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

- SCR-001 uses: DES-001
- SCR-002 uses: DES-001, DES-002
- SCR-003 uses: DES-102
- SCR-004 uses: DES-003, DES-101

**Components by Journey**:

- UJ-001 uses: DES-001, DES-002, DES-102
- UJ-002 uses: DES-003, DES-101

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
