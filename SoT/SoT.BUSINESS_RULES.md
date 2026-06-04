---
version: 1.0
purpose: Source of Truth for business rules and operational constraints.
id_prefix: BR-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by PRD.md, SoT.API_CONTRACTS.md, EPICs, and code
---

# Business Rules (SoT File)

> **Purpose**: Complete specifications for business constraints, privacy rules, and enforcement policies.
> **ID Prefix**: BR-XXX
> **Status**: Active SoT file
> **Cross-References**: Referenced by PRD.md, SoT.API_CONTRACTS.md, SoT.USER_JOURNEYS.md, SoT.TESTING.md, EPICs

## Navigation by Category

**Data & Security** (BR-101 to BR-199):

- [BR-101](#br-101-local-only-processing) - Local-only processing
- [BR-102](#br-102-no-persistent-audio-storage) - No persistent audio storage
- [BR-103](#br-103-audio-deletion-after-processing) - Audio deletion after processing
- [BR-104](#br-104-on-device-summarization) - On-device summarization

**Platform & Scope** (BR-201 to BR-299):

- [BR-201](#br-201-macos-only-platform) - macOS-only platform
- [BR-202](#br-202-english-only-transcription) - English-only transcription
- [BR-203](#br-203-single-user-local-app) - Single-user local app

**Output & Format** (BR-301 to BR-399):

- [BR-301](#br-301-markdown-output-format) - Markdown output format
- [BR-302](#br-302-obsidian-vault-compatibility) - Obsidian vault compatibility

**Performance & Limits** (BR-401 to BR-499):

- [BR-401](#br-401-apple-silicon-required) - Apple Silicon required
- [BR-402](#br-402-maximum-meeting-duration) - Maximum meeting duration

**UX & Interaction** (BR-501 to BR-599):

- [BR-501](#br-501-minimal-recording-ui) - Minimal recording UI

---

## BR-101: Local-Only Processing

**ID**: BR-101
**Category**: Data & Security
**Status**: Active
**Severity**: Critical
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

All audio capture, transcription, and speaker diarization MUST execute locally on the user's machine. No audio data, transcription data, or meeting metadata SHALL be transmitted to any external server or cloud service.

### Rationale

- **Business Driver**: Core product differentiator — privacy-first local processing
- **User Impact**: Users can confidently record sensitive meetings without privacy concerns

### Enforcement

**Location**: Application architecture (no network calls for core pipeline)
**Timing**: Design-time constraint; validated by architecture review

### Related IDs

- [CFD-001](SoT.customer_feedback.md#cfd-001-cloud-meeting-tools-force-privacy-tradeoffs) - driven-by
- [CFD-101](SoT.customer_feedback.md#cfd-101-local-processing-eliminates-privacy-anxiety) - driven-by
- [ARC-001](SoT.TECHNICAL_DECISIONS.md#arc-001-local-first-pipeline) - implements

---

## BR-102: No Persistent Audio Storage

**ID**: BR-102
**Category**: Data & Security
**Status**: Active
**Severity**: Critical
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

The application MUST NOT retain audio files after processing is complete. Audio exists only as a temporary artifact during the transcription pipeline. Once the transcript is generated and confirmed, audio files MUST be deleted.

### Rationale

- **Business Driver**: Privacy guarantee — no audio forensics possible after use
- **User Impact**: Users know their recordings are ephemeral

### Enforcement

**Location**: Pipeline completion handler
**Timing**: Immediately after successful transcript generation

### Related IDs

- [BR-103](#br-103-audio-deletion-after-processing) - implements
- [CFD-101](SoT.customer_feedback.md#cfd-101-local-processing-eliminates-privacy-anxiety) - driven-by

---

## BR-103: Audio Deletion After Processing

**ID**: BR-103
**Category**: Data & Security
**Status**: Active
**Severity**: Critical
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

Temporary audio files MUST be securely deleted upon: (a) successful transcript generation, (b) user cancellation of recording, or (c) application quit during recording. The app SHOULD use secure deletion (overwrite) where the OS supports it.

### Rationale

- **Business Driver**: Enforcement mechanism for BR-102
- **User Impact**: No orphaned audio files on disk

### Enforcement

**Location**: Pipeline manager + app lifecycle handlers
**Timing**: On pipeline completion, cancellation, or app termination

### Related IDs

- [BR-102](#br-102-no-persistent-audio-storage) - enforces
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - applies during

---

## BR-104: On-Device Summarization

**ID**: BR-104
**Category**: Data & Security
**Status**: Active
**Severity**: Critical
**Created**: 2026-06-04 (EPIC-09)

### Rule Statement

Meeting summarization (FEA-007 / API-401) MUST run entirely on-device. The
transcript text MUST NOT be sent to any network service for summarization.
Permitted engines: Apple Foundation Models (on-device Apple Intelligence) and
the local deterministic `ExtractiveSummarizer`. A cloud LLM is explicitly
prohibited unless BR-101 is formally revised with explicit, opt-in user consent.

### Rationale

- **Business Driver**: Refinement of BR-101 (local-only). The privacy promise
  ("no data leaves the device") must hold for the summary feature too.
- **User Impact**: Summaries of private meetings never leave the Mac.

### Enforcement

**Location**: `DefaultSummarizationService` (engine selection) + the pipeline.
**Timing**: Each pipeline run when `summarizeOnComplete` is enabled.
**Verification**: TEST-504 no-network probe covers the summarize stage too.

### Related IDs

- [BR-101](#br-101-local-only-processing) - refines
- API-401, FEA-007, TECH-008 - implemented-by

---

## BR-201: macOS-Only Platform

**ID**: BR-201
**Category**: Platform & Scope
**Status**: Active
**Severity**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

The MVP targets macOS only (macOS 14 Sonoma or later). No cross-platform support is in scope for initial release.

### Rationale

- **Business Driver**: Focus on a single platform to ship faster; Apple Silicon ML capabilities
- **User Impact**: Only macOS users can use the app

### Related IDs

- [BR-401](#br-401-apple-silicon-required) - related constraint
- [TECH-001](SoT.TECHNICAL_DECISIONS.md#tech-001-swift-swiftui) - implements

---

## BR-202: English-Only Transcription

**ID**: BR-202
**Category**: Platform & Scope
**Status**: Active
**Severity**: Medium
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

The MVP supports English language transcription only. Multi-language support is a future enhancement.

### Rationale

- **Business Driver**: Reduce scope; English Whisper models are most mature
- **User Impact**: Non-English meetings are not supported in MVP

### Related IDs

- [FEA-002 in PRD](../PRD.md) - Transcription feature constraint

---

## BR-203: Single-User Local App

**ID**: BR-203
**Category**: Platform & Scope
**Status**: Active
**Severity**: Medium
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

Transcript Shadow is a single-user desktop application. No user accounts, authentication, or multi-user collaboration features are in scope.

### Rationale

- **Business Driver**: Simplicity — no backend, no auth, no user management
- **User Impact**: App works immediately after install, no sign-up required

### Related IDs

- [ARC-001](SoT.TECHNICAL_DECISIONS.md#arc-001-local-first-pipeline) - architectural constraint

---

## BR-301: Markdown Output Format

**ID**: BR-301
**Category**: Output & Format
**Status**: Active
**Severity**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

All transcripts MUST be output as standard Markdown (.md) files with speaker labels, timestamps, and proper formatting. The format must be human-readable without any special tooling.

### Rationale

- **Business Driver**: Portability — markdown is universal
- **User Impact**: Transcripts work in any text editor or note-taking app

### Related IDs

- [CFD-004](SoT.customer_feedback.md#cfd-004-notion-recording-lock-in-frustration) - driven-by
- [FEA-004 in PRD](../PRD.md) - Markdown output feature
- [BR-302](#br-302-obsidian-vault-compatibility) - enables

---

## BR-302: Obsidian Vault Compatibility

**ID**: BR-302
**Category**: Output & Format
**Status**: Active
**Severity**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

Exported markdown files MUST be compatible with Obsidian vaults: valid frontmatter (YAML), no proprietary syntax, and file naming that works within Obsidian's conventions.

### Rationale

- **Business Driver**: Obsidian is the primary export target
- **User Impact**: Transcripts appear correctly in Obsidian with metadata

### Related IDs

- [CFD-003](SoT.customer_feedback.md#cfd-003-obsidian-users-want-native-meeting-notes) - driven-by
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - implements
- [FEA-005 in PRD](../PRD.md) - Obsidian export feature

---

## BR-401: Apple Silicon Required

**ID**: BR-401
**Category**: Performance & Limits
**Status**: Active
**Severity**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

Transcript Shadow requires Apple Silicon (M1 or later) for acceptable ML inference performance. Intel Macs are not supported.

### Rationale

- **Business Driver**: Whisper and diarization models require Neural Engine / GPU acceleration
- **User Impact**: Intel Mac users cannot run the app

### Related IDs

- [BR-201](#br-201-macos-only-platform) - related constraint
- [TECH-002](SoT.TECHNICAL_DECISIONS.md#tech-002-whisper-cpp-transcription) - driven-by

---

## BR-402: Maximum Meeting Duration

**ID**: BR-402
**Category**: Performance & Limits
**Status**: Active
**Severity**: Medium
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Rule Statement

The MVP supports meetings up to 2 hours in duration. Longer recordings MAY work but are not guaranteed. The app SHOULD warn users approaching the limit.

### Rationale

- **Business Driver**: Memory and disk constraints for local processing
- **User Impact**: Very long meetings may need to be split

### Related IDs

- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - applies during

---

## BR-501: Minimal Recording UI

**ID**: BR-501
**Category**: UX & Interaction
**Status**: Active
**Severity**: High
**Created**: 2026-04-24
**Last Updated**: 2026-05-16

### Rule Statement

While a recording is active, the app's main window MUST be hidden. The only app-owned UI visible to the user during recording is the Recording HUD (SCR-002), realized as either the Notch HUD (DES-105) on notch-equipped MacBook Pros or the Menu Bar Extra (DES-106) on all other Macs. The Recording HUD MUST expose exactly one user-facing action: **Stop**. No timer, audio level, waveform, pause/resume, source toggles, settings, or navigation shall be shown on the recording surface itself; any such controls require the user to explicitly open the main window.

### Rationale

- **Business Driver**: The app's job during a meeting is to stay out of the way. The user's focus belongs on the meeting app (Zoom, Meet, Teams, etc.), not on the recorder. A single, unambiguous Stop action eliminates the risk of accidental misconfiguration mid-meeting.
- **User Impact**: No window clutter; recording is ambient; the user can't hit the wrong button under pressure.

### Enforcement

**Location**: Window manager / recording state machine in the Swift app.
**Timing**: Transition into recording state (main window → hidden; HUD → appearing); transition out (HUD → dismissing; main window → SCR-003).

### Scope & Exceptions

- **Permission dialogs** (macOS mic / Screen Recording): owned by the OS and may appear; these are not app UI.
- **System notifications** (e.g., approaching BR-402 duration cap): allowed via `UNUserNotificationCenter` — they are ambient banners, not app windows.
- **Error recovery** (permission revoked mid-session): the HUD may briefly surface an error state, then the main window is restored to handle recovery.
- **User-initiated open**: clicking the app icon / expanding the notch is an explicit action; the main window may appear while recording continues. This is user choice, not automatic.

### Related IDs

- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - enforces during
- [SCR-002](SoT.USER_JOURNEYS.md#scr-002-recording-hud) - the single permitted recording surface
- [DES-105](SoT.DESIGN_COMPONENTS.md#des-105-recording-hud-notch) - notch realization
- [DES-106](SoT.DESIGN_COMPONENTS.md#des-106-recording-hud-menu-bar-extra) - menu bar realization
- [RISK-008 in PRD](../PRD.md) - hardware fragmentation risk tied to this rule

---

## Deprecated Rules

_No deprecated rules._

---

## Cross-Reference Index

**Rules by Category**:

- Data & Security: BR-101, BR-102, BR-103
- Platform & Scope: BR-201, BR-202, BR-203
- Output & Format: BR-301, BR-302
- Performance & Limits: BR-401, BR-402
- UX & Interaction: BR-501

**Rules by Severity**:

- Critical: BR-101, BR-102, BR-103
- High: BR-201, BR-301, BR-302, BR-401, BR-501
- Medium: BR-202, BR-203, BR-402

---

## Update Protocol

### When to Add New BR-XXX IDs

1. **New Business Constraint**: Rule affecting user behavior or system limits
2. **Privacy Requirement**: New data handling or deletion rule
3. **Platform Constraint**: New scope or compatibility limitation

### Bidirectional Reference Checklist

When adding a new BR-XXX:

- [ ] Update SoT.API_CONTRACTS.md "Enforces Business Rules" section
- [ ] Update SoT.USER_JOURNEYS.md "Business Rules Enforced" section
- [ ] Update SoT.TESTING.md with validation test
- [ ] Update EPIC Section 2 "Context & IDs" list

---

*End of SoT.BUSINESS_RULES.md - Authoritative source for all BR-XXX IDs*
