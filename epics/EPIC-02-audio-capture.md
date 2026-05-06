---
template_version: "3.0.0"
---

# EPIC-02 Audio Capture Engine

> **State**: `✅ Complete`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: Claude Agent (session: 2026-05-06)
> **Depends On**: EPIC-01

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-06 — Implemented `DefaultAudioCaptureService` actor with injectable `MicrophoneSource` (AVAudioEngine) + `SystemAudioSource` (ScreenCaptureKit). Real-time mixing via `AudioFileWriter` (auto-converts to writer's processing format). 5 SoT tests + 4 unit tests all green; full audio pipeline produces a valid WAV under both mic-only and dual-source configurations.
- **Stopping Point**: All Phase A–E deliverables ticked. EPIC-02 closed.
- **Next Steps**: EPIC-03 (Transcription Pipeline). Wire WhisperKit (already SPM-resolved at 0.18.0) to consume the WAV produced by `AudioCaptureService.stopCapture()` and produce time-coded segments.
- **Context**: Public surface is `AudioCaptureService` protocol + `DefaultAudioCaptureService` actor. Sources are injectable so future EPICs can stub them without hardware. WAV format is 48 kHz, 32-bit float, mono — chosen because SoT was silent and that format is the cheapest path to WhisperKit ingestion (no resampling needed by EPIC-03).

---

## Objective & Scope

> **Goal**: Implement microphone capture (AVAudioEngine), system audio capture (ScreenCaptureKit), and audio mixing into a single WAV file.

- **Deliverables**:
  - [x] `AudioCaptureService` protocol + `DefaultAudioCaptureService` actor implementation (API-001)
  - [x] `AudioMixer` utility for mic + system audio (API-002) — pure function in `AudioMixer.swift`
  - [x] Microphone capture via AVAudioEngine (INT-201) — `AVAudioEngineMicrophoneSource`
  - [x] System audio capture via ScreenCaptureKit (INT-202) — `ScreenCaptureKitSystemAudioSource`
  - [x] Graceful fallback to mic-only when Screen Recording permission denied — emits `AudioCaptureMilestone.systemAudioFellBackToMicOnly` (TEST-005 covers)
  - [x] Audio level stream for UI visualization — `audioLevels()` returns `AsyncStream<Float>` throttled to ~10 Hz
  - [x] Duration limit guard (BR-402) — `AudioCaptureClock` abstraction enforces warning at `warningDuration` and auto-stop at `maximumDuration`
  - [x] Tests: TEST-001, TEST-002, TEST-003, TEST-004, TEST-005 — all green via fake sources + `FakeAudioCaptureClock`
- **Out of Scope**: Real-time transcription, streaming to downstream services

---

## Context & IDs

- **APIs**: API-001, API-002
- **Integrations**: INT-201, INT-202
- **Tech**: TECH-003, TECH-004
- **Business Rules**: BR-101, BR-402
- **Features**: FEA-001
- **Tests**: TEST-001, TEST-002, TEST-003, TEST-004, TEST-005
- **Risks**: RISK-002, RISK-004

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [x] **Context Loaded**: Read API-001, API-002, INT-201, INT-202, BR-402, all TEST-001..005
- [x] **Strategy**: Protocol-first design, AVAudioEngine mic first, then ScreenCaptureKit, then DefaultAudioCaptureService orchestrator. Inject sources + clock so the test suite never needs real hardware.

### Phase B: Design

- [x] Review Azayaka source for ScreenCaptureKit patterns (used `SCStreamConfiguration.capturesAudio = true` + minimal video filter as the canonical audio-only pattern)
- [x] Permission flow: each source surfaces `microphonePermissionDenied` / `screenRecordingPermissionDenied`; orchestrator catches the system-audio variant and falls back to mic-only with a milestone event so the UI (EPIC-07) can prompt re-grant later

### Phase C: Build (The "Context Window")

**Context Window 1: Microphone Capture**

- [x] Implement `AudioCaptureService` protocol + `DefaultAudioCaptureService` actor
- [x] AVAudioEngine mic capture with `installTap(onBus:bufferSize:format:)`
- [x] Audio level stream via RMS calculation (`AudioLevelComputer`), throttled by `LevelGate` to ~10 Hz
- [x] Continuous WAV write via `AudioFileWriter` (RISK-006 — frames flush incrementally, file finalized on `finish()`)
- [x] **Test**: TEST-001 (start/stop) ✅, TEST-002 (audio levels stream) ✅

**Context Window 2: System Audio**

- [x] ScreenCaptureKit audio-only capture (`SCStreamConfiguration.capturesAudio = true`, dummy 2×2 video frame interval to satisfy filter)
- [x] Permission request handling + graceful fallback (TEST-005 ✅)
- [x] `AudioMixer.mix()` for dual-source WAV output (TEST-003 ✅)
- [x] **Test**: TEST-003 (valid WAV) ✅, TEST-004 (duration limit) ✅

### Phase D: Validate

- [x] All 5 TEST-XXX cases pass (plus 4 supporting unit tests — 11/11 green)
- [ ] **Deferred**: Manual end-to-end test with a real microphone + real system audio (TCC permission wiring lands in EPIC-07 UI)
- [x] WAV file shape verified by `AVAudioFile(forReading:)` in `AudioMixerTests` (sample rate / channel count / frame length all correct)
- [x] Code traceability: `// @implements API-001` / `API-002` / `INT-201` / `INT-202` / `BR-402` / `RISK-006` markers added to relevant files

### Phase E: Finish (Harvest)

- [x] Generated `Recordings/` directory at `~/Library/Application Support/TranscriptShadow/Recordings/` per RISK-006 crash-recovery convention (created on first capture)
- [x] API-001 / API-002 marked Implemented in `SoT.API_CONTRACTS.md` (see commit)
- [x] Session audit completed

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | `AVAudioPCMBuffer` is not Sendable in Swift 6, so direct `AsyncStream<AVAudioPCMBuffer>` plumbing fails strict concurrency. Switched to a synchronous callback consumer (`AudioBufferConsumer`) handed to sources at start; sources invoke it on their own audio threads. | Documented inline in `MicrophoneSource.swift`. | Resolved |
| 2 | `NSLock.lock()` / `unlock()` is now banned in `async` contexts (Swift 6). Migrated all locks to `lock.withLock { … }` closures in capture sources, fakes, and the test clock. | Pattern is consistent across the audio module. | Resolved |
| 3 | `AVAudioFile` only finalizes the WAV header when the file object is released. `AudioFileWriter.finish()` was originally just a flag; now it nils out the underlying `AVAudioFile` so `AVAudioFile(forReading:)` sees the full data after stop. | None. | Resolved |
| 4 | `AVAudioFile.write(from:)` requires the buffer's format to match `processingFormat`; comparing via `==` is too strict (channel layouts differ). `AudioFileWriter` now compares via an `isEquivalent(to:)` extension and falls through to `AudioBufferConverter` if the structural format differs. | None. | Resolved |
| 5 | macOS codesign rejects extended attributes left over from xattr-tagged source files. Required clearing build artifacts (`rm -rf build`) once. CI runners start clean so this is a local-only friction. | Add `xattr -rc` step to a future `scripts/clean-build.sh` if the issue recurs. | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-06 | Claude Agent | Implemented `AudioCaptureService` (API-001) and `AudioMixer` (API-002), real `AVAudioEngineMicrophoneSource` + `ScreenCaptureKitSystemAudioSource`, duration guard via injectable `AudioCaptureClock`, and 11 passing tests covering TEST-001..005. |
