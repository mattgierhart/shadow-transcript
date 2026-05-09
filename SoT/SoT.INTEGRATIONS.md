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

- [INT-101](#int-101-whisperkit-model-loading) - WhisperKit Model Loading
- [INT-102](#int-102-pyannote-diarization) - pyannote.audio Diarization (subprocess sidecar)

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

## INT-101: WhisperKit Model Loading

**ID**: INT-101
**Category**: ML Model
**Status**: Implemented (EPIC-03, 2026-05-08)
**Provider**: argmaxinc/WhisperKit 0.18.0 (MIT License) — superseded the original whisper.cpp choice during v0.5 stack selection
**Created**: 2026-03-11
**Last Updated**: 2026-05-08

### Description

Load and run Whisper models for local speech-to-text transcription via WhisperKit (CoreML-optimised for Apple Silicon). Models are downloaded on first launch via WhisperKit's built-in download mechanism into a per-variant directory under `~/Library/Application Support/TranscriptShadow/Models/`.

### Configuration

**Model Files**:

- Default: `openai_whisper-base.en` (~148 MB, good quality/speed balance)
- Optional: `openai_whisper-small.en` (~488 MB, better accuracy)
- Optional: `openai_whisper-medium.en` (~1.5 GB, best accuracy)

**Environment Variables**: N/A (no network beyond the one-off model download from Hugging Face).

**Download Path**: Driven by `WhisperKit(model:downloadBase:load:)` — `downloadBase` points at `TranscriptionModelStore.directory`. WhisperKit creates `<downloadBase>/<model.rawValue>/` per variant. (EPIC-03 Codex review fixed an earlier mistake where this was passed as `modelFolder`, which would have made WhisperKit treat the empty cache root as an already-downloaded model and refuse to fetch on first run.)

### Constraints

- **Memory**: Model loaded into RAM during processing (base ~300MB, medium ~2GB)
- **Disk**: Model files stored in app support directory; cache check by directory non-empty (`TranscriptionModelStore.isCached(model:)`)
- **Performance**: Real-time factor ~0.1x on M1 (base model), ~0.3x (medium model)
- **Concurrency**: All `WhisperKit` calls serialized through `AsyncTaskQueue` in `WhisperKitEngine` so concurrent transcribe/load requests cannot collide

### Related IDs

- [TECH-002](SoT.TECHNICAL_DECISIONS.md#tech-002-whisperkit-transcription) - Technology decision
- [API-101](SoT.API_CONTRACTS.md#api-101-transcription-service) - Public surface
- [FEA-002 in PRD](../PRD.md) - Transcription feature
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Must run locally
- [TEST-104](SoT.TESTING.md#test-104-model-download-and-cache) - Cache invariant

---

## INT-102: pyannote Diarization

**ID**: INT-102
**Category**: ML Model (subprocess sidecar)
**Status**: Implemented (full — Python sidecar in EPIC-04a + Swift `DiarizationService` bridge in EPIC-04b).
**Provider**: `pyannote.audio` 4.x + the gated `pyannote/speaker-diarization-community-1` pipeline (CC-BY-4.0).
**Created**: 2026-05-09
**Last Updated**: 2026-05-09

### Description

Identify speaker segments in a recorded audio file. Implemented as a
PyInstaller `--onedir` Python sidecar (`sidecar/diarize.py`) that the
macOS app spawns as a subprocess. The model is gated — first download
requires accepting CC-BY-4.0 terms once on the HF model card and a
read-scoped HF token. Subsequent runs are offline from
`~/Library/Caches/ai.gearheart.TranscriptShadow/huggingface/`.

The cross-language contract is a frozen JSON envelope (schema version
1.0) — `sidecar/test_fixtures/golden-3spk.json` is the conformance
fixture both the Python emitter and EPIC-04b's Swift `DiarizationResult`
Codable type must agree on. See API-102 for the full schema.

### Configuration

**HF token resolution** (first-download only):
- `--hf-token <str>` CLI flag wins
- Falls back to `HF_TOKEN` env
- Exits with code `3` and `ERROR:3:HF auth required …` if neither and the
  model is not cached

**Cache locations** (set before any pyannote / numba import — order
matters; numba's JIT cache is uncacheable across launches without
explicit `NUMBA_CACHE_DIR`, costing a ~30 s librosa cold start otherwise):
- `HF_HOME` → `~/Library/Caches/ai.gearheart.TranscriptShadow/huggingface/`
- `NUMBA_CACHE_DIR` → `~/Library/Caches/ai.gearheart.TranscriptShadow/numba/`

**Audio path passing** (EPIC-04a Phase A Decision 3): the parent passes
`--audio` with a resolved absolute path. The
`TRANSCRIPT_SHADOW_AUDIO_BOOKMARK` env var is reserved for a future
security-scoped-bookmark hand-off; currently the binary errors with a
deferred-implementation message if it sees the env without `--audio`.
EPIC-04b's parent resolves bookmarks and copies/passes `--audio` through
sandbox inheritance.

### Constraints

- **Memory**: pyannote loads the entire pipeline into memory; concurrent
  runs would 2× the footprint. EPIC-04b serializes calls through
  `AsyncTaskQueue` (the same queue we ship for `WhisperKitEngine`).
- **Disk**: First download lands ~150–250 MB of model weights into
  `HF_HOME` (community-1 size is empirically measured during EPIC-04a
  Phase A Spike B; not published on the model card). Bundle target
  ~700 MB compressed (RISK-003).
- **Performance**: RTF is the open RISK-001 unknown. EPIC-04a Phase A
  Spike C measures actual on a 5-min 3-speaker recording. Estimate
  was "~31 s per hour" of audio; revisit RISK-001 with measured values.
- **Concurrency**: Python child is single-process. Swift parent
  serializes via `AsyncTaskQueue`.

### Sandbox + entitlement implications (EPIC-04b)

The PyInstaller bootloader loads `*.dylib` / `*.so` files under the
bundled tree that are NOT signed by the app's Team ID. Under hardened
runtime, dyld refuses to load them without:

- `com.apple.security.cs.disable-library-validation` (parent)
- `com.apple.security.cs.allow-unsigned-executable-memory` (parent — CPython bytecode + ctypes)
- `com.apple.security.cs.allow-jit` (parent — torch MPS path JIT, defensive)

The child binary's entitlements file contains ONLY `app-sandbox` +
`inherit`. Anything else (notably the auto-injected `get-task-allow`
in debug builds) causes `_libsecinit_appsandbox` to crash the child.
The codesign sequence is bottom-up via a Run Script Build Phase — every
`.dylib` / `.so` first, then the inner `diarize` binary, then the `.app`.
Never `--deep` (deprecated since macOS 13; notarization-rejection trigger).

### Related IDs

- [API-102](SoT.API_CONTRACTS.md#api-102-diarization-sidecar-cli) - Subprocess CLI contract
- [TECH-006](SoT.TECHNICAL_DECISIONS.md#tech-006-pyannote-audio-diarization) - Technology decision
- [ARC-002](SoT.TECHNICAL_DECISIONS.md#arc-002-python-sidecar-for-diarization) - Sidecar architecture
- [FEA-003 in PRD](../PRD.md) - Diarization feature
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Must run locally
- TEST-201, TEST-202, TEST-203, TEST-204 — see SoT.TESTING.md

### Lessons learned (EPIC-04a Codex Gate 1, 2026-05-09)

- pyannote 4.0.0's setup metadata pulls torch/torchaudio/torchcodec/
  newer soundfile transitively; hand-pinning `torch>=2.4,<2.5` fails
  to resolve. Pin pyannote.audio only; let it own its transitive graph.
- pyannote's `ProgressHook` writes rich progress bars to stdout —
  collides with our `PROGRESS:` line contract for EPIC-04b's Swift
  parser. Don't forward to the inner hook; emit our own typed lines.
- Bookmark resolution in pure Python is impossible without Foundation
  APIs; the env var contract surface exists, but resolution is the
  parent's job. Swift parent passes `--audio` post-resolution.

---

## INT-201: macOS Audio Capture

**ID**: INT-201
**Category**: System
**Status**: Implemented (EPIC-02, 2026-05-06; tap-leak fix 2026-05-06; lock migration to `withLock` for Swift 6 strict concurrency 2026-05-06)
**Provider**: Apple AVFoundation / AVAudioEngine
**Created**: 2026-03-11
**Last Updated**: 2026-05-06

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
**Status**: Implemented (EPIC-02, 2026-05-06; channelCount config knob removed 2026-05-07 in favor of internal `AudioCaptureConfiguration.outputChannelCount`)
**Provider**: Apple ScreenCaptureKit (macOS 13+; we target macOS 15+ for unified mic + system audio)
**Created**: 2026-03-11
**Last Updated**: 2026-05-07

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
