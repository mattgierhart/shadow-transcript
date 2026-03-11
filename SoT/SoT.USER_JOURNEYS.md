---
version: 1.0
purpose: Source of Truth for user journeys, personas, and screen flows.
id_prefix: UJ-XXX, PER-XXX, SCR-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by PRD.md, EPICs, and other SoT files
---

# User Journeys (SoT File)

> **Purpose**: User flows, personas, and screen definitions for Transcript Shadow.
> **ID Prefixes**: UJ-XXX (journeys), PER-XXX (personas), SCR-XXX (screens)
> **Status**: Active SoT file
> **Cross-References**: Referenced by PRD.md, SoT.API_CONTRACTS.md, SoT.TESTING.md, EPICs

## Navigation by Category

**Personas** (PER-001 to PER-099):

- [PER-001](#per-001-solo-knowledge-worker) - Solo Knowledge Worker
- [PER-002](#per-002-privacy-conscious-professional) - Privacy-Conscious Professional

**Screens** (SCR-001 to SCR-099):

- [SCR-001](#scr-001-main-window) - Main Window
- [SCR-002](#scr-002-recording-view) - Recording View
- [SCR-003](#scr-003-processing-view) - Processing View
- [SCR-004](#scr-004-transcript-view) - Transcript View
- [SCR-005](#scr-005-settings-view) - Settings View
- [SCR-006](#scr-006-transcript-history) - Transcript History

**Core Journeys** (UJ-001 to UJ-099):

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Record and Transcribe Meeting
- [UJ-002](#uj-002-review-and-export-transcript) - Review and Export Transcript
- [UJ-003](#uj-003-configure-app-settings) - Configure App Settings

---

## PER-001: Solo Knowledge Worker

**ID**: PER-001
**Status**: Active
**Created**: 2026-03-11

### Profile

- **Role**: Individual contributor (engineer, PM, designer, consultant) who attends 3-8 meetings/day
- **Goals**: Capture meeting content without manual note-taking; searchable meeting history in Obsidian
- **Pain Points**: Loses context from meetings; manual notes are incomplete; existing tools require cloud upload
- **Tech Comfort**: High — comfortable with Obsidian, markdown, macOS power-user features

### Behavioral Signals

- Uses Obsidian as primary knowledge base
- Values local-first tools and data ownership
- Willing to trade some convenience for privacy
- Wants "set and forget" recording workflow

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Primary journey
- [UJ-002](#uj-002-review-and-export-transcript) - Secondary journey
- [CFD-002](SoT.customer_feedback.md#cfd-002-no-local-first-transcription-with-diarization) - driven-by
- [CFD-003](SoT.customer_feedback.md#cfd-003-obsidian-users-want-native-meeting-notes) - driven-by

---

## PER-002: Privacy-Conscious Professional

**ID**: PER-002
**Status**: Active
**Created**: 2026-03-11

### Profile

- **Role**: Professional in regulated or sensitive field (legal, medical, executive, HR)
- **Goals**: Document meetings for compliance/reference without exposing content to third parties
- **Pain Points**: Cannot use cloud transcription due to confidentiality requirements; manual transcription is expensive
- **Tech Comfort**: Medium — comfortable with desktop apps, may not be an Obsidian user initially

### Behavioral Signals

- Works with confidential or privileged information
- Compliance requirements prohibit cloud processing of meeting content
- Willing to pay for tools that guarantee data stays local
- May use markdown export to other tools beyond Obsidian

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Primary journey
- [CFD-001](SoT.customer_feedback.md#cfd-001-cloud-meeting-tools-force-privacy-tradeoffs) - driven-by
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - critical requirement

---

## SCR-001: Main Window

**ID**: SCR-001
**Status**: Planned
**Created**: 2026-03-11

### Purpose

Primary app window. Shows recording controls and recent transcript history. Minimal, focused interface.

### Key Elements

- Record button (prominent, center)
- Audio source selector (microphone + system audio toggle)
- Recent transcripts list (last 10)
- Settings gear icon
- Status indicator (idle / recording / processing)

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Entry point for recording
- [SCR-006](#scr-006-transcript-history) - Links to full history
- [DES-001](SoT.DESIGN_COMPONENTS.md#des-001-record-button) - Record button component

---

## SCR-002: Recording View

**ID**: SCR-002
**Status**: Planned
**Created**: 2026-03-11

### Purpose

Active recording state. Shows real-time audio level, elapsed time, and stop control.

### Key Elements

- Audio waveform / level meter
- Elapsed time counter
- Stop button
- Audio source indicator (mic / system / both)
- Pause button (optional MVP, may defer)

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Step 3-4
- [DES-002](SoT.DESIGN_COMPONENTS.md#des-002-audio-level-indicator) - Waveform component
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Duration limit warning

---

## SCR-003: Processing View

**ID**: SCR-003
**Status**: Planned
**Created**: 2026-03-11

### Purpose

Shows transcription and diarization progress after recording stops.

### Key Elements

- Progress bar (overall pipeline progress)
- Stage indicator (transcribing → diarizing → formatting)
- Estimated time remaining
- Cancel button

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Step 5
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Audio deleted after this

---

## SCR-004: Transcript View

**ID**: SCR-004
**Status**: Planned
**Created**: 2026-03-11

### Purpose

Display completed transcript with speaker labels and timestamps. Allows review and editing before export.

### Key Elements

- Speaker-labeled transcript with timestamps
- Speaker name editing (rename "Speaker 1" → "Alice")
- Copy to clipboard button
- Export to Obsidian button
- Save as markdown button (generic file save)
- Transcript metadata header (date, duration, speaker count)

### Related IDs

- [UJ-002](#uj-002-review-and-export-transcript) - Primary journey for this screen
- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format) - Output format
- [DES-003](SoT.DESIGN_COMPONENTS.md#des-003-transcript-block) - Transcript display component

---

## SCR-005: Settings View

**ID**: SCR-005
**Status**: Planned
**Created**: 2026-03-11

### Purpose

App configuration: audio sources, Obsidian vault path, model selection, output preferences.

### Key Elements

- Audio input device selector
- System audio capture toggle (requires ScreenCaptureKit permission)
- Obsidian vault path picker (folder selector)
- Whisper model size selector (tiny/base/small/medium)
- Output template customization (frontmatter fields)
- Auto-delete audio toggle (always on, shown for transparency)

### Related IDs

- [UJ-003](#uj-003-configure-app-settings) - Settings journey
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Vault path config
- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - Audio deletion setting

---

## SCR-006: Transcript History

**ID**: SCR-006
**Status**: Planned
**Created**: 2026-03-11

### Purpose

Browse and search past transcripts stored locally.

### Key Elements

- List of past transcripts (date, title, duration, speaker count)
- Search/filter bar
- Quick actions (open, export, delete)
- Sort options (date, duration)

### Related IDs

- [UJ-002](#uj-002-review-and-export-transcript) - Access past transcripts
- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts) - Transcript data store

---

## UJ-001: Record and Transcribe Meeting

**ID**: UJ-001
**Category**: Core
**Status**: Active
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Overview

- **User Goal**: Record a meeting and get a speaker-labeled transcript
- **Trigger**: User has a meeting starting (or wants to record ongoing audio)
- **Success Criteria**: Transcript with speaker labels and timestamps is generated locally

### Steps

1. **Open App**: User launches Transcript Shadow → sees SCR-001 (Main Window)
2. **Select Audio Source**: User selects microphone and/or system audio → source indicator updates
3. **Start Recording**: User clicks Record → transitions to SCR-002 (Recording View)
4. **Recording Active**: Audio captured in real-time, waveform shows levels, timer counts up
5. **Stop Recording**: User clicks Stop → transitions to SCR-003 (Processing View)
6. **Processing**: Audio is transcribed (Whisper) then diarized → progress bar advances
7. **Transcript Ready**: Processing complete → transitions to SCR-004 (Transcript View)
8. **Audio Deleted**: Temp audio file is securely deleted (BR-103)

### Error Paths

- **No microphone permission**: Show macOS permission dialog, guide user to System Settings
- **Processing fails**: Show error with retry option; temp audio preserved until retry or explicit cancel
- **App quit during recording**: Audio saved to temp, processing can resume on next launch (or auto-delete per BR-103)

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker) - Primary persona
- [PER-002](#per-002-privacy-conscious-professional) - Secondary persona
- [SCR-001](#scr-001-main-window) → [SCR-002](#scr-002-recording-view) → [SCR-003](#scr-003-processing-view) → [SCR-004](#scr-004-transcript-view) - Screen flow
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - All processing local
- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - Audio deleted after
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Deletion enforcement
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Duration limit
- [FEA-001 in PRD](../PRD.md) - Audio capture
- [FEA-002 in PRD](../PRD.md) - Transcription
- [FEA-003 in PRD](../PRD.md) - Diarization

---

## UJ-002: Review and Export Transcript

**ID**: UJ-002
**Category**: Core
**Status**: Active
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Overview

- **User Goal**: Review a completed transcript, rename speakers, and export to Obsidian
- **Trigger**: Transcript processing completes (from UJ-001) or user opens past transcript
- **Success Criteria**: Transcript is saved as markdown in Obsidian vault with correct speaker names

### Steps

1. **View Transcript**: User sees SCR-004 (Transcript View) with speaker-labeled content
2. **Rename Speakers**: User clicks speaker labels to rename (e.g., "Speaker 1" → "Alice")
3. **Review Content**: User scrolls through transcript, verifying content
4. **Export to Obsidian**: User clicks "Export to Obsidian" → file saved to configured vault path
5. **Confirmation**: Success toast shown with file path; transcript appears in Obsidian

### Alternative Paths

- **Copy to clipboard**: User copies markdown to clipboard instead of file export
- **Save as file**: User saves to arbitrary location via file picker
- **Open past transcript**: User accesses from SCR-006 (History) instead of fresh processing

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker) - Primary persona
- [SCR-004](#scr-004-transcript-view) - Primary screen
- [SCR-006](#scr-006-transcript-history) - Entry from history
- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format) - Output format
- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Obsidian compatibility
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Obsidian export
- [FEA-004 in PRD](../PRD.md) - Markdown output
- [FEA-005 in PRD](../PRD.md) - Obsidian export

---

## UJ-003: Configure App Settings

**ID**: UJ-003
**Category**: Core
**Status**: Active
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Overview

- **User Goal**: Configure audio sources, Obsidian vault path, and transcription preferences
- **Trigger**: First launch (onboarding) or user wants to change settings
- **Success Criteria**: Settings saved and applied to subsequent recordings

### Steps

1. **Open Settings**: User clicks gear icon → SCR-005 (Settings View)
2. **Select Audio Input**: User picks microphone device from dropdown
3. **Enable System Audio**: User toggles system audio capture (grants ScreenCaptureKit permission if needed)
4. **Set Obsidian Vault**: User picks vault folder via file picker
5. **Choose Model Size**: User selects Whisper model (tiny/base/small/medium) with size/speed tradeoff shown
6. **Save**: Settings auto-save on change

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker) - Primary persona
- [SCR-005](#scr-005-settings-view) - Settings screen
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Vault path configuration

---

## Deprecated Entries

_No deprecated entries._

---

## Cross-Reference Index

**Journeys by Persona**:

- PER-001 uses: UJ-001, UJ-002, UJ-003
- PER-002 uses: UJ-001, UJ-002

**Journeys by Screen**:

- SCR-001 appears in: UJ-001 (step 1)
- SCR-002 appears in: UJ-001 (steps 3-4)
- SCR-003 appears in: UJ-001 (step 6)
- SCR-004 appears in: UJ-001 (step 7), UJ-002 (step 1)
- SCR-005 appears in: UJ-003
- SCR-006 appears in: UJ-002 (alternative)

---

## Update Protocol

### When to Add New IDs

1. **PER-XXX**: New user segment or persona identified
2. **SCR-XXX**: New screen or significant screen redesign
3. **UJ-XXX**: New user flow from trigger to goal completion

### Bidirectional Reference Checklist

When adding a new UJ/PER/SCR-XXX:

- [ ] Update SoT.API_CONTRACTS.md for APIs used
- [ ] Update SoT.BUSINESS_RULES.md for rules enforced
- [ ] Update SoT.DESIGN_COMPONENTS.md for UI components
- [ ] Update SoT.TESTING.md with validation tests
- [ ] Update EPIC Section 2 "Context & IDs" list

---

*End of SoT.USER_JOURNEYS.md - Authoritative source for UJ-XXX, PER-XXX, SCR-XXX IDs*
