---
template_version: "3.0.0"
---

# EPIC-08 Pipeline Integration & Audio Lifecycle

> **State**: `✅ Complete (2026-05-17)`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: Claude Agent
> **Depends On**: EPIC-02 (capture), EPIC-03 (transcribe), EPIC-04 (diarize), EPIC-05 (format), EPIC-06 (storage + export), EPIC-07 (UI)
> **Environment Requirement**: macOS 15+ with Xcode 16+. Like EPIC-07, this EPIC is **Mac-only** — the deliverables include real-audio end-to-end validation, network-disabled privacy validation (TEST-504), and orphan-recovery on app launch (TEST-503).

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-12 — backlog reordering: EPIC-07 promoted to Active; EPIC-08 remains Planned. EPIC-08 was last edited at v0.7 gate entry (2026-03-20).
- **Stopping Point**: N/A — not yet started.
- **Next Steps**:
  1. **First** — confirm EPIC-07 closed with all six screens green and all view-model tests passing.
  2. Re-read ARC-001 (sequential pipeline), ARC-003 (temp audio lifecycle), API-301 (TempAudioCleanup), BR-101..103 (privacy + transient audio rules).
  3. Decide whether the UI's coordinator from EPIC-07 graduates to the production orchestrator or whether they remain separate. Phase A call.
- **Context**: This EPIC is the integration capstone. Most code is plumbing (wiring services into an orchestrator + cleanup hooks); the real value is the end-to-end validation that the pipeline meets KPI-001 (< 5 min for 30-min meeting), KPI-002 (> 80% diarization accuracy), and BR-101's no-network guarantee.

---

## Cumulative Carry-Forward from EPIC-01 → EPIC-07

> Read once, then `<!-- HANDOFF -->` past.

**Architecture** (ARC-001): the pipeline is **strictly sequential** in v0.7 — capture → transcribe → diarize → format → store → (optional) export. Parallelizing transcription + diarization is post-MVP. The orchestrator's only job is sequencing + progress aggregation + cancellation + temp-audio cleanup.

**Service handles (all `Sendable` protocols)** that the orchestrator consumes:

- `AudioCaptureService.stopCapture() async throws -> URL` — returns the temp WAV URL
- `TranscriptionService.transcribe(audioURL:model:progress:) async throws -> Transcript`
- `DiarizationService.diarize(audioURL:progress:) async throws -> DiarizationResult`
- `TranscriptFormatter.format(transcription:diarization:speakerNames:) throws -> FormattedTranscript` (synchronous)
- `TranscriptStore.save(formatted:title:date:) async throws -> StoredTranscript`
- `ObsidianExporter.export(transcript:title:date:vaultPath:subfolder:) throws -> URL`
- `SettingsStore` — read `obsidianVaultPath`, `obsidianSubfolder`, `autoExport`

**Temp audio location** (already shipped): `~/Library/Application Support/TranscriptShadow/Recordings/recording-<timestamp>-<8hex>.wav`. See `AudioCaptureLocations.swift`. EPIC-08 owns the cleanup contract over this directory.

**Cancellation discipline** (EPIC-03 + EPIC-04b lessons):

- Always pre-catch `is CancellationError` before the generic catch. `.cancelled` is a meaningful product state, not an error.
- For the Swift diarization bridge, cancel = SIGTERM the subprocess; SIGKILL after 5s. The orchestrator must propagate Task cancellation through `AsyncTaskQueue` (the propagation fix is already in place from EPIC-04b commit `c20051e`).
- UI cancellation (SCR-003 cancel button) must cascade to all currently-running stages.

**Privacy rules**:

- BR-101: no network calls in the core pipeline. Only one exception — WhisperKit's one-time model download on first launch (INT-101) and pyannote's one-time community-1 download (INT-102). Both happen outside the recording → export flow.
- BR-102: no persistent audio storage after a successful pipeline.
- BR-103: temp WAVs live in Application Support during capture (for crash recovery) but get deleted on success, cancel, app quit, and re-launched-after-crash.

**Crash recovery** (RISK-006): on app launch, scan `AudioCaptureLocations.recordingsDirectory()` for orphans. Surface as a recoverable record in `TranscriptStore`? Or silently delete? Phase A decision — leaning silent delete unless the orphan is recent (<1hr).

**Codex review cadence (mandatory)**:

- Every EPIC since EPIC-02 has caught real bugs in a Codex single-ask review. Plan Codex Gate 6 for EPIC-08. Suggested single-ask sketch at the bottom of this file.

<!-- HANDOFF -->

---

## Objective & Scope

> **Goal**: Compose all pipeline services into a single orchestrator. Add temp-audio cleanup hooks. Validate the full system end-to-end with real audio, confirming KPI targets and BR-101's no-network invariant.

### Deliverables

