---
version: 1.0
purpose: Source of Truth for test specifications and coverage requirements.
id_prefix: TEST-XXX
last_updated: 2026-03-20
authority: This is a SoT file - IDs here are referenced by PRD.md, SoT.API_CONTRACTS.md, SoT.BUSINESS_RULES.md, EPICs
---

# Testing (SoT File)

> **Purpose**: Test case specifications for every API contract, business rule, and integration.
> **ID Prefix**: TEST-XXX
> **Status**: Active SoT file
> **Cross-References**: Referenced by PRD.md, SoT.API_CONTRACTS.md, SoT.BUSINESS_RULES.md, EPICs

## Navigation by Category

**Audio Service Tests** (TEST-001 to TEST-099):

- [TEST-001](#test-001-audio-capture-starts-and-stops) - Audio capture starts and stops
- [TEST-002](#test-002-audio-level-stream-emits-values) - Audio level stream emits values
- [TEST-003](#test-003-audio-mixer-produces-valid-wav) - Audio mixer produces valid WAV
- [TEST-004](#test-004-capture-respects-duration-limit) - Capture respects duration limit
- [TEST-005](#test-005-mic-only-fallback) - Mic-only fallback mode

**Transcription Tests** (TEST-101 to TEST-199):

- [TEST-101](#test-101-whisperkit-transcribes-sample-audio) - WhisperKit transcribes sample audio
- [TEST-102](#test-102-word-level-timestamps) - Word-level timestamps returned
- [TEST-103](#test-103-transcription-progress-callback) - Transcription progress callback
- [TEST-104](#test-104-model-download-and-cache) - Model download and cache

**Diarization Tests** (TEST-201 to TEST-299):

- [TEST-201](#test-201-sidecar-produces-valid-json) - Sidecar produces valid JSON
- [TEST-202](#test-202-single-speaker-detection) - Single speaker detection
- [TEST-203](#test-203-sidecar-progress-output) - Sidecar progress output
- [TEST-204](#test-204-sidecar-error-handling) - Sidecar error exit codes

**Formatter & Output Tests** (TEST-301 to TEST-399):

- [TEST-301](#test-301-speaker-labeled-markdown) - Speaker-labeled markdown output
- [TEST-302](#test-302-speaker-rename-propagation) - Speaker rename propagates
- [TEST-303](#test-303-timestamp-alignment) - Timestamp alignment accuracy

**Export & Storage Tests** (TEST-401 to TEST-499):

- [TEST-401](#test-401-obsidian-export-valid-markdown) - Obsidian export writes valid markdown
- [TEST-402](#test-402-frontmatter-valid-yaml) - Frontmatter is valid YAML
- [TEST-403](#test-403-transcript-persists-to-sqlite) - Transcript persists to SQLite
- [TEST-404](#test-404-full-text-search) - Full-text search works
- [TEST-405](#test-405-settings-persistence) - Settings persist and load

**Privacy & Lifecycle Tests** (TEST-501 to TEST-599):

- [TEST-501](#test-501-temp-audio-deleted-after-processing) - Temp audio deleted after processing
- [TEST-502](#test-502-temp-audio-deleted-on-cancel) - Temp audio deleted on cancel
- [TEST-503](#test-503-orphaned-audio-cleanup-on-launch) - Orphaned audio cleaned on launch
- [TEST-504](#test-504-no-network-calls-during-pipeline) - No network calls during pipeline

---

## Coverage Targets

| Category | Statement | Branch | Function | Line |
|----------|-----------|--------|----------|------|
| Pipeline Services | >= 85% | >= 80% | >= 90% | >= 85% |
| Data Layer (GRDB) | >= 80% | >= 75% | >= 85% | >= 80% |
| UI Layer (SwiftUI) | >= 60% | >= 55% | >= 70% | >= 60% |

---

## TEST-001: Audio Capture Starts and Stops

**ID**: TEST-001
**Category**: Unit (uses fakes; runs without hardware)
**Status**: Implemented (EPIC-02, 2026-05-06)
**Priority**: P0 (Critical)
**Created**: 2026-03-20
**Last Updated**: 2026-05-06

### Test Case (Given-When-Then)

**Given**: App has microphone permission
**When**: `startCapture(mic: true, systemAudio: false)` → wait 5s → `stopCapture()`
**Then**: Valid WAV file URL returned; `isCapturing` transitions false → true → false; `elapsedTime` ≈ 5s (±0.5s)

### Validates

- [API-001](SoT.API_CONTRACTS.md#api-001-audio-capture-service) - AudioCaptureService
- [FEA-001 in PRD](../PRD.md) - Audio Capture feature

### Implementation

**File**: `TranscriptShadowTests/Audio/DefaultAudioCaptureServiceTests.swift` (`test_TEST_001_startThenStop_returnsValidWAV_andTogglesIsCapturing`)
**Traceability**: `// @implements TEST-001`

---

## TEST-002: Audio Level Stream Emits Values

**ID**: TEST-002
**Category**: Unit
**Status**: Implemented (EPIC-02, 2026-05-06; covered also by `AudioLevelComputerTests` + EPIC-02b broadcast bus regression test)
**Priority**: P1
**Created**: 2026-03-20
**Last Updated**: 2026-05-07

### Test Case (Given-When-Then)

**Given**: Capture is active
**When**: `audioLevel()` stream is observed for 2 seconds
**Then**: Values in [0.0, 1.0]; >= 5 values/sec; stream terminates on stop

### Validates

- [API-001](SoT.API_CONTRACTS.md#api-001-audio-capture-service) - audioLevel()
- [DES-002](SoT.DESIGN_COMPONENTS.md#des-002-audio-level-indicator) - Level indicator

### Implementation

**File**: `TranscriptShadowTests/Audio/DefaultAudioCaptureServiceTests.swift` (`test_TEST_002_audioLevels_streamEmitsValuesInUnitRange`, `test_audioLevels_streamFinishes_whenCaptureStops`) + `TranscriptShadowTests/Audio/AudioLevelComputerTests.swift`
**Traceability**: `// @implements TEST-002`

---

## TEST-003: Audio Mixer Produces Valid WAV

**ID**: TEST-003
**Category**: Unit
**Status**: Implemented (EPIC-02, 2026-05-06)
**Priority**: P0 (Critical)
**Created**: 2026-03-20
**Last Updated**: 2026-05-06

### Test Case (Given-When-Then)

**Given**: Two PCM audio buffers (mic, system)
**When**: `AudioMixer.mix()` called
**Then**: Output WAV has correct header, matching sample rate, duration ≈ input, both sources audible

### Validates

- [API-002](SoT.API_CONTRACTS.md#api-002-audio-mixer) - AudioMixer

### Implementation

**File**: `TranscriptShadowTests/Audio/AudioMixerTests.swift` (`test_mix_writesValidWAV_andPreservesFrameCount`, `test_mix_unequalLengthBuffers_usesShorter`); dual-source path covered by `DefaultAudioCaptureServiceTests.test_dualSource_mixesMicAndSystemIntoOneFile`
**Traceability**: `// @implements TEST-003`

---

## TEST-004: Capture Respects Duration Limit

**ID**: TEST-004
**Category**: Unit (uses `FakeAudioCaptureClock` so the 2-hour limit fires in milliseconds)
**Status**: Implemented (EPIC-02, 2026-05-06; payload extended to `recordingFinalized` in EPIC-02b 2026-05-07)
**Priority**: P1
**Created**: 2026-03-20
**Last Updated**: 2026-05-07

### Test Case (Given-When-Then)

**Given**: Recording is active approaching 2-hour limit
**When**: Time reaches 1h50m and then 2h00m
**Then**: Warning at 1h50m; auto-stop at 2h00m; captured portion processed normally

### Validates

- [API-001](SoT.API_CONTRACTS.md#api-001-audio-capture-service) - Duration guard
- [BR-402](SoT.BUSINESS_RULES.md#br-402-maximum-meeting-duration) - Max duration rule

### Implementation

**File**: `TranscriptShadowTests/Audio/DefaultAudioCaptureServiceTests.swift` (`test_TEST_004_durationGuard_emitsWarningThenLimitAndAutoStops`, `test_durationAutoStop_emitsRecordingFinalized_withSavedURL`)
**Traceability**: `// @implements TEST-004`

---

## TEST-005: Mic-Only Fallback

**ID**: TEST-005
**Category**: Unit (uses fake `SystemAudioSource` injected with `screenRecordingPermissionDenied` error)
**Status**: Implemented (EPIC-02, 2026-05-06)
**Priority**: P1
**Created**: 2026-03-20
**Last Updated**: 2026-05-06

### Test Case (Given-When-Then)

**Given**: Screen Recording permission NOT granted
**When**: `startCapture(mic: true, systemAudio: true)` called
**Then**: Graceful degradation to mic-only; no crash; user informed

### Validates

- [API-001](SoT.API_CONTRACTS.md#api-001-audio-capture-service) - Graceful degradation
- [RISK-004 in PRD](../PRD.md) - Permission friction

### Implementation

**File**: `TranscriptShadowTests/Audio/DefaultAudioCaptureServiceTests.swift` (`test_TEST_005_systemAudioDenied_fallsBackToMicOnly`)
**Traceability**: `// @implements TEST-005`

---

## TEST-101: WhisperKit Transcribes Sample Audio

**ID**: TEST-101
**Category**: Unit (uses `FakeTranscriptionEngine`; the real-WhisperKit integration test is deferred — would require ~150 MB model download per run)
**Status**: Implemented (EPIC-03, 2026-05-08)
**Priority**: P0 (Critical)
**Created**: 2026-03-20
**Last Updated**: 2026-05-08

### Test Case (Given-When-Then)

**Given**: Known test WAV with clear English speech (pre-recorded fixture)
**When**: `transcribe(audioURL:model:progress:)` called with base.en model
**Then**: `segments` non-empty; text matches expected (>70% word overlap); `language` == "en"; `duration` ≈ audio length (±1s)

### Validates

- [API-101](SoT.API_CONTRACTS.md#api-101-transcription-service) - TranscriptionService
- [TECH-002](SoT.TECHNICAL_DECISIONS.md#tech-002-whisperkit-transcription) - WhisperKit

### Implementation

**File**: `TranscriptShadowTests/Transcription/DefaultTranscriptionServiceTests.swift` (`test_TEST_101_transcribe_returnsSegmentsAndLanguage`)
**Traceability**: `// @implements TEST-101`

---

## TEST-102: Word-Level Timestamps

**ID**: TEST-102
**Category**: Unit
**Status**: Implemented (EPIC-03, 2026-05-08)
**Priority**: P0 (Critical)
**Created**: 2026-03-20
**Last Updated**: 2026-05-08

### Test Case (Given-When-Then)

**Given**: Transcription result from TEST-101
**When**: Inspecting `segments[*].words`
**Then**: Non-nil, non-empty; timestamps monotonically increasing; all within [0, audio_duration]

### Validates

- [API-101](SoT.API_CONTRACTS.md#api-101-transcription-service) - Word timestamps
- [RISK-005 in PRD](../PRD.md) - Alignment depends on timestamps

### Implementation

**File**: `TranscriptShadowTests/Transcription/DefaultTranscriptionServiceTests.swift` (`test_TEST_102_wordTimestamps_areMonotonic`)
**Traceability**: `// @implements TEST-102`

---

## TEST-103: Transcription Progress Callback

**ID**: TEST-103
**Category**: Unit
**Status**: Implemented (EPIC-03, 2026-05-08)
**Priority**: P1
**Created**: 2026-03-20
**Last Updated**: 2026-05-08

### Test Case (Given-When-Then)

**Given**: Transcription in progress
**When**: Progress callback observed
**Then**: Fires >= 5 times; values in [0.0, 1.0] non-decreasing; final value == 1.0

### Validates

- [API-101](SoT.API_CONTRACTS.md#api-101-transcription-service) - Progress reporting
- [SCR-003](SoT.USER_JOURNEYS.md#scr-003-processing-view) - Progress UI

### Implementation

**File**: `TranscriptShadowTests/Transcription/DefaultTranscriptionServiceTests.swift` (`test_TEST_103_progressCallback_fires_monotonic_andEndsAtOne`)
**Traceability**: `// @implements TEST-103`

---

## TEST-104: Model Download and Cache

**ID**: TEST-104
**Category**: Unit (cache invariant tested via fake-engine load-call counter; on-disk download verified by `TranscriptionModelStoreTests`)
**Status**: Implemented (EPIC-03, 2026-05-08; service-side cache fix verified post-Codex review same day)
**Priority**: P1
**Created**: 2026-03-20
**Last Updated**: 2026-05-08

### Test Case (Given-When-Then)

**Given**: No cached Whisper model
**When**: TranscriptionService initialized
**Then**: Model files appear in Application Support; second init skips download

### Validates

- [INT-101](SoT.INTEGRATIONS.md#int-101-whisper-cpp-model-loading) - Model loading

### Implementation

**File**: `TranscriptShadowTests/Transcription/DefaultTranscriptionServiceTests.swift` (`test_TEST_104_prepare_isIdempotent_andTranscribeReuses`, `test_TEST_104_switchingModel_unloadsAndReloads`); model-folder layout covered by `TranscriptShadowTests/Transcription/TranscriptionModelStoreTests.swift`
**Traceability**: `// @implements TEST-104`

---

## TEST-201: Sidecar Produces Valid JSON

**ID**: TEST-201
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Multi-speaker test WAV (2-3 speakers, pre-recorded fixture)
**When**: `./diarize --audio test.wav --output speakers.json` invoked
**Then**: Exit code 0; JSON parses; `speakers` non-empty; each has speaker/start/end; start < end; segments cover full duration

### Validates

- [API-102](SoT.API_CONTRACTS.md#api-102-diarization-sidecar-cli) - CLI contract
- [ARC-002](SoT.TECHNICAL_DECISIONS.md#arc-002-python-sidecar-for-diarization) - Sidecar arch

### Implementation

**File**: `TranscriptShadowTests/DiarizationSidecarTests.swift`
**Traceability**: `// @implements TEST-201`

---

## TEST-202: Single Speaker Detection

**ID**: TEST-202
**Category**: Integration
**Status**: Planned
**Priority**: P1
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Single-speaker WAV fixture
**When**: Sidecar invoked
**Then**: `num_speakers` == 1; all segments same speaker key

### Validates

- [API-102](SoT.API_CONTRACTS.md#api-102-diarization-sidecar-cli) - Single speaker case

### Implementation

**File**: `TranscriptShadowTests/DiarizationSidecarTests.swift`
**Traceability**: `// @implements TEST-202`

---

## TEST-203: Sidecar Progress Output

**ID**: TEST-203
**Category**: Integration
**Status**: Planned
**Priority**: P1
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Diarization in progress
**When**: Parsing stdout lines
**Then**: Contains `PROGRESS:XX` lines; values 0-100; non-decreasing

### Validates

- [API-102](SoT.API_CONTRACTS.md#api-102-diarization-sidecar-cli) - Progress protocol
- [SCR-003](SoT.USER_JOURNEYS.md#scr-003-processing-view) - Progress UI

### Implementation

**File**: `TranscriptShadowTests/DiarizationSidecarTests.swift`
**Traceability**: `// @implements TEST-203`

---

## TEST-204: Sidecar Error Handling

**ID**: TEST-204
**Category**: Unit
**Status**: Planned
**Priority**: P1
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Invalid audio path OR corrupted file
**When**: Sidecar invoked
**Then**: Exit code 1; stderr contains error message; no crash/hang

### Validates

- [API-102](SoT.API_CONTRACTS.md#api-102-diarization-sidecar-cli) - Error contract

### Implementation

**File**: `TranscriptShadowTests/DiarizationSidecarTests.swift`
**Traceability**: `// @implements TEST-204`

---

## TEST-301: Speaker-Labeled Markdown

**ID**: TEST-301
**Category**: Unit
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: TranscriptionResult + DiarizationResult fixtures
**When**: `TranscriptFormatter.format()` called
**Then**: Markdown contains speaker labels (**Speaker 1**:), timestamps [HH:MM:SS], blank-line-separated turns, valid markdown

### Validates

- [API-201](SoT.API_CONTRACTS.md#api-201-transcript-formatter) - Formatter
- [BR-301](SoT.BUSINESS_RULES.md#br-301-markdown-output-format) - Markdown format

### Implementation

**File**: `TranscriptShadowTests/TranscriptFormatterTests.swift`
**Traceability**: `// @implements TEST-301`

---

## TEST-302: Speaker Rename Propagation

**ID**: TEST-302
**Category**: Unit
**Status**: Planned
**Priority**: P1
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Formatted transcript with SPEAKER_00
**When**: speakerNames map `["SPEAKER_00": "Alice"]` applied
**Then**: All SPEAKER_00 references replaced with "Alice"; speakerMap reflects rename

### Validates

- [API-201](SoT.API_CONTRACTS.md#api-201-transcript-formatter) - Speaker naming
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Rename flow

### Implementation

**File**: `TranscriptShadowTests/TranscriptFormatterTests.swift`
**Traceability**: `// @implements TEST-302`

---

## TEST-303: Timestamp Alignment

**ID**: TEST-303
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Transcription word timestamps + diarization speaker segments
**When**: Merge operation aligns words to speakers
**Then**: No word attributed outside its speaker's segment (±1.0s tolerance); overlapping speech and silence handled without crash

### Validates

- [API-201](SoT.API_CONTRACTS.md#api-201-transcript-formatter) - Alignment
- [RISK-005 in PRD](../PRD.md) - Alignment accuracy risk

### Implementation

**File**: `TranscriptShadowTests/TimestampAlignmentTests.swift`
**Traceability**: `// @implements TEST-303`

---

## TEST-401: Obsidian Export Valid Markdown

**ID**: TEST-401
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: FormattedTranscript + valid vault path
**When**: `ObsidianExporter.export()` called
**Then**: File at `vaultPath/subfolder/YYYY-MM-DD Title.md`; starts with YAML frontmatter; transcript body follows; UTF-8 encoded

### Validates

- [API-202](SoT.API_CONTRACTS.md#api-202-obsidian-exporter) - Export service
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Obsidian integration

### Implementation

**File**: `TranscriptShadowTests/ObsidianExporterTests.swift`
**Traceability**: `// @implements TEST-401`

---

## TEST-402: Frontmatter Valid YAML

**ID**: TEST-402
**Category**: Unit
**Status**: Planned
**Priority**: P1
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Exported markdown file
**When**: Parsing frontmatter between `---` markers
**Then**: Valid YAML; contains date, type, duration, speakers, source, tags; type == "meeting-transcript"; source == "transcript-shadow"

### Validates

- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Frontmatter template
- [BR-302](SoT.BUSINESS_RULES.md#br-302-obsidian-vault-compatibility) - Obsidian compat

### Implementation

**File**: `TranscriptShadowTests/ObsidianExporterTests.swift`
**Traceability**: `// @implements TEST-402`

---

## TEST-403: Transcript Persists to SQLite

**ID**: TEST-403
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Completed pipeline output
**When**: Transcript saved to database
**Then**: Row in `transcripts` with UUID; rows in `speakers` matching count; rows in `segments` in sequence order; FK relationships valid

### Validates

- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts) - Transcripts table
- [DBT-002](SoT.DATA_MODEL.md#dbt-002-speakers) - Speakers table
- [DBT-003](SoT.DATA_MODEL.md#dbt-003-segments) - Segments table

### Implementation

**File**: `TranscriptShadowTests/DatabaseTests.swift`
**Traceability**: `// @implements TEST-403`

---

## TEST-404: Full-Text Search

**ID**: TEST-404
**Category**: Unit
**Status**: Planned
**Priority**: P1
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Multiple transcripts in database
**When**: FTS query for a known phrase
**Then**: Matching transcript returned; partial word matches work; empty query returns empty

### Validates

- [DBT-001](SoT.DATA_MODEL.md#dbt-001-transcripts) - FTS index
- [SCR-006](SoT.USER_JOURNEYS.md#scr-006-transcript-history) - Search UI

### Implementation

**File**: `TranscriptShadowTests/DatabaseTests.swift`
**Traceability**: `// @implements TEST-404`

---

## TEST-405: Settings Persistence

**ID**: TEST-405
**Category**: Unit
**Status**: Planned
**Priority**: P1
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Settings store initialized
**When**: Write value → reinitialize store → read value
**Then**: Written value retrievable; unset keys return defaults; invalid JSON handled gracefully

### Validates

- [DBT-101](SoT.DATA_MODEL.md#dbt-101-app-settings) - Settings table

### Implementation

**File**: `TranscriptShadowTests/SettingsTests.swift`
**Traceability**: `// @implements TEST-405`

---

## TEST-501: Temp Audio Deleted After Processing

**ID**: TEST-501
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Pipeline completed successfully
**When**: Checking temp directory
**Then**: Temp WAV file no longer exists; deletion within 5s of completion

### Validates

- [API-301](SoT.API_CONTRACTS.md#api-301-temp-audio-cleanup) - Cleanup service
- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - No persistent audio
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Deletion rule

### Implementation

**File**: `TranscriptShadowTests/TempAudioCleanupTests.swift`
**Traceability**: `// @implements TEST-501`

---

## TEST-502: Temp Audio Deleted on Cancel

**ID**: TEST-502
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Recording in progress
**When**: User cancels
**Then**: Partial temp file deleted within 5s; no error thrown

### Validates

- [API-301](SoT.API_CONTRACTS.md#api-301-temp-audio-cleanup) - Cancel cleanup
- [BR-103](SoT.BUSINESS_RULES.md#br-103-audio-deletion-after-processing) - Deletion rule

### Implementation

**File**: `TranscriptShadowTests/TempAudioCleanupTests.swift`
**Traceability**: `// @implements TEST-502`

---

## TEST-503: Orphaned Audio Cleanup on Launch

**ID**: TEST-503
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Dummy `.wav` files placed in temp directory (simulating crash)
**When**: App launches
**Then**: Orphaned files deleted during startup; no user-visible error

### Validates

- [API-301](SoT.API_CONTRACTS.md#api-301-temp-audio-cleanup) - Orphan cleanup
- [ARC-003](SoT.TECHNICAL_DECISIONS.md#arc-003-temporary-audio-lifecycle) - Crash recovery
- [RISK-006 in PRD](../PRD.md) - Crash data loss risk

### Implementation

**File**: `TranscriptShadowTests/TempAudioCleanupTests.swift`
**Traceability**: `// @implements TEST-503`

---

## TEST-504: No Network Calls During Pipeline

**ID**: TEST-504
**Category**: Integration
**Status**: Planned
**Priority**: P0 (Critical)
**Created**: 2026-03-20

### Test Case (Given-When-Then)

**Given**: Network disabled (airplane mode equivalent)
**When**: Full pipeline executes (capture → transcribe → diarize → format → export)
**Then**: Pipeline completes successfully; no DNS lookups; no outbound connections

### Validates

- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Local-only
- [ARC-001](SoT.TECHNICAL_DECISIONS.md#arc-001-local-first-pipeline) - Pipeline arch

### Implementation

**File**: `TranscriptShadowTests/PrivacyTests.swift`
**Traceability**: `// @implements TEST-504`

---

## Deprecated Tests

_No deprecated tests._

---

## Cross-Reference Index

**Tests by API**:

- API-001: TEST-001, TEST-002, TEST-004, TEST-005
- API-002: TEST-003
- API-101: TEST-101, TEST-102, TEST-103
- API-102: TEST-201, TEST-202, TEST-203, TEST-204
- API-201: TEST-301, TEST-302, TEST-303
- API-202: TEST-401, TEST-402
- API-301: TEST-501, TEST-502, TEST-503

**Tests by Business Rule**:

- BR-101: TEST-504
- BR-102: TEST-501
- BR-103: TEST-501, TEST-502
- BR-301: TEST-301
- BR-302: TEST-402
- BR-402: TEST-004

**Tests by Priority**:

- P0 Critical: TEST-001, TEST-003, TEST-101, TEST-102, TEST-201, TEST-301, TEST-303, TEST-401, TEST-403, TEST-501, TEST-502, TEST-503, TEST-504
- P1: TEST-002, TEST-004, TEST-005, TEST-103, TEST-104, TEST-202, TEST-203, TEST-204, TEST-302, TEST-402, TEST-404, TEST-405

---

## Update Protocol

### When to Add New TEST-XXX IDs

1. **New API Contract**: Every API-XXX gets at least one TEST-XXX
2. **New Business Rule**: Every critical BR-XXX gets a validation test
3. **Bug Found**: Regression test added for each bug fix

### Bidirectional Reference Checklist

When adding a new TEST-XXX:

- [ ] Link to the API/BR/DBT it validates
- [ ] Add to the relevant EPIC's test phase
- [ ] Update cross-reference index above
- [ ] Add `// @implements TEST-XXX` in test file

---

*End of SoT.TESTING.md - Authoritative source for all TEST-XXX IDs*
