---
version: 2.1
purpose: Source of Truth for user journeys, personas, and screen flows.
id_prefix: UJ-XXX, PER-XXX, SCR-XXX
last_updated: 2026-05-16
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

- [SCR-001](#scr-001-main-window-idle) - Main Window (Idle / Pre-Record)
- [SCR-002](#scr-002-recording-hud) - Recording HUD (Notch or Menu Bar Extra)
- [SCR-003](#scr-003-processing-view) - Processing View (Main Window Restored)
- [SCR-004](#scr-004-transcript-view) - Transcript View
- [SCR-005](#scr-005-settings-sheet) - Settings Sheet
- [SCR-006](#scr-006-transcript-history-sidebar) - Transcript History (Sidebar)

**Core Journeys** (UJ-001 to UJ-099):

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Record and Transcribe Meeting
- [UJ-002](#uj-002-review-and-export-transcript) - Review and Export Transcript
- [UJ-003](#uj-003-configure-app-settings) - Configure App Settings

**Feature-to-Screen Matrix**:

| Feature | SCR-001 | SCR-002 | SCR-003 | SCR-004 | SCR-005 | SCR-006 |
|---------|---------|---------|---------|---------|---------|---------|
| FEA-001 (Audio Capture) | Start | Active | | | Config | |
| FEA-002 (Transcription) | | | Active | | Config (model) | |
| FEA-003 (Diarization) | | | Active | Display | | |
| FEA-004 (Markdown Output) | | | | Display | | |
| FEA-005 (Obsidian Export) | | | | Action | Config (path) | |
| FEA-006 (Transcript History) | | | | | | Display |

---

## PER-001: Solo Knowledge Worker

**ID**: PER-001
**Type**: Primary
**Status**: Active
**Confidence**: 3/5 (source: CFD-002, CFD-003 pain point validation)
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Profile

- **Role**: Individual contributor (engineer, PM, designer, consultant) who attends 3-8 meetings/day
- **Context**: Uses macOS + Obsidian as daily driver. Meetings are on Zoom/Teams/Meet.
- **Technical Level**: High — comfortable with Obsidian, markdown, macOS power-user features
- **Goals**: Capture meeting content without manual note-taking; searchable meeting history in Obsidian (CFD-002, CFD-003)
- **Frustrations**: Loses context from meetings; manual notes are incomplete; existing tools require cloud upload (CFD-002)
- **Decision Factors**: Privacy > convenience; local-first > cloud features; simplicity > configurability
- **Current Workflow**: Manual notes during meeting → paste into Obsidian → lose detail

### Behavioral Signals

- Uses Obsidian as primary knowledge base
- Values local-first tools and data ownership
- Willing to trade some convenience for privacy
- Wants "set and forget" recording workflow — hit record, forget about it, review later

### Product Relationship

- **Primary Value**: CFD-102 ("Local processing eliminates privacy anxiety")
- **Key Features**: FEA-001 (capture), FEA-002 (transcription), FEA-003 (diarization), FEA-005 (Obsidian export)
- **Marketing Hook**: "Record. Transcribe. It's already in Obsidian."

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Primary journey
- [UJ-002](#uj-002-review-and-export-transcript) - Secondary journey
- [CFD-002](SoT.customer_feedback.md#cfd-002-no-local-first-transcription-with-diarization) - driven-by
- [CFD-003](SoT.customer_feedback.md#cfd-003-obsidian-users-want-native-meeting-notes) - driven-by

---

## PER-002: Privacy-Conscious Professional

**ID**: PER-002
**Type**: Secondary
**Status**: Active
**Confidence**: 2/5 (source: CFD-001 pain point; no direct interview validation)
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Profile

- **Role**: Professional in regulated or sensitive field (legal, medical, executive, HR)
- **Context**: Meetings contain confidential or privileged information. Company policy or regulation prohibits cloud processing.
- **Technical Level**: Medium — comfortable with desktop apps, may not be an Obsidian user initially
- **Goals**: Document meetings for compliance/reference without exposing content to third parties (CFD-001)
- **Frustrations**: Cannot use cloud transcription due to confidentiality requirements; manual transcription is expensive (CFD-001)
- **Decision Factors**: Compliance first; willing to pay; needs confidence that data stays local
- **Current Workflow**: No transcription (too risky), or expensive manual service

### Behavioral Signals

- Works with confidential or privileged information
- Compliance requirements prohibit cloud processing of meeting content
- Willing to pay for tools that guarantee data stays local
- May use markdown export to other tools beyond Obsidian
- Needs explicit reassurance that nothing leaves the machine

### Product Relationship

- **Primary Value**: CFD-101 ("Local processing eliminates privacy anxiety")
- **Key Features**: FEA-001 (capture), FEA-002 (transcription), FEA-004 (markdown output — portable, not locked to Obsidian)
- **Marketing Hook**: "Your meetings. Your machine. No exceptions."

### Related IDs

- [UJ-001](#uj-001-record-and-transcribe-meeting) - Primary journey
- [CFD-001](SoT.customer_feedback.md#cfd-001-cloud-meeting-tools-force-privacy-tradeoffs) - driven-by
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - critical requirement

---

## SCR-001: Main Window (Idle)

**ID**: SCR-001
**Type**: Page (content area state)
**Status**: Implemented (2026-05-17, EPIC-07)
**Confidence**: 3/5 (source: journey-mapping + design-interview)
**Created**: 2026-03-11
**Last Updated**: 2026-05-16

### Purpose

The main window of the app. Visible **before** recording (pre-flight surface — pick sources, review history, hit Record) and **after** recording (host for SCR-003 processing and SCR-004 transcript view). Per BR-501, this window is **hidden while recording is active**; only the Recording HUD (SCR-002, realized as DES-105 or DES-106) is visible during the meeting.

### Journeys

- [UJ-001](#uj-001-record-and-transcribe-meeting) — Step 1 (pre-record entry point); also restored at Step 6 (post-Stop)
- [UJ-002](#uj-002-review-and-export-transcript) — Entry surface via sidebar
- [UJ-003](#uj-003-configure-app-settings) — First-launch host

### Features

- FEA-001 (Audio Capture) — Pre-flight: source toggles + pre-record level preview; **Start recording** action

### Primary Actions

- **Record**: Click DES-001 → main window hides + Recording HUD (SCR-002) appears (per BR-501)
- **Open Transcript**: Click item in sidebar (DES-004) → loads SCR-004 in content area

### Secondary Actions

- **Settings**: Click gear in toolbar (DES-005) → opens SCR-005 as sheet
- **Search History**: Focus search in sidebar → filter transcript list

### Navigation

- **From**: App launch; restored from SCR-002 on Stop → SCR-003 in content area; return from SCR-004 (close transcript)
- **To**: SCR-002 (click Record — main window hides), SCR-004 (click sidebar item), SCR-005 (settings gear)

### Content

- Record button (DES-001) centered in content area — large, prominent, **start only**
- Audio source indicator + toggles directly above the button: Microphone (always on) + System Audio (toggle, requires Screen Recording permission)
- Pre-record audio level preview (DES-002) immediately beneath the source toggles — confirms inputs are live before recording starts
- Brief status text: "Ready to record" or "Last recording: [title] [time ago]"
- If first launch with no permissions: DES-103 permission prompt replaces record button area
- If no transcripts exist: DES-104 empty state in both sidebar and content

### Density Mode

**Spacious** (DES-203) — Content max-width 600px, centered. Generous whitespace. The user is about to start a meeting — don't overwhelm.

### Constraints

- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - No network indicator needed (everything is local)
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Duration limit info available via tooltip on record button
- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - This window hides on Record; only SCR-002 (HUD) is visible while recording

### Design Components

- [DES-001](SoT.DESIGN_COMPONENTS.md#des-001-record-button) - Record button (start only, no Stop state lives here)
- [DES-002](SoT.DESIGN_COMPONENTS.md#des-002-audio-level-preview) - Pre-record level preview (only place this appears)
- [DES-004](SoT.DESIGN_COMPONENTS.md#des-004-sidebar-transcript-list) - Sidebar (always visible on this window)
- [DES-005](SoT.DESIGN_COMPONENTS.md#des-005-toolbar) - Toolbar (idle state)
- [DES-103](SoT.DESIGN_COMPONENTS.md#des-103-permission-prompt) - First-launch only
- [DES-104](SoT.DESIGN_COMPONENTS.md#des-104-empty-state) - No transcripts state

### Design Notes

- PER-001 wants "set and forget" — the idle state should communicate readiness, not complexity
- PER-002 may need explicit "All processing stays on your Mac" reassurance text (first-launch only)
- The level preview (DES-002) is a **pre-flight check** — it disappears with the window once Record is clicked

---

## SCR-002: Recording HUD

**ID**: SCR-002
**Type**: HUD (not a content-area state — its own window-level surface)
**Status**: Implemented (2026-05-17, EPIC-07 — DES-105 + DES-106 peers)
**Confidence**: 3/5 (source: journey-mapping + design-interview + BR-501)
**Created**: 2026-03-11
**Last Updated**: 2026-05-16

### Purpose

The single permitted recording surface. Per BR-501, the app's main window (SCR-001) is hidden the moment recording starts; SCR-002 is the only app-owned UI visible until Stop. Realized as one of two peer surfaces based on hardware:

- **DES-105 — Notch HUD** (primary on notch-equipped MacBook Pros, 2021+)
- **DES-106 — Menu Bar Extra** (peer realization on non-notch Macs; promoted to primary if DES-105 cannot stay above fullscreen meeting apps per RISK-008)

Both surfaces are designed as **peers, not primary/degraded** — feature parity is mandatory.

### Journeys

- [UJ-001](#uj-001-record-and-transcribe-meeting) — Steps 4-5 (recording active → Stop)

### Features

- FEA-001 (Audio Capture) — Active capture happens beneath this surface; the HUD only exposes Stop

### Primary Actions

- **Stop**: Click Stop on the HUD (or invoke the global hotkey) → HUD dismisses + main window restores into SCR-003 (Processing View)

### Secondary Actions

- *None.* Per BR-501, this is the only action available on the HUD. Source toggles, settings, history navigation, and pause/resume all require the user to explicitly re-open the main window (clicking the app icon).

### Navigation

- **From**: SCR-001 (Record clicked → main window hides → HUD appears)
- **To**: SCR-003 (Stop clicked or hotkey → HUD dismisses → main window restores to processing view)
- **User-initiated open of main window during recording**: explicit click on app icon shows main window with recording continuing in background; HUD remains visible. Closing the main window returns to HUD-only state.

### Content

The HUD's content is hardware-conditional but exposes the **same elements** in either realization:

- A small red dot (recording active indicator) with 1Hz opacity oscillation (DES-301 recording red)
- A "Recording" label (SF Pro Medium, DES-302)
- A **Stop** button — the only interactive element
- Nothing else. No timer. No audio waveform. No source toggle. No pause/resume. No settings gear. No sidebar.

### Density Mode

Not a content-area screen — the HUD is a separate window surface at `.statusBar + 1` (DES-105) or in the system menu bar (DES-106). The density-mode taxonomy from DES-203 does not apply.

### Constraints

- [BR-501](SoT.BUSINESS_RULES.md#br-501-minimal-recording-ui) - **Single-action constraint** — no other UI may live on this surface
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Approaching-limit warning is delivered as a macOS notification (`UNUserNotificationCenter`), NOT as HUD content
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - No upload indicator needed

### Design Components

- [DES-105](SoT.DESIGN_COMPONENTS.md#des-105-recording-hud-notch) - Notch realization
- [DES-106](SoT.DESIGN_COMPONENTS.md#des-106-recording-hud-menu-bar-extra) - Menu Bar Extra realization

### Design Notes

- The HUD is **ambient**: the user is in a meeting, looking at Zoom/Teams/Meet. The HUD must confirm "still recording" at a glance and accept a single Stop action.
- The red-dot oscillation is the liveness signal. No timer or waveform — those would invite glancing at the HUD instead of attending the meeting.
- **Error states**: if mic permission is revoked mid-session or the capture pipeline crashes, the HUD briefly surfaces an error state (red dot turns amber + "Error" label) for ~2s, then dismisses while the main window is restored to handle recovery.

---

## SCR-003: Processing View

**ID**: SCR-003
**Type**: Page (content area state on the restored main window)
**Status**: Implemented (2026-05-17, EPIC-07)
**Confidence**: 3/5 (source: journey-mapping + design-interview)
**Created**: 2026-03-11
**Last Updated**: 2026-05-16

### Purpose

Shows transcription and diarization progress after recording stops. This is the **restored main window** — once Stop is hit on the HUD (SCR-002), the HUD dismisses and SCR-001's window comes back to host this view. A brief interlude — the user just finished their call and is transitioning from "meeting mode" to "review mode."

### Journeys

- [UJ-001](#uj-001-record-and-transcribe-meeting) — Steps 6-9 (HUD dismisses → main window restores → processing → transcript ready)

### Features

- FEA-002 (Transcription) — WhisperKit processing
- FEA-003 (Diarization) — pyannote sidecar processing

### Primary Actions

- **Wait**: Processing completes automatically → transitions to SCR-004
- **Cancel**: Cancel button → deletes temp audio (BR-103), returns to SCR-001

### Secondary Actions

- **Open Past Transcript**: Click sidebar item → opens in SCR-004 (processing continues)

### Navigation

- **From**: SCR-002 (Stop clicked on HUD → HUD dismisses → main window restores → this view appears)
- **To**: SCR-004 (processing complete, automatic), SCR-001 (cancel)

### Content

- Pipeline progress (DES-102) — three stages: Transcribing → Identifying Speakers → Formatting
- Estimated time remaining — below pipeline, muted text
- Cancel button — bottom, muted/secondary style (not prominent — cancellation discards audio per BR-103)
- Sidebar remains accessible (DES-004)

### Density Mode

**Spacious** (DES-203) — Content max-width 600px, centered. Same spacious feel as recording. The pipeline progress is the single focus. Generous padding.

### Constraints

- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - If cancelled, temp audio is deleted. Show confirmation: "Cancel will delete the recording. This can't be undone."
- [RISK-001 in PRD](../PRD.md) - Processing may take several minutes for long recordings. Show realistic time estimate.

### Design Components

- [DES-102](SoT.DESIGN_COMPONENTS.md#des-102-progress-pipeline) - Pipeline stages
- [DES-004](SoT.DESIGN_COMPONENTS.md#des-004-sidebar-transcript-list) - Sidebar
- [DES-005](SoT.DESIGN_COMPONENTS.md#des-005-toolbar) - Processing state

### Design Notes

- Transition from spacious (processing) → dense (transcript) should be animated smoothly — content area widens, spacing tightens
- If processing fails, show error state in DES-102 with retry button. Do NOT auto-delete audio on failure — preserve for retry.

---

## SCR-004: Transcript View

**ID**: SCR-004
**Type**: Page (content area state)
**Status**: Implemented (2026-05-17, EPIC-07)
**Confidence**: 3/5 (source: journey-mapping + design-interview)
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Purpose

Display completed transcript with speaker labels and timestamps. The user is focused — the call is over, they're reviewing and exporting. This is the "money shot" screen — where core product value is delivered.

### Journeys

- [UJ-001](#uj-001-record-and-transcribe-meeting) — Step 7 (transcript ready)
- [UJ-002](#uj-002-review-and-export-transcript) — Steps 1-5 (review, rename, export)

### Features

- FEA-003 (Diarization) — Speaker labels displayed
- FEA-004 (Markdown Output) — Formatted transcript rendered
- FEA-005 (Obsidian Export) — Export action button

### Primary Actions

- **Export to Obsidian**: Toolbar button → writes to vault (API-202) → success toast with file path
- **Rename Speaker**: Click speaker label pill (DES-101) → inline edit → propagates through transcript

### Secondary Actions

- **Copy to Clipboard**: Toolbar button → copies markdown to clipboard
- **Save As File**: Toolbar button → macOS save dialog
- **Open in Obsidian**: After export, "Open in Obsidian" link in success toast

### Navigation

- **From**: SCR-003 (processing complete, automatic), SCR-006/sidebar (click past transcript)
- **To**: SCR-001 (close transcript / start new recording), SCR-005 (settings)

### Content

- **Metadata header**: Date, duration, speaker count, model used — compact row at top
- **Speaker summary**: Horizontal row of speaker pills (DES-101) with speaking time — allows rename before scrolling
- **Transcript body**: Scrollable list of transcript blocks (DES-003) — speaker label, timestamp, text per turn
- **Action bar**: Export to Obsidian (primary teal button), Copy, Save As (secondary buttons)
- Sidebar shows this transcript as selected (DES-004)

### Density Mode

**Dense** (DES-203) — Content fills available width. Tight line spacing (1.4-1.5). Compact padding between blocks (8-12px). The user is reading — maximize content, minimize chrome.

### Constraints

- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format) - Transcript displayed as rendered markdown
- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Export produces valid frontmatter
- [DES-302](SoT.DESIGN_COMPONENTS.md#des-302-typography-system) - Transcript text size respects macOS accessibility settings

### Design Components

- [DES-003](SoT.DESIGN_COMPONENTS.md#des-003-transcript-block) - Transcript turn blocks
- [DES-101](SoT.DESIGN_COMPONENTS.md#des-101-speaker-label) - Speaker name pills
- [DES-004](SoT.DESIGN_COMPONENTS.md#des-004-sidebar-transcript-list) - Sidebar (transcript selected)
- [DES-005](SoT.DESIGN_COMPONENTS.md#des-005-toolbar) - Action buttons

### Design Notes

- **Money Shot**: This screen communicates core product value. A clean, well-formatted, speaker-labeled transcript with one-click Obsidian export.
- PER-001 will spend 1-3 minutes here: scan speakers, rename if needed, export, done
- PER-002 may spend longer reviewing for accuracy — adjustable text size is critical
- Speaker rename must be instant and propagate visually through the entire transcript

---

## SCR-005: Settings Sheet

**ID**: SCR-005
**Type**: Sheet (overlay)
**Status**: Implemented (2026-05-17, EPIC-07)
**Confidence**: 3/5 (source: journey-mapping + design-interview)
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Purpose

App configuration. Opens as a macOS sheet overlay (not a separate window), accessible via Cmd+, or toolbar gear icon. Settings auto-save on change.

### Journeys

- [UJ-003](#uj-003-configure-app-settings) — All steps

### Features

- FEA-001 (Audio Capture) — Audio input configuration
- FEA-002 (Transcription) — Model selection
- FEA-005 (Obsidian Export) — Vault path configuration

### Primary Actions

- **Close**: Dismiss sheet (Escape or close button) → returns to previous content state

### Secondary Actions

- **Grant Permissions**: Button to open macOS System Settings for mic/screen recording permissions
- **Download Model**: Trigger download of larger Whisper model

### Navigation

- **From**: Any screen via Cmd+, or toolbar gear
- **To**: Returns to previous content state on close

### Content

**Section: Audio**
- Audio input device selector (dropdown, system devices)
- System audio capture toggle (with permission status indicator)
- "Grant Permission" button if Screen Recording not yet authorized

**Section: Transcription**
- Whisper model size selector (base.en / small.en / medium.en)
- Model size + speed tradeoff shown inline (e.g., "base.en — 148MB, fastest")
- Download progress for models not yet cached

**Section: Export**
- Obsidian vault path picker (folder browser dialog)
- Subfolder name field (default: "Meetings")
- Auto-export toggle (export automatically after processing)

**Section: Privacy** (for PER-002 reassurance)
- "All audio processing happens locally on your Mac"
- "Temporary audio files are deleted after processing"
- Audio auto-delete indicator (always on, shown for transparency, not toggleable — per BR-102)

### Density Mode

**Spacious** — Content max-width 560px, centered in sheet. Standard macOS settings sheet feel. Not dense.

### Constraints

- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - Audio deletion is not optional — show as informational, not a toggle
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Vault path must be a valid directory
- [INT-202](SoT.INTEGRATIONS.md#int-202-screencapturekit-system-audio) - System audio requires Screen Recording permission

### Design Components

- [DES-005](SoT.DESIGN_COMPONENTS.md#des-005-toolbar) - Gear icon trigger
- [DES-304](SoT.DESIGN_COMPONENTS.md#des-304-borders-and-elevation) - Sheet uses native macOS sheet presentation

### Design Notes

- Standard macOS settings sheet — familiar, unambiguous
- PER-002 needs the Privacy section — explicit local-only reassurance
- Model download should show progress bar and estimated size. Don't surprise users with 1.5GB download.

---

## SCR-006: Transcript History (Sidebar)

**ID**: SCR-006
**Type**: Component (persistent sidebar)
**Status**: Implemented (2026-05-17, EPIC-07)
**Confidence**: 3/5 (source: journey-mapping + design-interview)
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Purpose

Always-visible sidebar listing past transcripts. This IS the sidebar (DES-004) — not a separate screen. Modeled after Obsidian's file explorer.

### Journeys

- [UJ-002](#uj-002-review-and-export-transcript) — Alternative entry (open past transcript)

### Features

- FEA-006 (Transcript History) — Browse and search past transcripts

### Primary Actions

- **Open Transcript**: Click item → loads in SCR-004 (content area)
- **Search**: Type in search bar → filters list (full-text search via DBT-001 FTS index)

### Secondary Actions

- **Delete Transcript**: Right-click → delete (confirmation dialog)
- **Re-export**: Right-click → export to Obsidian again
- **Toggle Sidebar**: Cmd+\ or toolbar button → collapse/expand

### Navigation

- **From**: Always visible (persistent)
- **To**: SCR-004 (click transcript)

### Content

- Search bar at top (live filter)
- Transcript list grouped by date: Today, Yesterday, This Week, Older
- Per item: Title (primary), date + duration + speaker count badge (secondary)
- Selected state: Teal accent background tint
- Empty state: DES-104 with "Record your first meeting" prompt

### Density Mode

**Dense** — Sidebar items are compact (8px vertical padding per item). This is a navigation component, not a reading surface.

### Constraints

- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts) - Data source for list
- [DBT-001 FTS](SoT.DATA_MODEL.md#dbt-001-transcripts) - Full-text search index powers search

### Design Components

- [DES-004](SoT.DESIGN_COMPONENTS.md#des-004-sidebar-transcript-list) - This screen IS DES-004
- [DES-104](SoT.DESIGN_COMPONENTS.md#des-104-empty-state) - Sidebar empty variant

### Design Notes

- Obsidian's file explorer is the reference — dark surface, subtle hover, clean grouping
- Sidebar is resizable (180-320px) and collapsible — power users will want this flexibility
- Right-click context menu for secondary actions (delete, re-export) — standard macOS pattern

---

## UJ-001: Record and Transcribe Meeting

**ID**: UJ-001
**Category**: Core
**Type**: Core
**Status**: Active
**Confidence**: 3/5 (source: design-validation + feature-status-planned + BR-501)
**Created**: 2026-03-11
**Last Updated**: 2026-05-16

### Overview

- **Persona**: PER-001 (primary), PER-002 (secondary)
- **Trigger**: User has a meeting starting (calendar reminder, Zoom opening) — not "opens app"
- **Goal**: Record a meeting and get a speaker-labeled transcript without audio leaving the machine, **without the recording UI demanding attention during the meeting**
- **Success Criteria**: Transcript with speaker labels and timestamps generated locally; main window stays out of the way for the duration of the call (BR-501)
- **KPI Link**: KPI-001 (processing speed < 5 min for 30-min meeting), KPI-002 (diarization accuracy > 80%)
- **Success Metric**: End-to-end time from "click Record" to "transcript visible" for a 30-min meeting

### Steps

1. **Open App (Pre-Flight)**: User launches Transcript Shadow → SCR-001 (Main Window — Idle) → FEA-001
2. **Pre-Flight Check**: User glances at source toggles (mic + system audio) and the pre-record level preview (DES-002) to confirm inputs are live → FEA-001
3. **Start Recording**: User clicks Record (DES-001) → **main window hides** + Recording HUD appears (SCR-002, realized as DES-105 Notch or DES-106 Menu Bar Extra) → FEA-001
4. **Recording Active (HUD-only)**: User switches to Zoom/Teams/Meet. Only the HUD is visible from this app — a red dot + Stop button. No timer, no waveform on the recording surface (BR-501). Audio captured continuously in background; temp file written incrementally for crash recovery (RISK-006) → FEA-001
5. **Stop Recording**: User clicks Stop on the HUD (or fires the global hotkey) → **HUD dismisses** → main window restores → SCR-003 (Processing View) appears in the main content area → FEA-001
6. **Transcription**: WhisperKit transcribes audio → progress in DES-102 stage 1 (visible on the restored main window) → FEA-002
7. **Diarization**: pyannote identifies speakers → progress in DES-102 stage 2 → FEA-003
8. **Formatting**: Transcription + diarization merged → progress in DES-102 stage 3 → FEA-004
9. **Transcript Ready**: Processing complete → content area transitions to SCR-004 → FEA-004
10. **Audio Deleted**: Temp audio file is securely deleted (BR-103)

### Pain Points

- **Step 1-2**: First-launch permission prompts may confuse PER-002 (medium tech comfort). Mitigation: DES-103 permission prompt with plain-language explanation; pre-record level preview (DES-002) immediately tells the user mic/system are wired up.
- **Step 4**: User cannot see realtime audio levels (BR-501 explicitly forbids them on the HUD). Mitigation: pre-flight check at Step 2 establishes "inputs are working"; the red-dot liveness oscillation on the HUD confirms the capture pipeline hasn't crashed. Trust is built before recording, not interrogated during.
- **Step 4 (cont.)**: User may forget which Mac they're on and look for the HUD in the wrong place (notch vs menu bar). Mitigation: a one-time onboarding tooltip on first recording points at the correct surface for their hardware.
- **Step 6-8**: Processing wait for long meetings (RISK-001). Mitigation: Realistic time estimate in DES-102; user can browse past transcripts in sidebar (now visible again) during wait.

### Moment of Value

Step 9: Seeing the completed transcript with speaker names labeled and timestamps — "the app was invisible during my meeting, and it still got everything." Both the **absence** of the recording UI during the call and the **presence** of the transcript afterward are part of the value moment.

### Error Paths

- **No microphone permission (pre-flight)**: DES-103 prompt → guides to System Settings → re-check on return. Record button stays disabled until granted.
- **Screen Recording permission denied** (system audio): SCR-001 shows a yellow banner: "System audio unavailable — recording in mic-only mode. Grant Screen Recording in Settings to capture everyone in your call." User can proceed mic-only (PER-002 fallback) or open SCR-005 to fix the permission.
- **Permission revoked mid-session**: The HUD briefly surfaces an error state (red dot turns amber, "Error" label) for ~2s, the recording stops gracefully (audio buffered so far is preserved and routed to SCR-003), the main window restores, and a banner explains what happened with a "Reopen Settings" link.
- **Processing fails**: DES-102 error state with retry button. Temp audio preserved until retry or explicit cancel.
- **App quit during recording (crash or force-quit)**: Audio saved to temp continuously (RISK-006 mitigation). On next launch, the app detects the orphaned temp file: a recovery banner on SCR-001 asks "Recover unfinished recording from [time]?" — Yes routes the file directly into SCR-003 processing; No deletes per BR-103. API-301 handles silent cleanup of files older than the recovery window.

### APIs Used

- API-001 (AudioCaptureService) — steps 2-5
- API-002 (AudioMixer) — step 4 (mixing mic + system)
- API-101 (TranscriptionService) — step 6
- API-102 (DiarizationSidecar) — step 7
- API-201 (TranscriptFormatter) — step 8
- API-301 (TempAudioCleanup) — step 10

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker) - Primary persona
- [PER-002](#per-002-privacy-conscious-professional) - Secondary persona
- Screen flow: [SCR-001](#scr-001-main-window-idle) → [SCR-002](#scr-002-recording-view) → [SCR-003](#scr-003-processing-view) → [SCR-004](#scr-004-transcript-view)
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing), [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage), [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing), [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration)
- FEA-001, FEA-002, FEA-003, FEA-004

---

## UJ-002: Review and Export Transcript

**ID**: UJ-002
**Category**: Core
**Type**: Core
**Status**: Active
**Confidence**: 3/5 (source: design-validation + feature-status-planned)
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Overview

- **Persona**: PER-001 (primary)
- **Trigger**: Transcript processing completes (from UJ-001 step 9) or user clicks past transcript in sidebar
- **Goal**: Review transcript, rename speakers to real names, and export to Obsidian vault
- **Success Criteria**: Markdown file with correct speaker names appears in Obsidian vault
- **KPI Link**: KPI-003 (daily active use — user records 1+ meeting/day, implies they find export valuable)
- **Success Metric**: Time from "transcript visible" to "exported to Obsidian" ≤ 2 minutes

### Steps

1. **View Transcript**: User sees SCR-004 with speaker-labeled content (DES-003) → FEA-004
2. **Rename Speakers**: User clicks a speaker pill (DES-101) in the speaker summary row → the pill enters its Editing state (inline text field, teal focus ring per DES-101). User types "Alice" and presses Enter (or Esc to cancel). The rename writes to `API-201` `speakerNames` map and persists via `DBT-002.display_name`; the change propagates instantly to **every** transcript block (DES-003) for that speaker. A single-level Undo (Cmd+Z) reverts the most recent rename. If the rename collides with another speaker's existing display name, an inline error appears ("Two speakers can't share a name") and the field stays open. → FEA-003
3. **Review Content**: User scrolls transcript, verifying content → FEA-004
4. **Export to Obsidian**: User clicks "Export to Obsidian" button → file written to vault → FEA-005
5. **Confirmation**: Success toast with file path + "Open in Obsidian" link

### Pain Points

- **Step 2**: Speaker names are auto-generated ("Speaker 1") — user must manually identify who is who. Mitigation: Show speaking time per speaker so user can infer identity from duration. Renames are atomic across the transcript so the user never sees half-renamed segments.
- **Step 4**: Vault path not configured yet (first use). Mitigation: If not configured, button opens SCR-005 settings with vault path section highlighted.

### Alternative Paths

- **Copy to clipboard**: Skip file export, paste markdown anywhere
- **Save as file**: Generic file picker for non-Obsidian users (PER-002)
- **Open past transcript**: Entry from sidebar (SCR-006) instead of fresh processing

### Moment of Value

Step 5: Transcript appears in Obsidian vault — searchable, linked, part of the user's knowledge base. "It's already where I need it."

### APIs Used

- API-202 (ObsidianExporter) — step 4
- DBT-001 (transcripts table) — read transcript
- DBT-002 (speakers table) — speaker rename persistence

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker) - Primary persona
- [SCR-004](#scr-004-transcript-view) - Primary screen
- [SCR-006](#scr-006-transcript-history-sidebar) - Alternative entry
- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format), [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility)
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export)
- FEA-003, FEA-004, FEA-005

---

## UJ-003: Configure App Settings

**ID**: UJ-003
**Category**: Onboarding
**Type**: Onboarding (gates UJ-001 and UJ-002)
**Status**: Active
**Confidence**: 3/5 (source: design-validation)
**Created**: 2026-03-11
**Last Updated**: 2026-03-20

### Overview

- **Persona**: PER-001 (primary), PER-002 (secondary)
- **Trigger**: First launch (permissions needed before first recording) or user wants to change settings
- **Goal**: Configure audio sources, grant permissions, set Obsidian vault path, choose model
- **Success Criteria**: Settings saved, permissions granted, ready to record
- **Success Metric**: First-launch setup completed in ≤ 3 minutes

### Steps

1. **First Launch**: App shows DES-103 permission prompt in content area → user grants mic permission
2. **System Audio Permission**: Optional — prompt explains Screen Recording permission → user grants or skips (mic-only mode)
3. **Open Settings**: User clicks gear (Cmd+,) → SCR-005 sheet opens
4. **Set Obsidian Vault**: User picks vault folder via file browser
5. **Choose Model Size**: User selects Whisper model with size/speed guidance
6. **Close Settings**: Settings auto-save → return to SCR-001 → ready to record

### Pain Points

- **Step 1-2**: macOS permission flow is multi-step (dialog → System Settings → restart app). Mitigation: Clear inline guidance in DES-103. After granting, permission status updates in real-time.
- **Step 4**: PER-002 may not use Obsidian. Mitigation: Vault path is optional — "Save As" button in SCR-004 works without it.
- **Step 5**: Model download for larger models (small/medium) takes time. Mitigation: Show download size and progress. Default to base.en (smallest) — works immediately.

### Dependencies

This journey gates UJ-001 — mic permission must be granted before recording can start. System audio and Obsidian vault are optional but recommended.

### APIs Used

- DBT-101 (app_settings table) — read/write settings

### Related IDs

- [PER-001](#per-001-solo-knowledge-worker), [PER-002](#per-002-privacy-conscious-professional)
- [SCR-005](#scr-005-settings-sheet) - Settings screen
- [DES-103](SoT.DESIGN_COMPONENTS.md#des-103-permission-prompt) - First-launch prompt
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export), [INT-201](SoT.INTEGRATIONS.md#int-201-macos-audio-capture), [INT-202](SoT.INTEGRATIONS.md#int-202-screencapturekit-system-audio)
- [RISK-004 in PRD](../PRD.md) - Permission friction

---

## Deprecated Entries

_No deprecated entries._

---

## Cross-Reference Index

**Journeys by Persona**:

- PER-001 uses: UJ-001, UJ-002, UJ-003
- PER-002 uses: UJ-001, UJ-002, UJ-003

**Journeys by Screen**:

- SCR-001 appears in: UJ-001 (step 1), UJ-003 (step 6)
- SCR-002 appears in: UJ-001 (steps 3-4)
- SCR-003 appears in: UJ-001 (steps 5-8)
- SCR-004 appears in: UJ-001 (step 9), UJ-002 (steps 1-5)
- SCR-005 appears in: UJ-003 (steps 3-6)
- SCR-006 appears in: UJ-002 (alternative entry) — persistent sidebar

**Screens by Density Mode**:

- Spacious (main window): SCR-001, SCR-003, SCR-005
- Dense (main window): SCR-004, SCR-006
- HUD (not on main window — own window-level surface): SCR-002

**APIs by Journey**:

- UJ-001 calls: API-001, API-002, API-101, API-102, API-201, API-301
- UJ-002 calls: API-202
- UJ-003 writes: DBT-101

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