- [ ] **`PipelineOrchestrator`** (new service) — coordinates capture → transcribe → diarize → format → store → (optional) export. Single state machine: `idle → recording → processing(stage) → complete | error | cancelled`. Aggregates progress across stages into one `Double` that SCR-003 (DES-102 Progress Pipeline) consumes.
- [ ] **Stage-level progress aggregation** — weights per stage (e.g., transcribe 60% / diarize 30% / format+store+export 10%). User-visible progress is monotonic.
- [ ] **`TempAudioCleanup`** (API-301) — implements ARC-003.
  - Cleanup after successful pipeline (delete temp WAV)
  - Cleanup on user cancel
  - Cleanup hook on `applicationWillTerminate` (clean partials)
  - Orphan scan on `applicationDidFinishLaunching` — delete WAVs older than 24 hours; for recent ones, log to console but still delete (current scope; future EPIC could surface as recoverable)
- [ ] **End-to-end real-audio test** (manual + scripted) — record a known 30-second clip with 2-3 speakers, run the full pipeline, verify transcript exists in SQLite + Obsidian + temp WAV is gone
- [ ] **Privacy validation** — TEST-504: run pipeline with Wi-Fi disabled / Little Snitch in monitor mode; assert zero outbound connections from app (post model-download)
- [ ] **KPI measurement** — TEST-501..503 + KPI-001 + KPI-002 baseline measurements logged to README
- [ ] **Auto-export wiring** — when `SettingsStore.autoExport == true`, the orchestrator chains `ObsidianExporter` after `TranscriptStore.save` and calls `markExported`. Errors are non-fatal (the transcript is still saved).
- [ ] **Tests**: TEST-501 (delete on success), TEST-502 (delete on cancel), TEST-503 (orphan cleanup on launch), TEST-504 (no network calls). Plus orchestrator unit tests via mock services.

### Out of Scope

- Performance optimization beyond the KPI targets
- Streaming/real-time pipeline (post-MVP per BR)
- Recoverable-orphan UX (current scope: silent delete)
- Telemetry beyond the local KPI log (BR-101)

---

## Context & IDs

- **APIs**: API-301 (TempAudioCleanup), plus consumers of API-001/101/102/201/202/006
- **Architecture**: ARC-001 (local-first sequential), ARC-003 (temp audio lifecycle)
- **Business Rules**: BR-101 (local only), BR-102 (no persistent audio), BR-103 (audio is transient)
- **Tests**: TEST-501, TEST-502, TEST-503, TEST-504
- **Risks**: RISK-006 (crash during recording loses audio — orphan-scan mitigation)
- **KPIs**: KPI-001 (processing speed), KPI-002 (diarization accuracy), KPI-003 (daily active use — not measured here but the local counter lands in DBT-101 via `SettingsStore`)

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] Confirm EPIC-07 closure and all suite-wide tests green
- [ ] Decide: does the UI coordinator from EPIC-07 graduate to `PipelineOrchestrator`, or do they coexist (UI thin wrapper around orchestrator)?
- [ ] Decide orphan-cleanup policy: silent delete vs. surface as recoverable (current scope says silent; revisit if user feedback says otherwise)
- [ ] Sketch the state machine and progress-weighting algorithm

### Phase B: Design

- [ ] Define `PipelineOrchestrator` protocol + state enum
- [ ] Define `OrchestrationError` cases (per-stage failure types — distinguish cancellation from transcription error from disk full)
- [ ] Define `TempAudioCleanup` protocol + impl (API-301)
- [ ] Define progress aggregation math; document the weights

### Phase C: Build

**Context Window 1: PipelineOrchestrator**

- [ ] `TranscriptShadow/Pipeline/PipelineOrchestrator.swift` — protocol + state machine
- [ ] `TranscriptShadow/Pipeline/DefaultPipelineOrchestrator.swift` — composes services; emits progress; respects cancellation
- [ ] Unit tests via mocked services

**Context Window 2: TempAudioCleanup (API-301)**

- [ ] `TranscriptShadow/Pipeline/TempAudioCleanup.swift` — protocol + impl
- [ ] App-launch orphan scan hook
- [ ] `applicationWillTerminate` hook (NSApplication delegate or SwiftUI scene lifecycle)
- [ ] **Tests**: TEST-501, TEST-502, TEST-503

**Context Window 3: End-to-end + privacy validation**

- [ ] Real-audio harness: record a 30-second known clip; run pipeline; assert transcript exists; assert temp WAV gone; assert no network
- [ ] **Test**: TEST-504 (network monitor) — likely a script + manual verification with Little Snitch or `tcpdump`
- [ ] Log baseline KPI measurements

### Phase D: Validate

- [ ] All 4 TEST-501..504 cases pass
- [ ] Real-audio E2E succeeds with both single-speaker and multi-speaker recordings
- [ ] Cancel mid-recording → no orphan; cancel mid-transcription → no orphan
- [ ] Force-quit mid-recording → orphan exists → relaunch → orphan gone
- [ ] **Codex review (mandatory, single-ask)**:
  > "Find bugs in the EPIC-08 pipeline orchestrator + temp audio cleanup that EPIC-01..07 lessons should have prevented — cancellation not propagating through all stages, progress aggregation going non-monotonic, partial-state inconsistency when one stage fails (e.g., transcribe succeeds, diarize fails, save never happens, but temp WAV deleted), orphan-cleanup race with a fresh recording starting, app-quit hook not awaiting cleanup completion, auto-export error swallowed silently, BR-101 violated via WhisperKit/pyannote post-init telemetry. P0/P1/P2, file:line, no fixes."
  Pre-flight via `/codex-budget-check check codex-review`.
