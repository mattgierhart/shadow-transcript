---
version: 1.0
purpose: Source of Truth for internal API/service contracts for Transcript Shadow.
id_prefix: API-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by PRD.md, SoT.USER_JOURNEYS.md, SoT.TESTING.md, EPICs, and code
---

# API Contracts (SoT File)

> **Purpose**: Internal service contracts for Transcript Shadow (local app, no HTTP APIs).
> **ID Prefix**: API-XXX
> **Status**: Active SoT file
> **Note**: Transcript Shadow is a local macOS app — these are internal Swift service interfaces and the diarization sidecar CLI contract, not HTTP endpoints.

## Navigation by Category

**Audio Services** (API-001 to API-099):

- [API-001](#api-001-audio-capture-service) - Audio Capture Service
- [API-002](#api-002-audio-mixer) - Audio Mixer (mic + system)

**Transcription Services** (API-101 to API-199):

- [API-101](#api-101-transcription-service) - Transcription Service (WhisperKit)
- [API-102](#api-102-diarization-sidecar-cli) - Diarization Sidecar CLI

**Output Services** (API-201 to API-299):

- [API-201](#api-201-transcript-formatter) - Transcript Formatter
- [API-202](#api-202-obsidian-exporter) - Obsidian Exporter

**Background Jobs** (API-301 to API-399):

- [API-301](#api-301-temp-audio-cleanup) - Temp Audio Cleanup

---

## API-001: Audio Capture Service

**ID**: API-001
**Category**: Internal
**Status**: Implemented (EPIC-02, 2026-05-06; hardened by EPIC-02b, 2026-05-07)
**Created**: 2026-03-11
**Last Updated**: 2026-05-07

### Specification

**Type**: Swift protocol + actor
**Interface**: `AudioCaptureService` (protocol) + `DefaultAudioCaptureService` (actor)

### Purpose

Manage microphone and system audio capture, producing a mixed WAV file for downstream processing.

### Interface

```swift
public protocol AudioCaptureService: Sendable {
    func startCapture(configuration: AudioCaptureConfiguration) async throws
    @discardableResult
    func stopCapture() async throws -> URL
    func audioLevels() -> AsyncStream<Float>             // 0.0–1.0, ~10 Hz; finishes on stop
    func milestones() -> AsyncStream<AudioCaptureMilestone>  // broadcast, service-lifetime
    var isCapturing: Bool { get async }
    var elapsedTime: TimeInterval { get async }
}

public struct AudioCaptureConfiguration: Sendable, Equatable {
    public var captureMicrophone: Bool        // default true
    public var captureSystemAudio: Bool       // default true
    public var maximumDuration: TimeInterval  // default 7200 (BR-402)
    public var warningDuration: TimeInterval  // default 6600
    public var sampleRate: Double             // default 48_000
    // Output is always mono — see AudioCaptureConfiguration.outputChannelCount.
}

public enum AudioCaptureMilestone: Sendable, Equatable {
    case durationWarningReached
    case durationLimitReached
    case systemAudioFellBackToMicOnly(reason: String)
    /// Emitted after the WAV is finalized on disk (mixed if dual-source).
    /// Fires for both user-initiated and duration-limit auto-stops so
    /// subscribers don't need to differentiate between the two paths.
    case recordingFinalized(url: URL, reason: AudioCaptureFinalizationReason)
}

public enum AudioCaptureFinalizationReason: Sendable, Equatable {
    case userRequested
    case durationLimitReached
}
```

### Notes vs. Original Sketch

The original v0.6 sketch took `(mic: Bool, systemAudio: Bool)` parameters and exposed a single `audioLevel()` stream. The implemented signature wraps both into `AudioCaptureConfiguration` (extensible without breaking callers) and adds a `milestones()` stream so the UI can react to BR-402 warnings/limits and to system-audio fallback events without polling. EPIC-02b added `recordingFinalized` so duration-limit auto-stops surface their saved URL alongside user-initiated stops, and made both streams broadcast-safe via internal `LevelBus` / `MilestoneBus` helpers. `channelCount` was removed from the public configuration since the output is always mono (the only format the downstream transcription pipeline accepts).

### Related IDs

- [TECH-003](SoT.TECHNICAL_DECISIONS.md#tech-003-avaudioengine-audio-capture) - Microphone tech
- [TECH-004](SoT.TECHNICAL_DECISIONS.md#tech-004-screencapturekit-system-audio) - System audio tech
- [UJ-001](SoT.USER_JOURNEYS.md#uj-001-record-and-transcribe-meeting) - Recording journey
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Duration limit

---

## API-002: Audio Mixer

**ID**: API-002
**Category**: Internal
**Status**: Implemented (EPIC-02, 2026-05-06)
**Created**: 2026-03-11
**Last Updated**: 2026-05-06

### Specification

**Type**: Swift utility
**Interface**: `AudioMixer`

### Purpose

Mix microphone and system audio streams into a single WAV file suitable for transcription and diarization.

### Interface

```swift
public enum AudioMixer {
    public static func mix(
        microphoneBuffer micBuffer: AVAudioPCMBuffer,
        systemBuffer: AVAudioPCMBuffer,
        sampleRate: Double = 48_000,
        to outputURL: URL
    ) throws
}
```

The mixer downmixes both inputs to mono and sums them with 0.5 attenuation per source so the result stays inside `[-1, 1]` without hard clipping. Output file format: 32-bit float, mono, 48 kHz, RIFF WAV. (SoT did not lock these values; they were chosen because WhisperKit ingests this format with no resampling.)

### Related IDs

- [API-001](#api-001-audio-capture-service) - Upstream capture
- [API-101](#api-101-transcription-service) - Downstream consumer

---

## API-101: Transcription Service

**ID**: API-101
**Category**: Internal
**Status**: Implemented (EPIC-03, 2026-05-08)
**Created**: 2026-03-11
**Last Updated**: 2026-05-08

### Specification

**Type**: Swift protocol + actor
**Interface**: `TranscriptionService` (protocol) + `DefaultTranscriptionService` (actor)

### Purpose

Transcribe audio file to text with word-level timestamps using WhisperKit.

### Interface

```swift
public protocol TranscriptionService: Sendable {
    /// Loads the requested model into memory; downloads on first use.
    /// Idempotent for the same model.
    func prepare(model: WhisperModel) async throws

    /// Transcribes the WAV at `audioURL`. The progress closure receives
    /// monotonic fractional values in [0, 1] and is guaranteed to fire at
    /// least once with 0.0 at the start and 1.0 on success. English-only
    /// per BR-202; entirely on-device per BR-101.
    func transcribe(
        audioURL: URL,
        model: WhisperModel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript

    var loadedModel: WhisperModel? { get async }
}

public struct Transcript: Sendable, Equatable {
    public let segments: [TranscriptSegment]
    public let language: String
    public let duration: TimeInterval
    public let model: WhisperModel
    public var text: String { /* segment text joined with spaces */ }
    public var allWords: [WordTimestamp] { /* flattened */ }
}

public struct TranscriptSegment: Sendable, Equatable {
    public let text: String
    public let start: TimeInterval
    public let end: TimeInterval
    public let words: [WordTimestamp]   // empty if engine did not produce them
}

public struct WordTimestamp: Sendable, Equatable {
    public let word: String
    public let start: TimeInterval
    public let end: TimeInterval
}

public enum WhisperModel: String, Sendable, CaseIterable {
    case baseEN = "openai_whisper-base.en"     // ~148 MB, default
    case smallEN = "openai_whisper-small.en"   // ~488 MB
    case mediumEN = "openai_whisper-medium.en" // ~1.5 GB
}
```

### Notes vs. Original Sketch

The v0.6 sketch named the return type `TranscriptionResult` and made `words` optional. The implementation renames the return type to `Transcript` because WhisperKit exports its own top-level `TranscriptionResult` from a same-named module — `import WhisperKit` shadows the module name with the class name and the qualified form `WhisperKit.TranscriptionResult` no longer resolves to the module's top-level type. Renaming our type to `Transcript` removes the ambiguity. The `words` array was made non-optional (empty when missing) because every consumer immediately defaulted nil to empty anyway. `prepare(model:)` was added so the UI (EPIC-07) can warm up a model during onboarding without immediately requesting a transcription.

### Related IDs

- [TECH-002](SoT.TECHNICAL_DECISIONS.md#tech-002-whisperkit-transcription) - WhisperKit
- [ARC-001](SoT.TECHNICAL_DECISIONS.md#arc-001-local-first-pipeline) - Pipeline stage
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Local only

---

## API-102: Diarization Sidecar CLI

**ID**: API-102
**Category**: Internal (subprocess)
**Status**: Planned
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Specification

**Type**: CLI executable (PyInstaller-bundled Python)
**Binary**: `TranscriptShadow.app/Contents/Resources/diarize`

### Purpose

Identify speaker segments in audio using pyannote-audio. Called as a subprocess by the Swift app.

### Interface

**Invocation**:
```bash
./diarize --audio /path/to/audio.wav --output /path/to/speakers.json [--num-speakers N]
```

**Output** (`speakers.json`):
```json
{
  "speakers": [
    {"speaker": "SPEAKER_00", "start": 0.5, "end": 12.3},
    {"speaker": "SPEAKER_01", "start": 12.5, "end": 25.1}
  ],
  "num_speakers": 2
}
```

**Exit Codes**: 0 = success, 1 = error (stderr contains message)

**Progress**: Writes progress percentage to stdout (e.g., `PROGRESS:45`)

### Related IDs

- [TECH-006](SoT.TECHNICAL_DECISIONS.md#tech-006-pyannote-audio-diarization) - pyannote
- [ARC-002](SoT.TECHNICAL_DECISIONS.md#arc-002-python-sidecar-for-diarization) - Sidecar architecture
- [FEA-003 in PRD](../PRD.md) - Diarization feature

---

## API-201: Transcript Formatter

**ID**: API-201
**Category**: Internal
**Status**: Planned
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Specification

**Type**: Swift service
**Interface**: `TranscriptFormatter`

### Purpose

Merge transcription results with diarization speaker segments. Produce formatted markdown with speaker labels and timestamps.

### Interface

```swift
protocol TranscriptFormatter {
    func format(transcription: TranscriptionResult,
                diarization: DiarizationResult,
                speakerNames: [String: String]?) -> FormattedTranscript
}

struct FormattedTranscript {
    let markdown: String
    let metadata: TranscriptMetadata
    let speakerMap: [String: String]  // SPEAKER_00 → "Alice"
}
```

### Related IDs

- [API-101](#api-101-transcription-service) - Upstream transcription
- [API-102](#api-102-diarization-sidecar-cli) - Upstream diarization
- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format) - Markdown format

---

## API-202: Obsidian Exporter

**ID**: API-202
**Category**: Internal
**Status**: Planned
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Specification

**Type**: Swift service
**Interface**: `ObsidianExporter`

### Purpose

Write formatted transcript to Obsidian vault directory with proper frontmatter and file naming.

### Interface

```swift
protocol ObsidianExporter {
    func export(transcript: FormattedTranscript,
                vaultPath: URL,
                subfolder: String?) throws -> URL  // Returns written file path
}
```

### Related IDs

- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Obsidian integration
- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Compatibility rules
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Export journey

---

## API-301: Temp Audio Cleanup

**ID**: API-301
**Category**: Background
**Status**: Planned
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Specification

**Type**: Swift background job
**Interface**: `TempAudioCleanup`

### Purpose

Ensure temporary audio files are deleted after processing completes, on cancellation, app quit, or crash recovery.

### Interface

```swift
struct TempAudioCleanup {
    static func cleanupAfterProcessing(audioURL: URL) throws
    static func cleanupOnCancel(audioURL: URL) throws
    static func cleanupOrphanedFiles() throws  // Called on app launch
}
```

### Related IDs

- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - No persistent audio
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Deletion rules
- [ARC-003](SoT.TECHNICAL_DECISIONS.md#arc-003-temporary-audio-lifecycle) - Lifecycle architecture

---

## Deprecated Endpoints

_No deprecated endpoints._

---

## Cross-Reference Index

**Services by Journey**:

- UJ-001 calls: API-001, API-002, API-101, API-102, API-201, API-301
- UJ-002 calls: API-202
- UJ-003 configures: API-001, API-202

**Services by Pipeline Stage**:

- Capture: API-001, API-002
- Process: API-101, API-102
- Output: API-201, API-202
- Cleanup: API-301

---

## Update Protocol

### When to Add New API-XXX IDs

1. **New Service**: Internal service interface
2. **New Sidecar Command**: CLI contract for subprocess
3. **New Background Job**: Scheduled or triggered task

### Bidirectional Reference Checklist

When adding a new API-XXX:

- [ ] Update SoT.USER_JOURNEYS.md "APIs Used" section
- [ ] Update SoT.BUSINESS_RULES.md if rule is enforced
- [ ] Update SoT.TESTING.md with service tests
- [ ] Update EPIC Section 2 "Context & IDs" list

---

*End of SoT.API_CONTRACTS.md - Authoritative source for all API-XXX IDs*
