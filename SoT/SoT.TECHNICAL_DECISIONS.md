---
version: 1.1
purpose: Source of Truth for technology choices, architecture decisions, and environment specifications.
id_prefix: TECH-XXX, ARC-XXX, ENV-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by PRD.md, EPICs, and code
---

# Technical Decisions (SoT File)

> **Purpose**: Record technology selections, architecture decisions, and environment specifications for Transcript Shadow.
> **ID Prefixes**: TECH-XXX (stack decisions), ARC-XXX (architecture decisions), ENV-XXX (environment setup)
> **Status**: Active SoT file
> **Cross-References**: Referenced by PRD.md v0.5-v0.6, SoT.API_CONTRACTS.md, EPICs

## Navigation by Category

**Stack Decisions** (TECH-001 to TECH-099):

- [TECH-001](#tech-001-swift-swiftui) - Swift + SwiftUI (app framework)
- [TECH-002](#tech-002-whisperkit-transcription) - WhisperKit (transcription engine)
- [TECH-003](#tech-003-avaudioengine-audio-capture) - AVAudioEngine (microphone capture)
- [TECH-004](#tech-004-screencapturekit-system-audio) - ScreenCaptureKit (system audio)
- [TECH-005](#tech-005-obsidian-file-system-integration) - Obsidian file system integration
- [TECH-006](#tech-006-pyannote-audio-diarization) - pyannote-audio (speaker diarization)
- [TECH-007](#tech-007-sqlite-local-storage) - SQLite (local transcript storage)

**Architecture Decisions** (ARC-001 to ARC-099):

- [ARC-001](#arc-001-local-first-pipeline) - Local-first processing pipeline
- [ARC-002](#arc-002-python-sidecar-for-diarization) - Python sidecar for diarization
- [ARC-003](#arc-003-temporary-audio-lifecycle) - Temporary audio lifecycle management

**Environment Specifications** (ENV-001 to ENV-099):

- [ENV-001](#env-001-development-environment) - Development environment setup

---

## TECH-001: Swift + SwiftUI

**ID**: TECH-001
**Category**: App Framework
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Need a macOS application framework that provides native access to audio capture APIs (ScreenCaptureKit, AVAudioEngine), ML inference (CoreML), and delivers a polished macOS experience.

### Decision

Build as a native macOS app using Swift and SwiftUI. Target macOS 15+ (Sequoia).

### Rationale

- **Chosen because**: Native access to ScreenCaptureKit, CoreML, AVAudioEngine without bridging. Smallest app footprint (~10-50MB). Best performance for audio processing. SwiftUI provides modern declarative UI.
- **Alternatives considered**: Tauri 2.0 (Rust+Web — cross-platform but requires Swift bridging for Apple APIs), Electron (too heavy, poor audio API access)
- **Trade-offs accepted**: macOS-only (no cross-platform), SwiftUI on macOS has some rough edges vs AppKit

### Related IDs

- [BR-201](SoT.BUSINESS_RULES.md#br-201-macos-only-platform) - macOS-only scope
- [BR-401](SoT.BUSINESS_RULES.md#br-401-apple-silicon-required) - Apple Silicon requirement
- [ARC-001](#arc-001-local-first-pipeline) - Enables local pipeline

### Open-Source References

- [Azayaka](https://github.com/Mnpn/Azayaka) — ScreenCaptureKit recorder (Swift, menu bar app)
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — Native Swift transcription

---

## TECH-002: WhisperKit (Transcription Engine)

**ID**: TECH-002
**Category**: ML/AI
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Need a local speech-to-text engine that runs on Apple Silicon with good accuracy for English meeting transcription.

### Decision

Use WhisperKit (argmaxinc/WhisperKit) as the primary transcription engine. MIT license. Native Swift Package with CoreML/ANE acceleration.

### Rationale

- **Chosen because**: Native Swift Package Manager integration (no C bridging). Runs on Apple Neural Engine via CoreML. Auto-selects optimal model for device. Supports streaming, word timestamps, VAD. 5,700+ GitHub stars, actively maintained (v0.16.0+). MIT license.
- **Alternatives considered**:
  - whisper.cpp (MIT, C/C++ — excellent but requires C bridging in Swift)
  - MLX Whisper (MIT, Python — fastest raw speed but requires Python sidecar)
  - Apple SFSpeechRecognizer (free, native — lower accuracy for technical content)
  - Apple SpeechAnalyzer (not yet shipping, macOS 26 expected fall 2026)
- **Trade-offs accepted**: Less control than whisper.cpp over inference pipeline; model download required on first launch

### Model Strategy

| Model | Size | Use Case | Quality |
|-------|------|----------|---------|
| `whisper-base.en` | ~148MB | Default — good speed/quality balance | Good |
| `whisper-small.en` | ~488MB | Higher accuracy option | Better |
| `whisper-medium.en` | ~1.5GB | Best accuracy for important meetings | Best |

### Related IDs

- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Must run locally
- [BR-202](SoT.BUSINESS_RULES.md#br-202-english-only-transcription) - English only
- [INT-101](SoT.INTEGRATIONS.md#int-101-whisper-cpp-model-loading) - Model loading integration
- [FEA-002 in PRD](../PRD.md) - Transcription feature

### Open-Source References

- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — MIT, Swift, 5.7k+ stars
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) — MIT, C/C++, fallback option
- [WhisperKit macOS guide](https://www.helrabelo.dev/blog/whisperkit-on-macos-integrating-on-device-ml)

---

## TECH-003: AVAudioEngine (Microphone Capture)

**ID**: TECH-003
**Category**: Audio
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Need to capture microphone input for recording the user's voice during meetings.

### Decision

Use AVAudioEngine for microphone capture. On macOS 15+, ScreenCaptureKit can also capture microphone via `SCStreamOutputType.microphone`, providing a unified capture path.

### Rationale

- **Chosen because**: First-party Apple API, straightforward tap-on-input-node pattern, works on all macOS versions
- **Alternatives considered**: ScreenCaptureKit microphone (macOS 15+ only), raw CoreAudio (too low-level)
- **Trade-offs accepted**: Cannot capture system audio (need ScreenCaptureKit for that)

### Related IDs

- [INT-201](SoT.INTEGRATIONS.md#int-201-macos-audio-capture) - Integration details
- [FEA-001 in PRD](../PRD.md) - Audio capture feature
- [TECH-004](#tech-004-screencapturekit-system-audio) - Companion for system audio

---

## TECH-004: ScreenCaptureKit (System Audio)

**ID**: TECH-004
**Category**: Audio
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Need to capture system audio (meeting app output — what other participants say) without requiring users to install third-party audio drivers.

### Decision

Use ScreenCaptureKit for system audio capture. Requires macOS 13+ (audio-only capture improved in macOS 14+, microphone support added in macOS 15+).

### Rationale

- **Chosen because**: No kernel extension or virtual audio driver needed. Pure userspace API. Apple-supported and maintained. Clean permission model via System Settings.
- **Alternatives considered**: BlackHole virtual audio driver (GPL-3.0, requires manual user setup — multi-step process), Core Audio aggregate devices (complex, fragile)
- **Trade-offs accepted**: Captures all system audio (including notification sounds). Requires Screen Recording permission.

### Related IDs

- [INT-202](SoT.INTEGRATIONS.md#int-202-screencapturekit-system-audio) - Integration details
- [FEA-001 in PRD](../PRD.md) - Audio capture feature
- [TECH-003](#tech-003-avaudioengine-audio-capture) - Companion for microphone

### Open-Source References

- [Azayaka](https://github.com/Mnpn/Azayaka) — ScreenCaptureKit recorder reference
- [BetterCapture](https://github.com/jsattler/BetterCapture) — SwiftUI dual audio capture demo

---

## TECH-005: Obsidian File System Integration

**ID**: TECH-005
**Category**: Export
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Need to export transcripts to Obsidian vaults. Obsidian vaults are local folders of markdown files.

### Decision

Write `.md` files directly to the user-configured Obsidian vault directory. No API, no plugin required. YAML frontmatter for metadata.

### Rationale

- **Chosen because**: Simplest possible integration. Zero dependencies. Obsidian auto-detects new files. Works even if Obsidian isn't running.
- **Alternatives considered**: Obsidian URI scheme (requires Obsidian to be running), custom plugin (unnecessary complexity)
- **Trade-offs accepted**: No bidirectional sync. App doesn't know about Obsidian's internal state.

### Related IDs

- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Integration details
- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Compatibility rules

---

## TECH-006: pyannote-audio (Speaker Diarization)

**ID**: TECH-006
**Category**: ML/AI
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Need to identify different speakers in meeting audio (diarization). No production-ready Swift-native diarization library exists as of March 2026.

### Decision

Use pyannote-audio with the `speaker-diarization-community-1` pipeline (CC-BY-4.0 model, MIT library). Run as a Python sidecar process bundled with the app.

### Rationale

- **Chosen because**: Best-in-class diarization accuracy. MIT library license. Community-1 model is CC-BY-4.0 (free, open). Processes ~31s per hour of audio (GPU benchmark). Fully offline capable.
- **Alternatives considered**:
  - WeSpeaker (Apache-2.0 — good embeddings, less turnkey for end-to-end diarization)
  - NVIDIA NeMo (Apache-2.0 — requires CUDA, not viable on macOS)
  - Native Swift (no production library exists)
  - WhisperKit Pro (commercial — bundles pyannote but paid)
- **Trade-offs accepted**: Requires Python runtime bundled as sidecar. Runs on CPU only on macOS (MPS support is unreliable). Processing takes several minutes for 30-60 min meetings. Not real-time.

### Sidecar Strategy

Bundle a minimal Python environment with pyannote pre-installed, compiled via PyInstaller into a standalone executable. This avoids requiring users to have Python installed.

### Related IDs

- [ARC-002](#arc-002-python-sidecar-for-diarization) - Architecture decision
- [FEA-003 in PRD](../PRD.md) - Diarization feature
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Must run locally

### Open-Source References

- [pyannote-audio](https://github.com/pyannote/pyannote-audio) — MIT, Python, best accuracy
- [speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1) — CC-BY-4.0 model
- [WeSpeaker](https://github.com/wenet-e2e/wespeaker) — Apache-2.0, alternative embeddings

---

## TECH-007: SQLite (Local Transcript Storage)

**ID**: TECH-007
**Category**: Storage
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Need local persistent storage for transcript metadata, speaker mappings, and settings. No server or cloud database.

### Decision

Use SQLite via Swift's native SQLite support (or GRDB.swift for a more ergonomic API). Store in app's Application Support directory.

### Rationale

- **Chosen because**: Zero-configuration, serverless, local-only. Perfect for single-user desktop apps. Swift has built-in SQLite support.
- **Alternatives considered**: Core Data (heavier, ORM complexity), JSON files (no querying), SwiftData (newer but less mature)
- **Trade-offs accepted**: No sync, no cloud backup (by design per BR-101)

### Related IDs

- [BR-203](SoT.BUSINESS_RULES.md#br-203-single-user-local-app) - Single-user local app
- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts) - Transcript table
- [DBT-002](SoT.DATA_MODEL.md#dbt-002-speakers) - Speaker table

---

## ARC-001: Local-First Processing Pipeline

**ID**: ARC-001
**Category**: Data Flow
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

The product's core value proposition is that all processing happens locally. Need to define the data flow from audio capture to transcript output.

### Decision

Implement a sequential pipeline: Capture → Temp File → Transcribe → Diarize → Merge → Format → Export → Cleanup.

### Pipeline Stages

```
[Audio Capture] → [Temp WAV File] → [WhisperKit Transcription]
                                           ↓
                                   [Word-level timestamps]
                                           ↓
                              [pyannote Diarization (sidecar)]
                                           ↓
                              [Speaker-segment alignment]
                                           ↓
                              [Merge: words + speakers]
                                           ↓
                              [Markdown Formatter]
                                           ↓
                    [Transcript View] → [Obsidian Export]
                                           ↓
                              [Delete Temp Audio (BR-103)]
```

### Rationale

- **Chosen because**: Clear separation of concerns. Each stage is independently testable. Sequential flow simplifies error handling and progress reporting.
- **Alternatives considered**: Streaming pipeline (real-time transcription during recording — higher complexity, deferred to post-MVP)
- **Consequences**: Processing happens after recording ends, not in real-time. Users wait during processing.

### Related IDs

- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Local-only constraint
- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - No audio retention
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Audio cleanup
- [TECH-002](#tech-002-whisperkit-transcription) - Transcription engine
- [TECH-006](#tech-006-pyannote-audio-diarization) - Diarization engine
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - User journey

---

## ARC-002: Python Sidecar for Diarization

**ID**: ARC-002
**Category**: Integration
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Speaker diarization requires pyannote-audio (Python). The main app is Swift. Need a strategy to bridge the two.

### Decision

Bundle a PyInstaller-compiled Python executable containing the pyannote diarization pipeline. The Swift app invokes it as a subprocess, passing the audio file path and receiving JSON output with speaker segments.

### Interface Contract

**Input**: `./diarize --audio /tmp/meeting.wav --output /tmp/speakers.json`

**Output** (`speakers.json`):
```json
{
  "speakers": [
    {"speaker": "SPEAKER_00", "start": 0.5, "end": 12.3},
    {"speaker": "SPEAKER_01", "start": 12.5, "end": 25.1}
  ]
}
```

### Rationale

- **Chosen because**: PyInstaller creates a self-contained executable (~200-400MB) with no user-visible Python dependency. Clean subprocess interface. Easy to replace diarization engine later.
- **Alternatives considered**: Embedded Python (complex, fragile), ONNX conversion (WeSpeaker — less accurate), pure Swift implementation (no library exists)
- **Consequences**: Large app bundle size. First-launch model download. Cold start time for diarization process.

### Related IDs

- [TECH-006](#tech-006-pyannote-audio-diarization) - Technology decision
- [ARC-001](#arc-001-local-first-pipeline) - Pipeline architecture

---

## ARC-003: Temporary Audio Lifecycle Management

**ID**: ARC-003
**Category**: Data Flow
**Status**: Accepted
**Decision Date**: 2026-03-11
**Last Reviewed**: 2026-03-11

### Context

Audio files must exist temporarily during processing but be deleted afterward (BR-102, BR-103). Need reliable cleanup across all scenarios.

### Decision

Use a dedicated temp directory within the app's sandbox. Implement multi-layer cleanup:

1. **Normal path**: Delete after successful transcript generation
2. **Cancellation**: Delete on user cancel
3. **App quit**: Register cleanup in `applicationWillTerminate`
4. **Crash recovery**: On next launch, scan temp directory and delete any orphaned audio files
5. **Secure deletion**: Use `FileManager.removeItem` (macOS handles secure deletion on APFS SSDs via TRIM)

### Rationale

- **Chosen because**: Defense in depth — no single failure point can leave audio on disk permanently
- **Consequences**: Audio cannot be re-processed after deletion. Users must re-record if transcript is lost.

### Related IDs

- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - No persistent audio
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Deletion rules

---

## ENV-001: Development Environment

**ID**: ENV-001
**Category**: Development Setup
**Status**: Planned
**Last Reviewed**: 2026-03-11
**Owner**: Developer

### Purpose

Document the development environment requirements for Transcript Shadow.

### CLIs (Global System Tools)

```bash
# macOS development tools
xcode-select --install          # Xcode command line tools
brew install python@3.11        # Python for diarization sidecar
brew install pyinstaller        # Bundle Python sidecar
```

### Language-Specific Packages

**Swift (via Xcode)**:
- Xcode 16+ (Swift 6, SwiftUI)
- WhisperKit (Swift Package Manager)
- GRDB.swift (Swift Package Manager, SQLite wrapper)

**Python (for diarization sidecar)**:
```bash
pip install pyannote.audio torch torchaudio
```

### Configuration Files

| File | Purpose |
|------|---------|
| `Package.swift` or Xcode project | Swift dependencies |
| `requirements.txt` | Python diarization dependencies |
| `Info.plist` | macOS app configuration, permissions |
| `.entitlements` | Sandbox entitlements (audio, screen capture) |

### Verification

```bash
# 1. Verify Xcode
xcodebuild -version

# 2. Verify Swift
swift --version

# 3. Verify Python
python3 --version
python3 -c "import pyannote.audio; print('pyannote OK')"

# 4. Build and run
xcodebuild build -scheme TranscriptShadow
```

### Related IDs

- [TECH-001](#tech-001-swift-swiftui) - Swift + SwiftUI
- [TECH-006](#tech-006-pyannote-audio-diarization) - Python dependency

---

## Deprecated Decisions

_No deprecated decisions._

---

## Cross-Reference Index

**Decisions by Domain**:

- App Framework: TECH-001
- ML/AI: TECH-002, TECH-006
- Audio: TECH-003, TECH-004
- Export: TECH-005
- Storage: TECH-007
- Architecture: ARC-001, ARC-002, ARC-003
- Environment: ENV-001

---

## Update Protocol

### When to Add New IDs

1. **TECH-XXX**: Selecting a new technology, framework, or tool
2. **ARC-XXX**: Making a structural decision about system design
3. **ENV-XXX**: Documenting environment requirements

### Bidirectional Reference Checklist

When adding a new TECH/ARC/ENV-XXX:

- [ ] Update PRD.md v0.5/v0.6 section if applicable
- [ ] Update related API contracts if affected
- [ ] Update EPIC Section 2 "Context & IDs" list

---

*End of SoT.TECHNICAL_DECISIONS.md - Authoritative source for TECH-XXX, ARC-XXX, and ENV-XXX IDs*
