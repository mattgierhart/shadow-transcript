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
- [SCR-002](#scr-002-recording-hud) - Recording HUD (notch / menu bar)
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
**Last Updated**: 2026-04-24

### Purpose

Idle and post-recording surface. The main window is the entry point (select sources, start a recording) and the review surface (processing progress, transcript review, history). Per BR-501, the main window is **hidden during active recording**; control passes to the compact Recording HUD (SCR-002).

### Key Elements

- Record button (prominent, center — DES-001)
- Audio source selector (microphone + system audio toggle)
- Recent transcripts list (last 10)
- Settings gear icon
- Status indicator (idle / processing — recording state lives in the HUD)

### Visibility Rule

- **Shown**: app launch, pre-record, processing (SCR-003), transcript review (SCR-004), history browsing (SCR-006)
- **Hidden**: active recording (see SCR-002)
- On Stop from the HUD, the main window is restored and transitions directly to SCR-003.

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Entry point for recording
- [SCR-002](#scr-002-recording-hud) - Replaces this surface during recording
- [SCR-006](#scr-006-transcript-history) - Links to full history
- [DES-001](SoT.DESIGN_COMPONENTS.md#des-001-record-button) - Record button component
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Visibility rule source

---

## SCR-002: Recording HUD

**ID**: SCR-002
**Status**: Planned
**Created**: 2026-03-11
**Last Updated**: 2026-04-24

### Purpose

The **only** UI shown while recording. A compact, ambient surface with a single action (Stop). Designed to stay out of the user's way during a meeting — the user remains focused on Zoom/Meet/Teams in the foreground. Enforces BR-501 (Minimal Recording UI).

### Key Elements

- Recording indicator (red dot or pulse — non-interactive, confirms capture is active)
- Stop button (the only interactive control)
- No timer, waveform, pause, source toggle, or navigation on this surface — all of those require opening the main window (which is hidden during recording).

### Realizations (hardware-dependent)

| Realization | When | Surface | Design |
|---|---|---|---|
| **Notch HUD** (primary) | MacBook Pro 14"/16" with display notch (M1 Pro+, 2021+) and on a screen whose notch is visible | Floats around the hardware notch; expands on hover | [DES-201](SoT.DESIGN_COMPONENTS.md#des-201-recording-hud-notch) |
| **Menu Bar Extra** (fallback) | Any Mac without a visible notch: MacBook Air, older/Intel MBP, iMac, Mac mini/Studio, or an external display | NSStatusItem in the menu bar; click reveals popover containing Stop | [DES-202](SoT.DESIGN_COMPONENTS.md#des-202-recording-hud-menu-bar-extra) |

The HUD realization is selected automatically at recording start based on the screen hosting the app; the user does not choose. If the user drags the window to a display without a notch mid-session, the realization does not change during that recording.

### States

- **Appearing**: animates in as main window hides (on Record)
- **Active**: steady recording indicator + Stop affordance
- **Dismissing**: animates out as main window returns (on Stop)
- **Error** (e.g., mic permission revoked mid-session): briefly surfaces error, then auto-opens main window

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Steps 3–5
- [SCR-001](#scr-001-main-window) - Hidden while this is active
- [SCR-003](#scr-003-processing-view) - Replaces this on Stop
- [DES-201](SoT.DESIGN_COMPONENTS.md#des-201-recording-hud-notch) - Notch realization
- [DES-202](SoT.DESIGN_COMPONENTS.md#des-202-recording-hud-menu-bar-extra) - Menu bar fallback
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Enforces minimal UI
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Duration limit warning (surfaced via system notification, not HUD)
- [RISK-007 in PRD](../PRD.md) - Notch fragmentation risk

---

## SCR-003: Processing View

**ID**: SCR-003
**Status**: Planned
**Created**: 2026-03-11
**Last Updated**: 2026-04-24

### Purpose

Shows transcription and diarization progress after recording stops. Rendered inside the **restored main window** — the meeting is over, so the minimal-UI constraint no longer applies.

### Key Elements

- Progress bar (overall pipeline progress)
- Stage indicator (transcribing → diarizing → formatting)
- Estimated time remaining
- Cancel button

### Entry

- Arrives from SCR-002 Stop: HUD dismisses, main window restores directly into this view.

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Step 6
- [SCR-002](#scr-002-recording-hud) - Upstream surface
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

- **User Goal**: Record a meeting and get a speaker-labeled transcript, without the recorder getting in the way during the meeting
- **Trigger**: User has a meeting starting (or wants to record ongoing audio)
- **Success Criteria**:
  - Transcript with speaker labels and timestamps is generated locally
  - User's attention stays on the meeting app during recording; Transcript Shadow does not occupy meaningful screen real estate (BR-501)

### Steps

1. **Open App**: User launches Transcript Shadow → sees SCR-001 (Main Window) with the Record button and source selector.
2. **Select Audio Source**: User sets microphone and/or system audio. Selection persists across sessions (DBT-101).
3. **Start Recording**: User clicks Record.
   - Main window animates closed / hides.
   - SCR-002 Recording HUD appears: Notch realization (DES-201) if the active screen has a hardware notch; otherwise Menu Bar Extra realization (DES-202).
   - Temp WAV file opens for streaming write (BR-103, ARC-003).
4. **Recording Active**: User works in their meeting app (Zoom, Meet, Teams, etc.). The HUD shows only a recording indicator and a Stop affordance — no timer, waveform, or source controls on the HUD surface (BR-501). Opening the main window during recording is an explicit action (click app icon / notch expand); it does not auto-appear.
5. **Stop Recording**: User clicks Stop from the HUD.
   - HUD dismisses.
   - Capture stops, temp WAV is finalized, app brings the main window forward.
   - Main window opens directly into SCR-003 Processing View.
6. **Processing**: Audio is transcribed (WhisperKit, API-101) then diarized (pyannote sidecar, API-102), then formatted (API-201). Progress bar advances through stages.
7. **Transcript Ready**: Processing complete → transitions to SCR-004 (Transcript View) with speaker-labeled content. User may rename speakers (UJ-002).
8. **Audio Deleted**: Temp audio file is securely deleted (BR-103).

### Error Paths

- **No microphone permission**: On Record, macOS surfaces the permission dialog; app blocks recording until granted and guides user to System Settings.
- **Screen Recording permission missing (system audio enabled)**: App falls back to mic-only mode and inline-notifies via the main window; does not silently fail.
- **HUD permission revoked mid-session** (e.g., user disables mic in Control Center): HUD enters Error state, dismisses, and opens main window with a resumable recording prompt (audio captured up to that point is preserved for processing).
- **Processing fails**: Show error in SCR-003 with retry option; temp audio preserved until retry or explicit cancel.
- **App quit during recording**: Temp WAV is preserved on disk (ARC-003). On next launch, app detects orphaned temp audio and offers to process it or discard (per BR-103).

### Business Rules Enforced

- BR-101 Local-Only Processing
- BR-102 / BR-103 Temp audio lifecycle
- BR-402 Duration cap (surfaced as system notification at 110m, not on the HUD)
- **BR-501 Minimal Recording UI** (HUD-only during recording; main window hidden)

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker) - Primary persona
- [PER-002](#per-002-privacy-conscious-professional) - Secondary persona
- Screen flow: [SCR-001](#scr-001-main-window) → [SCR-002](#scr-002-recording-hud) → [SCR-003](#scr-003-processing-view) → [SCR-004](#scr-004-transcript-view)
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - All processing local
- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - Audio deleted after
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Deletion enforcement
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Duration limit
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - Minimal recording UI
- [DES-201](SoT.DESIGN_COMPONENTS.md#des-201-recording-hud-notch) - Notch HUD
- [DES-202](SoT.DESIGN_COMPONENTS.md#des-202-recording-hud-menu-bar-extra) - Menu bar fallback
- [FEA-001 in PRD](../PRD.md) - Audio capture
- [FEA-002 in PRD](../PRD.md) - Transcription
- [FEA-003 in PRD](../PRD.md) - Diarization
- [RISK-007 in PRD](../PRD.md) - Notch/hardware fragmentation

---

## UJ-002: Review and Export Transcript

**ID**: UJ-002
**Category**: Core
**Status**: Active
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Overview

- **User Goal**: Review a completed transcript, rename auto-labeled speakers to real names, and export to Obsidian.
- **Trigger**: Transcript processing completes (from UJ-001) or user opens a past transcript from SCR-006.
- **Success Criteria**: Transcript is saved as markdown in Obsidian vault with user-chosen speaker names consistently applied across every segment.

### Steps

1. **View Transcript**: User sees SCR-004 (Transcript View). Each turn is rendered as a DES-003 Transcript Block with a DES-101 Speaker Label chip on the left and the spoken text on the right. Each speaker has a distinct color from the DES-301 speaker palette.
2. **Rename Speakers**: User clicks any speaker chip in the transcript (or in a condensed speaker roster, if provided at the top of SCR-004).
   - Chip enters **Editing** state → inline text field focused, current name preselected.
   - User types a name (e.g., "Alice") and commits with Enter / blur / click outside.
   - **Propagation rule**: the new name replaces every occurrence of that auto-key (e.g., `SPEAKER_00`) across the entire transcript — every block, every roster entry, every exported reference — in a single update. User never renames speakers one block at a time.
   - Storage: `DBT-002.display_name` is updated; `speaker_key` and `color_index` are unchanged. Undo reverts to the immediately previous name (including back to the default "Speaker 1").
3. **Review Content**: User scrolls, verifies text and attribution. Segments at speaker turn boundaries may show a "not sure?" affordance tied to low-confidence alignment (RISK-005 mitigation).
4. **Export to Obsidian**: User clicks "Export to Obsidian" → API-202 writes the formatted markdown to the configured vault subfolder. Export uses the current `display_name` values (not `speaker_key`).
5. **Confirmation**: Success toast shown with the exported file path and a "Reveal in Finder" / "Open in Obsidian" action.

### Alternative Paths

- **Copy to clipboard**: User copies current markdown (with renamed speakers) to the clipboard instead of file export.
- **Save as file**: User saves to an arbitrary location via a file picker.
- **Open past transcript**: User enters SCR-004 from SCR-006 History; rename + re-export flow is identical. Re-exporting overwrites only if the user confirms (no silent overwrite of the vault file).
- **Revert a rename**: Clicking a renamed chip and clearing the field restores the auto-default ("Speaker 1", "Speaker 2", …).

### Error Paths

- **Vault path missing or unwritable**: Export button disabled with inline reason; link to SCR-005 settings.
- **Duplicate name entered for two speakers**: Allowed (e.g., two "Unknown" speakers) but user is warned inline — speakers remain distinct entities in `DBT-002` regardless of display name.
- **Empty name submitted**: Reverts to the auto-default for that `speaker_key`.

### Business Rules Enforced

- BR-301 Markdown output format
- BR-302 Obsidian vault compatibility

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker) - Primary persona
- [SCR-004](#scr-004-transcript-view) - Primary screen
- [SCR-006](#scr-006-transcript-history) - Entry from history
- [DES-003](SoT.DESIGN_COMPONENTS.md#des-003-transcript-block) - Transcript block component
- [DES-101](SoT.DESIGN_COMPONENTS.md#des-101-speaker-label) - Speaker chip component (the rename surface)
- [DES-301](SoT.DESIGN_COMPONENTS.md#des-301-color-system) - Speaker color palette
- [API-201](SoT.API_CONTRACTS.md#api-201-transcript-formatter) - Formatter accepts `speakerNames` override map
- [API-202](SoT.API_CONTRACTS.md#api-202-obsidian-exporter) - Exports current display names
- [DBT-002](SoT.DATA_MODEL.md#dbt-002-speakers) - `display_name` persists rename
- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format) - Output format
- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Obsidian compatibility
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Obsidian export
- [FEA-003 in PRD](../PRD.md) - Diarization (produces auto-keys this journey renames)
- [FEA-004 in PRD](../PRD.md) - Markdown output
- [FEA-005 in PRD](../PRD.md) - Obsidian export
- [RISK-005 in PRD](../PRD.md) - Alignment accuracy (source of manual correction need)

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

- SCR-001 appears in: UJ-001 (step 1, restored at step 5), UJ-003
- SCR-002 appears in: UJ-001 (steps 3–5) — main window is hidden while SCR-002 is active
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
