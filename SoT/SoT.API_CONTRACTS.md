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
**Status**: Implemented (full — Python sidecar + Swift `DiarizationService` bridge).
**Created**: 2026-03-11
**Last Updated**: 2026-05-09 (EPIC-04b)

### Specification

**Type**: CLI executable (PyInstaller `--onedir` bundle of Python 3.11)
**Binary**: `TranscriptShadow.app/Contents/Resources/diarize/diarize`
**Source**: `sidecar/diarize.py` + `sidecar/diarize.spec`
**Cross-language conformance fixture**: `sidecar/test_fixtures/golden-3spk.json`

### Purpose

Identify speaker segments in audio using `pyannote.audio` 4.x and the
gated `pyannote/speaker-diarization-community-1` model. Called as a
subprocess by the Swift app (EPIC-04b).

### Interface

**Invocation**:
```bash
./diarize --audio <PATH> --output <PATH>
          [--model pyannote/speaker-diarization-community-1]
          [--num-speakers <int>]
          [--hf-token <str>]
```

The `TRANSCRIPT_SHADOW_AUDIO_BOOKMARK` env var is reserved for an
EPIC-04b security-scoped-bookmark hand-off. The current binary errors
with a deferred-implementation message if it sees the env without
`--audio`; the EPIC-04b parent resolves the bookmark and passes
`--audio` with the resolved path.

The `--hf-token` flag wins over the `HF_TOKEN` env var. Required only
on first download of the gated community-1 model; subsequent runs read
from `~/Library/Caches/ai.gearheart.TranscriptShadow/huggingface/`.

### Output (frozen schema, version 1.0)

Written to the file at `--output`, NOT to stdout. Stdout is reserved
for `PROGRESS:` lines so the JSON payload never intermixes.

```json
{
  "version": "1.0",
  "audio": {
    "path": "/abs/path/to/meeting.wav",
    "duration_seconds": 312.4
  },
  "model": {
    "name": "pyannote/speaker-diarization-community-1",
    "revision": "<commit-or-version>"
  },
  "speakers": [
    {"id": "SPEAKER_00", "total_seconds": 145.2},
    {"id": "SPEAKER_01", "total_seconds": 98.6}
  ],
  "segments": [
    {"speaker": "SPEAKER_00", "start": 0.0, "end": 4.235},
    {"speaker": "SPEAKER_01", "start": 4.235, "end": 7.18}
  ],
  "overlapping_segments": [
    {"speaker": "SPEAKER_00", "start": 4.0, "end": 4.5},
    {"speaker": "SPEAKER_01", "start": 4.235, "end": 4.5}
  ],
  "elapsed_seconds": 31.2,
  "warnings": []
}
```

`segments` is the exclusive_speaker_diarization view (no overlaps,
preferred for transcription alignment in EPIC-05). `overlapping_segments`
is the speaker_diarization view (allowing simultaneous speakers).
Floats round to 3 decimal places. `speakers` is sorted by id for
deterministic output. `warnings` is reserved for non-fatal issues
(e.g., "fewer than min_speakers detected"); may be empty.

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success — JSON written to `--output`. |
| `1` | Audio file unreadable / missing / bookmark env unsupported. |
| `2` | Model load failed (non-auth). |
| `3` | HF auth required (gated model, no token, not cached). |
| `4` | Out of memory. |

### Progress

`PROGRESS:0.42` lines on stdout. Format regex `^PROGRESS:(\d+(?:\.\d+)?)$`.
Two decimals. Clamped to `[0.0, 1.0]`. Emitted at pyannote pipeline
checkpoints; `main()` adds `PROGRESS:0.00` and `PROGRESS:1.00` book-ends
so the consumer sees ≥2 lines on every successful run.

### Errors

`ERROR:<code>:<message>` lines on stderr (regex `^ERROR:(\d+):(.+)$`).
Newlines and carriage returns in messages are stripped so the line
parser always sees one error per line.

### Related IDs

