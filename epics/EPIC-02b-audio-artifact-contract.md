---
template_version: "3.0.0"
---

# EPIC-02b Audio Artifact Contract Hardening

> **State**: `✅ Complete`
> **Lifecycle**: v0.7 Build Execution
> **Epic Lead**: Claude Agent (session: 2026-05-07)
> **Depends On**: EPIC-02
> **Blocks**: EPIC-03 (Transcription Pipeline must consume a stable artifact contract)

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-07 — All six Codex findings addressed. Introduced `MilestoneBus` + `LevelBus` thread-safe broadcast classes (synchronous registration, lock-protected observer lists) so `milestones()` is now a true broadcast surface and subscribers established right before `startCapture` cannot miss the immediate `.systemAudioFellBackToMicOnly` event. Added `AudioCaptureMilestone.recordingFinalized(url:reason:)`; both user-initiated and BR-402 auto-stop emit it through the same milestone stream. `AudioFileWriter.write` consolidated into a single critical section; init refuses to overwrite an existing file. `AudioCaptureLocations.newRecordingURL` now uses millisecond ISO-8601 timestamps + a UUID suffix; the docstring matches the implementation (only directory creation; cleanup is EPIC-08). `channelCount` removed from public configuration. 23/23 tests green (14 prior + 9 new).
- **Stopping Point**: All Phase A–E deliverables ticked. EPIC-02b closed.
- **Next Steps**: Begin **EPIC-03 — Transcription Pipeline**. WhisperKit is already SPM-resolved (0.18.0); per Codex's recommendation, treat `AudioCaptureService.stopCapture()` URL as the only handoff and design the `TranscriptionService` to accept any readable WAV (normalize internally), with fixture-based unit tests plus one integration test against an actual captured file.
- **Context**: This was a surgical hardening pass — no new capability, only contract fixes. The `AudioCaptureService` public surface is now the version EPIC-03 + EPIC-07 will build against without churn.

---

## Objective & Scope

> **Goal**: Stabilize the artifact contract `AudioCaptureService` exposes to downstream consumers (EPIC-03+ transcription, EPIC-07 UI) before any of those consumers exist.

- **Deliverables**:
  - [x] **Auto-stop returns the recording URL.** Added `AudioCaptureMilestone.recordingFinalized(url:reason:)`; both user-initiated stop and BR-402 auto-stop emit it through the same broadcast. `AudioCaptureFinalizationReason` distinguishes triggers (`.userRequested`, `.durationLimitReached`).
  - [x] **`AudioFileWriter.write()` is atomic.** Validate, convert, write, and frame-counter increment happen inside a single `lock.withLock { ... }` block. Concurrency test (`test_concurrentWriteAndFinish_doesNotDoubleCount`) drives 200 writers racing `finish()` and asserts `totalFrameCount == AVAudioFile.length` on readback.
  - [x] **Recording filenames are collision-proof.** `AudioCaptureLocations.newRecordingURL` now produces `recording-2026-05-07T07-23-45.123Z-8C5F.wav` (ISO with fractional seconds + 4-char UUID suffix). `AudioFileWriter.init` throws `audioFileWriteFailed` if the URL already exists rather than silently overwriting.
  - [x] **`milestones()` is a per-subscriber broadcast.** New `MilestoneBus` final class with synchronous lock-protected registration; same pattern for `LevelBus`. Eliminates the actor-entry race that could cause subscribers established right before `startCapture` to miss early events.
  - [x] **`channelCount` removed from `AudioCaptureConfiguration`.** Pinned to 1 internally via `AudioCaptureConfiguration.outputChannelCount`. ScreenCaptureKit now reads from the constant; mixer always outputs mono.
  - [x] **`AudioCaptureLocations` docs match implementation.** Docstring rewritten to describe only what's there (directory creation + unique URL generation) and to point at EPIC-08 for the cleanup lifecycle.
- **Out of Scope**: Real `TempAudioCleanup` implementation (EPIC-08). UI consumption of milestones (EPIC-07). Multi-channel output (deferred indefinitely; mono is correct for transcription).

---

## Context & IDs

- **APIs touched**: API-001 (AudioCaptureService), API-002 (AudioMixer)
- **Tests**: New regression tests for each fix; existing TEST-004 updated for new milestone payload
- **Risks**: RISK-006 (crash safety) — clarified contract, full impl deferred to EPIC-08
- **Source**: Codex synthesis review of 2026-05-07 (logged at `~/.claude/logs/codex-calls.jsonl`)

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [x] Codex synthesis review run; 6 findings extracted
- [x] Each finding mapped to a deliverable above
- [x] Decision recorded for each over-eng finding (drop `channelCount`, tighten `AudioCaptureLocations` docstring)

