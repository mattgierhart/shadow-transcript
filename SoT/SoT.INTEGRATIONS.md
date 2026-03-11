---
version: 1.0
purpose: Source of Truth for third-party service integrations and external dependencies.
id_prefix: INT-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by SoT.API_CONTRACTS.md, EPICs, and code
---

# Integrations (SoT File)

> **Purpose**: Catalog of third-party services, external APIs, and integration dependencies for Transcript Shadow.
> **ID Prefix**: INT-XXX
> **Status**: Active SoT file
> **Cross-References**: Referenced by SoT.API_CONTRACTS.md, SoT.DEPLOYMENT.md, EPICs

## Navigation by Category

**File System Integrations** (INT-001 to INT-099):

- [INT-001](#int-001-obsidian-vault-export) - Obsidian Vault Export

**ML Model Integrations** (INT-101 to INT-199):

- [INT-101](#int-101-whisper-cpp-model-loading) - whisper.cpp Model Loading

**System Integrations** (INT-201 to INT-299):

- [INT-201](#int-201-macos-audio-capture) - macOS Audio Capture
- [INT-202](#int-202-screencapturekit-system-audio) - ScreenCaptureKit System Audio

---

## INT-001: Obsidian Vault Export

**ID**: INT-001
**Category**: File System
**Status**: Planned
**Provider**: Obsidian (file-based, no API)
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Export transcripts as markdown files directly into an Obsidian vault directory. This is a file-system integration — no Obsidian API or plugin required. The app writes `.md` files with YAML frontmatter to the user-configured vault path.

### Configuration

**User Settings**:

- `obsidian_vault_path` - Path to Obsidian vault root directory
- `obsidian_subfolder` - Optional subfolder within vault (default: "Meetings")

**File Naming Convention**: `YYYY-MM-DD Meeting Title.md`

**Frontmatter Template**:
```yaml
---
date: 2026-03-11
type: meeting-transcript
duration: "45:30"
speakers: ["Alice", "Bob"]
source: transcript-shadow
tags: [meeting, transcript]
---
```

### Constraints

- **Rate Limits**: N/A (local file system)
- **Cost Model**: Free (file write)
- **Dependencies**: User must have Obsidian installed and vault path accessible

### Related IDs

- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Compatibility requirement
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Export journey
- [SCR-005](SoT.USER_JOURNEYS.md#scr-005-settings-view) - Vault path configuration
- [CFD-003](SoT.customer_feedback.md#cfd-003-obsidian-users-want-native-meeting-notes) - driven-by
- [TECH-005](SoT.TECHNICAL_DECISIONS.md#tech-005-obsidian-file-system-integration) - Technology decision

---

## INT-101: whisper.cpp Model Loading

**ID**: INT-101
**Category**: ML Model
**Status**: Planned
**Provider**: ggerganov/whisper.cpp (MIT License)
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Load and run Whisper GGML models for local speech-to-text transcription. Models are bundled with the app or downloaded on first launch. CoreML-optimized variants available for Apple Silicon acceleration.

### Configuration

**Model Files**:

- Bundled: `whisper-base.en` (~148MB, good quality/speed balance)
- Optional download: `whisper-small.en` (~488MB, better accuracy)
- Optional download: `whisper-medium.en` (~1.5GB, best accuracy)

**Environment Variables**: N/A (local binary/library)

### Constraints

- **Memory**: Model loaded into RAM during processing (base ~300MB, medium ~2GB)
- **Disk**: Model files stored in app support directory
- **Performance**: Real-time factor ~0.1x on M1 (base model), ~0.3x (medium model)

### Related IDs

- [TECH-002](SoT.TECHNICAL_DECISIONS.md#tech-002-whisper-cpp-transcription) - Technology decision
- [FEA-002 in PRD](../PRD.md) - Transcription feature
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Must run locally

---

## INT-201: macOS Audio Capture

**ID**: INT-201
**Category**: System
**Status**: Planned
**Provider**: Apple AVFoundation / AVAudioEngine
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Capture microphone audio using AVAudioEngine. Requires microphone permission (NSMicrophoneUsageDescription in Info.plist).

### Configuration

**Entitlements**:

- `com.apple.security.device.audio-input` (microphone access)
- Sandbox exception for audio recording

**Permissions**:

- macOS microphone permission dialog (system-managed)

### Constraints

- **Rate Limits**: N/A
- **Dependencies**: macOS 14+, user must grant microphone permission

### Related IDs

- [FEA-001 in PRD](../PRD.md) - Audio capture feature
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Recording journey
- [TECH-003](SoT.TECHNICAL_DECISIONS.md#tech-003-avaudioengine-audio-capture) - Technology decision

---

## INT-202: ScreenCaptureKit System Audio

**ID**: INT-202
**Category**: System
**Status**: Planned
**Provider**: Apple ScreenCaptureKit (macOS 13+)
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Description

Capture system audio (meeting app output) using ScreenCaptureKit. Allows recording what other participants say in video calls without a virtual audio driver.

### Configuration

**Entitlements**:

- `com.apple.security.screencapture` (screen capture, includes audio)

**Permissions**:

- macOS Screen Recording permission dialog (system-managed)
- User must grant in System Settings > Privacy & Security > Screen Recording

### Constraints

- **Platform**: macOS 13+ only (macOS 14+ recommended for audio-only capture)
- **Limitation**: Captures all system audio — may include notification sounds
- **Alternative**: BlackHole virtual audio driver for more targeted capture

### Related IDs

- [FEA-001 in PRD](../PRD.md) - Audio capture feature
- [INT-201](#int-201-macos-audio-capture) - Used alongside for mic + system audio
- [TECH-004](SoT.TECHNICAL_DECISIONS.md#tech-004-screencapturekit-system-audio) - Technology decision

---

## Deprecated Integrations

_No deprecated integrations._

---

## Cross-Reference Index

**Integrations by Journey**:

- UJ-001 uses: INT-201, INT-202, INT-101
- UJ-002 uses: INT-001
- UJ-003 configures: INT-001, INT-201, INT-202

**Integrations by Category**:

- File System: INT-001
- ML Model: INT-101
- System: INT-201, INT-202

---

## Update Protocol

### When to Add New INT-XXX IDs

1. **New Third-Party Service**: Adding a new external dependency
2. **Service Migration**: Switching providers (create new, deprecate old)
3. **System Integration**: New OS-level API or framework dependency

### Bidirectional Reference Checklist

When adding a new INT-XXX:

- [ ] Update SoT.API_CONTRACTS.md "External Services" section
- [ ] Update SoT.DEPLOYMENT.md with required environment variables
- [ ] Update EPIC Section 2 "Context & IDs" list
- [ ] Document in SoT.TECHNICAL_DECISIONS.md if significant choice

---

*End of SoT.INTEGRATIONS.md - Authoritative source for all INT-XXX IDs*
