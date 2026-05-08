---
template_version: "3.0.0"
---

# EPIC-03 Transcription Pipeline

> **State**: `✅ Complete`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: Claude Agent (session: 2026-05-08)
> **Depends On**: EPIC-01, EPIC-02b

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-08 — Implemented `TranscriptionService` protocol + `DefaultTranscriptionService` actor + internal `TranscriptionEngine` seam + production `WhisperKitEngine` (final class wrapping WhisperKit 0.18.0). Per Codex's path-forward, the service accepts any readable WAV URL (validates via `AVAudioFile`), normalizes language to English internally (BR-202), and is not coupled to `DefaultAudioCaptureService`. 35/35 tests green; transcription tests substitute `FakeTranscriptionEngine` so the suite never touches the real WhisperKit weights.
- **Stopping Point**: All Phase A–E deliverables ticked. EPIC-03 closed.
- **Next Steps**: EPIC-04 (Speaker Diarization Sidecar). Codex recommends starting with a CLI/benchmark spike on `pyannote.audio` (proving accuracy + JSON shape + PyInstaller bundling) *before* building the Swift `Process` bridge, treating those as separable scopes.
- **Context**: Public surface is the `TranscriptionService` protocol returning `Transcript` (renamed from `TranscriptionResult` because WhisperKit exports a top-level type with that exact name from a same-named module — see Agent Observation #1). Models live at `~/Library/Application Support/TranscriptShadow/Models/`; WhisperKit downloads on first `prepare(_:)` call.

---

## Objective & Scope

> **Goal**: Wrap WhisperKit into a TranscriptionService that transcribes WAV → segments with word-level timestamps, with model download/cache management.

- **Deliverables**:
  - [x] `TranscriptionService` protocol (API-101) + `DefaultTranscriptionService` actor + `WhisperKitEngine` final class (production engine).
  - [x] Model download on first launch + cache management (INT-101) — `TranscriptionModelStore` owns `~/Library/Application Support/TranscriptShadow/Models/`; WhisperKit downloads on first `prepare(_:)`. Service-level cache short-circuits repeat `prepare` calls (TEST-104).
  - [x] Progress callback during transcription — `progress: @escaping @Sendable (Double) -> Void`. `WhisperKitEngine` maps WhisperKit's elapsed-pipeline-seconds signal into a monotonic `[0, 1]` fraction via `ProgressBox`.
  - [x] `Transcript` (renamed from SoT's `TranscriptionResult` to avoid the WhisperKit module/class name collision) + `TranscriptSegment` + `WordTimestamp` data types.
  - [x] Tests: TEST-101, TEST-102, TEST-103, TEST-104 (12 transcription tests total, all green).
- **Out of Scope**: Diarization (EPIC-04), multi-language, streaming/real-time, an integration test that loads real WhisperKit weights (deferred — would require ~150 MB model download per CI run).

---

## Context & IDs

- **APIs**: API-101
- **Integrations**: INT-101
- **Tech**: TECH-002
- **Business Rules**: BR-101, BR-202
- **Features**: FEA-002
- **Tests**: TEST-101, TEST-102, TEST-103, TEST-104

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [x] **Context Loaded**: Read API-101, TECH-002, INT-101, BR-101, BR-202; pulled WhisperKit 0.18 docs via Context7 for the actual current API surface.
- [x] **Strategy**: Define a public protocol mirroring the SoT, slot in an internal `TranscriptionEngine` seam so unit tests substitute fakes (per Codex's "don't couple WhisperKit to `DefaultAudioCaptureService`" recommendation), implement the production engine using WhisperKit. Service validates the audio URL, gates the engine on its own loaded model, normalizes the request to English (BR-202).

### Phase B: Design

- [x] Reviewed WhisperKit 0.18.x via Context7: `WhisperKit(model:modelFolder:load:)` + `transcribe(audioPath:decodeOptions:_:)` returning `[WhisperKit.TranscriptionResult]`; progress callback receives elapsed pipeline seconds (not a fraction).
- [x] Decided on synthetic fixture WAVs (`FixtureWAV.make`) for unit tests — the real-WhisperKit integration test path is deferred per Out-of-Scope above.

### Phase C: Build

**Context Window 1: Model Management**

- [x] `TranscriptionModelStore` owns the Application Support `Models/` directory; resolves per-variant subdirectories matching WhisperKit's naming.
- [x] `WhisperKit(model:modelFolder:load:)` initializer wired so first call downloads + caches.
- [x] Model selection via `WhisperModel` enum (`baseEN` default, plus `smallEN`, `mediumEN`).
- [x] Cache short-circuit at the service boundary (`loadIfNeeded`) and again in the engine.
- [x] **Test**: TEST-104 ✅ (idempotent prepare, switching models reloads).

**Context Window 2: Transcription Service**

- [x] `TranscriptionService` protocol + `DefaultTranscriptionService` actor.
- [x] `WhisperKitEngine` wraps the SDK; `ProgressBox` clamps WhisperKit's elapsed-pipeline-seconds into a monotonic `[0, 1]` fraction; service emits `0.0` at start and `1.0` on success on top.
- [x] Error mapping: missing/unreadable audio, model load/download failures, generic transcription failures, cancellation.
- [x] **Test**: TEST-101 ✅, TEST-102 ✅, TEST-103 ✅ + 5 supporting tests (audio validation paths, error propagation, switching models, cache short-circuit, etc.).

### Phase D: Validate

- [x] All 4 TEST-XXX cases pass; total transcription test count is 12 (12/12 green).
- [ ] **Deferred**: Manual end-to-end transcription with a real meeting clip (gates EPIC-04 + EPIC-07 — easier to validate once UI exists).
- [x] Code traceability: `// @implements API-101` markers across the module.

### Phase E: Finish (Harvest)

- [x] SoT.API_CONTRACTS.md API-101 updated — status `Implemented`, interface reflects the actual `Transcript` type + `prepare(_:)` method.
- [x] Session audit complete.

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | **Naming collision**: WhisperKit's module *and* class share the name `WhisperKit`, and the module also exports a top-level `TranscriptionResult` struct. With both `import WhisperKit` and our own `TranscriptionResult` in scope, the class shadows the module name, so `WhisperKit.TranscriptionResult` parses as "nested type of class WhisperKit" and fails to compile. Renamed our type to `Transcript` to remove the ambiguity entirely. | Document the choice in `Transcript.swift` header. SoT API-101 already reflects the rename. | Resolved |
| 2 | **Swift 6 strict concurrency × non-Sendable WhisperKit**: An `actor` engine generated "sending 'whisperKit' risks causing data races" on every `await whisperKit.transcribe(...)`. Switched the engine from `actor` to `final class` with `NSLock` — same serialization invariants without Swift's actor-isolation analysis flagging the SDK call. | Pattern to reuse for any future SDK that isn't Sendable; document in agent memory. | Resolved |
| 3 | **WhisperKit's progress callback is elapsed-pipeline-seconds, not a fraction.** Mapped through `ProgressBox` using the input WAV's duration as the denominator + monotonic clamp. Edge cases when the engine reports more elapsed time than the audio duration (e.g., on cold start) → clamped to 0.999 until the service emits `1.0`. | None. | Resolved |
| 4 | **Filename suffix collision in `AudioCaptureLocations`** (carry-over from EPIC-02b): a 4-char UUID suffix has only 16 bits of entropy; 200 same-millisecond calls hit a birthday-paradox collision. Bumped to 8 chars (32 bits) so the EPIC-02b uniqueness regression test passes deterministically. | None. | Resolved |
| 5 | **`package` access modifier requires `-package-name` flag** that XcodeGen-generated projects don't set. Used `internal` instead and `@testable import` for the engine seam. | Future contributors: prefer `internal` + `@testable import` over `package` on this codebase. | Resolved |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-08 | Claude Agent | Implemented `TranscriptionService` (API-101), `WhisperKitEngine` (production) + `FakeTranscriptionEngine` (tests), `TranscriptionModelStore`, `Transcript` data types. 12/12 transcription tests green; 35/35 overall. |