### Phase B: Design

- [x] Milestone enum extended with `recordingFinalized(url:reason:)` + `FinalizationReason` (`userRequested`, `durationLimitReached`)
- [x] Broadcast pattern for `milestones()` mirrors the existing `audioLevels()` observer-list mechanic; observers identified by UUID for clean removal on continuation termination

### Phase C: Build

- [x] Updated milestone enum (`recordingFinalized` + `AudioCaptureFinalizationReason`); both user/auto stop paths emit through `milestoneBus.broadcast(...)`
- [x] Refactored `AudioFileWriter.write` to a single `withLock` critical section (validate + convert + write + counter)
- [x] Updated `AudioCaptureLocations.newRecordingURL` to ISO with fractional seconds + 4-char UUID suffix; rewrote docstring to match impl
- [x] Updated `AudioFileWriter.init` to throw `audioFileWriteFailed` on existing-file URL
- [x] Dropped `channelCount` from `AudioCaptureConfiguration`; introduced `outputChannelCount` static; updated `SystemAudioSource` reference
- [x] Refactored `milestones()` to use new `MilestoneBus` (sync registration, broadcast); also moved `audioLevels()` onto a parallel `LevelBus` (broadcast + finishAll on stop)

### Phase D: Validate

- [x] All EPIC-02 tests still pass (14/14 prior tests green)
- [x] New regression tests pass (9 added — total 23):
  - `test_userInitiatedStop_emitsRecordingFinalized` — milestone URL == stopCapture return value
  - `test_durationAutoStop_emitsRecordingFinalized_withSavedURL` — auto-stop yields `.recordingFinalized(url, .durationLimitReached)`
  - `test_milestones_areBroadcastToMultipleSubscribers` — two subscribers both observe a fallback event
  - `test_init_throws_whenFileAlreadyExists` — no silent overwrite
  - `test_finishedWriter_rejectsSubsequentWrites` — finish() invariant
  - `test_concurrentWriteAndFinish_doesNotDoubleCount` — `totalFrameCount` matches on-disk frames under race
  - `test_newRecordingURL_isUniqueAcrossRapidCalls` — 200 calls at the same Date all unique
  - `test_newRecordingURL_includesFractionalSeconds` — millisecond precision
- [x] `xcodebuild test` exits 0

### Phase E: Finish (Harvest)

- [x] SoT.API_CONTRACTS.md API-001 interface updated to show the new milestone enum + `AudioCaptureFinalizationReason`
- [x] EPIC-02 observation #7 added pointing at this EPIC for the fixes
- [x] README backlog table inserts EPIC-02b row sequenced before EPIC-03

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | Two-step `withLock` was the easy version of `AudioFileWriter.write` — release after validate, re-acquire for the actual write — but exactly that gap is what `finish()` slipped into. Worth recording: any "validate then mutate shared state" pair across an actor boundary needs a single critical section unless we can prove the validation result is stable. | Internalize as a code-review heuristic for the rest of the audio module + transcription consumers. | Resolved |
| 2 | The `Task { await self.registerObserver(continuation) }` shape inside `AsyncStream { ... }` looks correct for actor-isolated observer lists, but the registration is asynchronous and can lose to other actor-bound calls. Synchronous-via-bus is the only contract-safe pattern when subscribers register right before triggering work. | Same pattern is now used for both `LevelBus` and `MilestoneBus`. Document for future stream surfaces. | Resolved |
| 3 | A duplicate `TranscriptShadow 2.xcodeproj` appeared during this session (Finder/Spotlight artifact); xcodebuild errored "directory contains 2 projects." Removed manually. | Add a build script step to remove `*.xcodeproj` duplicates before `xcodebuild`, or move the .xcodeproj into a sibling directory not scanned by xcodebuild's auto-discovery. | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-05-07 | Claude Agent | Created EPIC after Codex synthesis review surfaced 6 artifact-contract issues |
| 2026-05-07 | Claude Agent | All 6 fixes shipped: recordingFinalized milestone, atomic writer, unique filenames, broadcast buses, channelCount removal, docstring tightening. 23/23 tests green. |