- [TECH-006](SoT.TECHNICAL_DECISIONS.md#tech-006-pyannote-audio-diarization) - pyannote.audio
- [ARC-002](SoT.TECHNICAL_DECISIONS.md#arc-002-python-sidecar-for-diarization) - Sidecar architecture
- [INT-201](SoT.INTEGRATIONS.md#int-201-pyannote-diarization) - pyannote integration
- [FEA-003 in PRD](../PRD.md) - Diarization feature
- TEST-201, TEST-202, TEST-203, TEST-204 (all Implemented; see SoT.TESTING.md)

### Swift consumer (EPIC-04b)

The Swift side parses the JSON envelope into `DiarizationResult` (Codable)
and exposes the contract through `DiarizationService`:

```swift
public protocol DiarizationService: Sendable {
    func diarize(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> DiarizationResult
}
```

Production implementation: `PyannoteSidecarDiarizationService` (final
class, `@unchecked Sendable`, parallel to `WhisperKitEngine`'s pattern).
Spawns the bundled binary via Foundation `Process`, streams stdout via
`FileHandle.bytes.lines` to forward `PROGRESS:` lines to the caller's
closure, parses stderr for typed `DiarizationError` mapping. All calls
go through `AsyncTaskQueue` so concurrent diarizations cannot share the
pipeline's memory footprint. Cancellation propagates as SIGTERM (with a
5 s grace period before SIGKILL on genuine timeout).

The cross-language contract is golden-3spk.json — the Swift Codable
type must decode that file unchanged.

### Lessons learned (EPIC-04a Codex Gate 1 + EPIC-04b Codex Gate 2)

- pyannote 4.0.0 doesn't accept hand-pinned `torch>=2.4,<2.5` — let the
  pipeline package's own metadata pull transitive deps. Hand-pinning
  caused a P0 install failure in initial requirements.txt.
- pyannote's bundled `ProgressHook` writes rich progress bars to
  stdout — would have collided with our `PROGRESS:` line contract if
  forwarded. Our adapter emits PROGRESS lines directly without
  delegating.
- Bookmark resolution in pure Python is impossible without Foundation
  APIs. EPIC-04b's parent resolves and passes `--audio`; the env var
  contract surface exists only as a deferred-implementation error.
- `AsyncTaskQueue` had a P0 race between reading `tail` and writing the
  new tail under separate locks. Two concurrent enqueues could capture
  the same predecessor and run concurrently — defeating the queue.
  Fixed in EPIC-04b with a single critical section.
- `Foundation.Process` cancellation does not propagate through an
  unstructured `Task`'s `await ... .value`. The queue now wraps that
  await in `withTaskCancellationHandler` and explicitly cancels the
  outcome task on the cancel handler.
- `Process.environment` — passing the full parent env wholesale leaks
  test runner / Xcode env vars into the child. Codex Gate 2 P1 fix:
  whitelist (PATH/HOME/TMPDIR/locale/HF_*/NUMBA_CACHE_DIR/
  TRANSCRIPT_SHADOW_AUDIO_BOOKMARK).
- `parseProgress` cannot rely on `Double()` alone — it accepts `inf`,
  `nan`, exponents, and whitespace-padded forms. The contract regex
  `^PROGRESS:(\d+(?:\.\d+)?)$` must be enforced manually.
- `Task.sleep` throws on cancellation; `try? await Task.sleep` in a
  polling loop without throttle creates a busy-spin in cancelled tasks.
  Wrap such loops in `Task.detached` to escape the parent's
  cancellation context when the wait MUST complete.
- macOS hardened-runtime + sandbox + a PyInstaller bundle requires
  `cs.disable-library-validation` + `cs.allow-unsigned-executable-memory`
  + `cs.allow-jit` on the parent. Child binary is `inherit=true` only.
  `get-task-allow` (auto-injected in Debug) crashes the child via
  `_libsecinit_appsandbox` and must be stripped at codesign time.

---

## API-201: Transcript Formatter

**ID**: API-201
**Category**: Internal
**Status**: Implemented (EPIC-05, 2026-05-12)
**Created**: 2026-03-11
**Last Updated**: 2026-05-12

### Specification

**Type**: Swift service
**Interface**: `TranscriptFormatter` (protocol) + `DefaultTranscriptFormatter` (struct)

### Purpose

Merge transcription word timestamps with diarization speaker segments. Produce body markdown with speaker labels and timestamps plus metadata for downstream storage. YAML frontmatter and Obsidian-vault file write are out of scope — that's API-202.

### Interface

```swift
public protocol TranscriptFormatter: Sendable {
    func format(
        transcription: Transcript,
        diarization: DiarizationResult,
        speakerNames: [String: String]
    ) throws -> FormattedTranscript
}

public struct FormattedTranscript: Codable, Sendable, Equatable {
    public let markdown: String
    public let metadata: TranscriptMetadata
    public let speakerMap: [String: String]   // canonical SPEAKER_xx → display name
    public let warnings: [String]
    public let turns: [TranscriptTurn]
}

public struct TranscriptTurn: Codable, Sendable, Equatable {
    public let canonicalSpeaker: String       // matches DBT-002 speaker_key
    public let displayName: String
    public let startSeconds: TimeInterval
    public let endSeconds: TimeInterval
    public let text: String
}

public struct TranscriptMetadata: Codable, Sendable, Equatable {
    public let durationSeconds: Int           // matches DBT-001 column shape
    public let speakerCount: Int              // matches DBT-001
    public let language: String
    public let model: WhisperModel
    public let wordCount: Int
    public let turnCount: Int
}

public enum FormatterError: Error, Equatable {
    case invalidSpeakerSegment(start: TimeInterval, end: TimeInterval)
}
```

### Notes vs. Original Sketch

The v0.6 sketch named the first parameter `transcription: TranscriptionResult` and made `speakerNames` optional (`[String: String]?`). The implementation uses `transcription: Transcript` because EPIC-03 shipped the WhisperKit-disambiguating rename (see API-101's "Notes vs. Original Sketch" — `import WhisperKit` shadows `TranscriptionResult`). `speakerNames` was made non-optional with a `[:]` default via a protocol extension; every call site converted `nil` to `[:]` anyway, and dropping optionality removes a needless branch. The sketch also omitted `FormattedTranscript.warnings` — added during EPIC-05 to surface (a) `DiarizationResult.warnings` passthrough and (b) the formatter's own diagnostics (boundary-word straddles, single-speaker fallback when diarization returned zero segments). `TranscriptMetadata` was fully specified in EPIC-05; `durationSeconds` is `Int` (rounded) to match DBT-001's `INTEGER` column shape so EPIC-06 can copy fields directly.

**EPIC-06 extension (2026-05-12)**: `FormattedTranscript.turns: [TranscriptTurn]` was added to expose the per-turn structure used to render `markdown`. EPIC-06's `TranscriptStore.save` populates DBT-002 (speakers) and DBT-003 (segments) from this without re-deriving from the raw `Transcript`/`DiarizationResult`. `TranscriptTurn.canonicalSpeaker` matches DBT-002 `speaker_key` for the FK join.

### Algorithm Notes (RISK-005)

Alignment is midpoint-greedy: for each `WordTimestamp`, `midpoint = (start + end) / 2`; find the unique segment in `diarization.segments` (exclusive view; `overlappingSegments` is deferred) where `segment.start <= midpoint < segment.end`. Boundary straddles (word.start in segment A, word.end in segment B) keep the midpoint attribution but emit one warning at the end. No-match midpoints attribute to canonical `SPEAKER_UNKNOWN` (displayed as `"Speaker ?"`). Empty `words` on a `TranscriptSegment` falls back to segment-level midpoint attribution. Zero diarization segments fall back to a synthesized single-speaker turn. Invalid segments (`end <= start`) throw `FormatterError.invalidSpeakerSegment`.

Default speaker display names are 1-indexed by first appearance in `diarization.segments` (`"Speaker 1"`, `"Speaker 2"`, …). Caller-supplied `speakerNames` overrides win.

### Related IDs

- [API-101](#api-101-transcription-service) - Upstream transcription
- [API-102](#api-102-diarization-sidecar-cli) - Upstream diarization
- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format) - Markdown format
- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts-table) - downstream storage shape
- RISK-005 (in PRD.md) - alignment accuracy

---

## API-202: Obsidian Exporter

**ID**: API-202
**Category**: Internal
**Status**: Implemented (EPIC-06, 2026-05-12)
**Created**: 2026-03-11
**Last Updated**: 2026-05-12

### Specification

**Type**: Swift service
**Interface**: `ObsidianExporter` (protocol) + `DefaultObsidianExporter` (final class)

### Purpose

Write a `FormattedTranscript` body (BR-301) to an Obsidian vault directory as a `.md` file with YAML frontmatter (INT-001) and an Obsidian-safe filename (BR-302). Pure I/O — no DB writes; `TranscriptStore.markExported` records the returned `URL`.

### Interface

```swift
public protocol ObsidianExporter: Sendable {
    func export(
        transcript: FormattedTranscript,
        title: String,
        date: Date,
        vaultPath: URL,
        subfolder: String?
    ) throws -> URL
}

public enum ObsidianExportError: Error, Equatable {
    case vaultPathNotADirectory(URL)
    case fileExists(URL)
    case writeFailed(path: String, underlying: String)
}
```

### Notes vs. Original Sketch

The sketch elided `title` and `date` — they're separate parameters in the impl because the user-facing title is editable after recording and the recording date is not a property of `FormattedTranscript` (which carries `metadata.durationSeconds` but not a wall-clock anchor). The `ObsidianExportError` enum + `overwriteExisting` flag on `DefaultObsidianExporter`'s init were added for the EPIC-08 orchestrator's failure semantics. Filename sanitization is delegated to `MarkdownFilenameSanitizer` (per BR-302); duration is rendered as `MM:SS` (or `H:MM:SS`) matching INT-001's example. Subfolder is created on demand.

### Related IDs

- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Obsidian integration
- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Compatibility rules
- [API-201](#api-201-transcript-formatter) - Source `FormattedTranscript`
- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts-table) - `exported_path` column updated post-export
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Export journey

---

## API-301: Temp Audio Cleanup

**ID**: API-301
**Category**: Background
**Status**: Implemented (2026-05-17, EPIC-08)
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