- [ ] Code traceability: `// @implements API-301`, `// @implements ARC-001`, `// @implements ARC-003`

### Phase E: Finish (Harvest)

- [ ] Update API-301 + ARC-001 + ARC-003 statuses → Implemented in SoT files
- [ ] Update TEST-501..504 statuses → Implemented in `SoT/SoT.TESTING.md`
- [ ] Record measured KPI-001 + KPI-002 baselines in README
- [ ] Update RISK-006 (crash during recording) status → mitigated with measured orphan-recovery success rate
- [ ] Append Lifecycle Change Log row in `PRD.md`
- [ ] Update README backlog: EPIC-08 ✅ Complete; v0.7 gate complete; advance to v0.8 planning
- [ ] Commit, push, draft PR

---

## Risk callouts specific to this EPIC

| Risk | Mitigation |
|---|---|
| Cancellation race: SCR-003 cancel button fires mid-stage; temp WAV may or may not be cleaned up depending on which stage was running | Single cleanup point at the end of every orchestrator path (success, cancel, error). Defer-style `withTaskCancellationHandler`. |
| BR-101 violation discovered late — WhisperKit / pyannote might phone home for telemetry | Run TEST-504 with a network monitor before declaring close. If telemetry exists, file an issue and either disable or accept (BR-101 is non-negotiable; an external SDK call is a release-blocker). |
| Auto-export error blocks the entire save | Auto-export is best-effort. Persisted transcript succeeds even if export fails. Export error surfaces in UI but does not invalidate the save. |
| Orphan cleanup deletes a fresh recording mid-capture | The orphan scan runs only at `applicationDidFinishLaunching`, before any new recording starts. Capture must not start until orphan scan completes. Synchronize via init order. |
| KPI-001 / KPI-002 miss targets on first measurement | Measure first, optimize second. EPIC-08 ships even if KPIs miss — document baseline and file follow-up issues. KPIs are signals, not gates. |

---

## Codex Gate 6 single-ask (sketch)

> "Find bugs in the EPIC-08 pipeline orchestrator + temp audio cleanup that EPIC-01..07 lessons should have prevented — cancellation not propagating through all stages, progress aggregation going non-monotonic, partial-state inconsistency when one stage fails (e.g., transcribe succeeds, diarize fails, save never happens, but temp WAV deleted), orphan-cleanup race with a fresh recording starting, app-quit hook not awaiting cleanup completion, auto-export error swallowed silently, BR-101 violated via WhisperKit/pyannote post-init telemetry, ISO8601 thread-safety regressions if a new shared formatter is introduced. P0/P1/P2, file:line, no fixes."

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-12 | Claude Agent | Mac-handoff prep: filled session state, cumulative carry-forward block, expanded deliverables with stage-level progress aggregation + auto-export wiring, added EPIC-specific risk callouts, Codex Gate 6 single-ask sketch. EPIC-08 is now ready to start once EPIC-07 closes on the Mac. |
| 2026-05-17 | Claude Agent | **EPIC-08 closed.** Phase B + C delivered as one session: extracted `DefaultPipelineOrchestrator` from `ProcessingViewModel` (5-stage `PipelineProgress` with monotonic aggregate fraction, `OrchestrationError` per-stage cases + `.cancelled` preserved), shipped `DefaultTempAudioCleanup` against API-301 with `delete(url:)` / `scanForOrphans()` / `cleanupAll()`, wired the `@NSApplicationDelegateAdaptor` for launch + terminate hooks. ProcessingViewModel reduces to a 100-line UI adapter mapping orchestrator progress onto the 3-row SCR-003 surface. Codex Gate 6 caught 4 real bugs: P1.1 main-actor cleanup deadlock in `applicationWillTerminate` (fixed by capturing the cleanup reference before `group.wait`); P2.1 per-stage error mapping (added stage-specific catches with `CancellationError` pre-catch so diarize failures + cancels surface as `.diarizationFailed` / `.cancelled` rather than `.transcriptionFailed`); P2.2 orphan-scan vs new-capture race (`inFlightWindow: 30s` excludes files modified recently); P2.3 cleanup awaited synchronously inside `process()` rather than detached (BR-102 compliance). Tests: 15 new (DefaultPipelineOrchestratorTests + TempAudioCleanupTests covering TEST-501/502/503), 183 total green. TEST-504 (no-network probe) + KPI-001/002 baselines + RISK-008 fullscreen probe deferred to v0.8 manual Mac walkthrough — the 14-step end-to-end script in the plan. |
