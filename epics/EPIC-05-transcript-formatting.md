---
template_version: "3.0.0"
---

# EPIC-05 Transcript Formatting & Alignment

> **State**: `Active` (next up after EPIC-04 close, 2026-05-09)
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-03 (`Transcript` + `TranscriptSegment` + `WordTimestamp`), EPIC-04b (`DiarizationResult` + `SpeakerSegment`)

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-09 — EPIC-04 fully closed (PR #5 merged). EPIC-05 is now Active. No code yet.
- **Stopping Point**: N/A — not yet started.
- **Next Steps**: Phase A planning. Read API-201, BR-301, RISK-005 + the EPIC-04b `DiarizationResult` Codable shape. Decide on the alignment algorithm (greedy-overlap vs IoU-weighted) and the edge-case policy for words that fall in silence / overlap regions before writing code.
- **Context**: Lower technical risk than EPIC-04 — both inputs are pure-Swift Codable structs already in memory; no subprocess, no sandbox, no model download. **The single hardest thing is RISK-005** (alignment accuracy at speaker boundaries). The exclusive-view `segments` (no overlaps) is preferred for alignment; `overlappingSegments` is the fallback view for true simultaneous speech.

---

## Cumulative Carry-Forward (read once, then `<!-- HANDOFF -->` past)

> Patterns that have already cost us cycles in EPIC-01..04. The full block
> lives in [`epics/EPIC-04-speaker-diarization.md`](EPIC-04-speaker-diarization.md)
> (the index for the now-closed 04a + 04b chain). EPIC-05-relevant
> highlights:

**Inputs you'll consume**:

- `Transcript` (from `API-101`, EPIC-03) — `segments: [TranscriptSegment]`. Each segment has `text`, `start`, `end`, `words: [WordTimestamp]`. WhisperKit always populates `words` because the orchestrator requests `wordTimestamps: true`. Don't assume non-empty though — guard with a fallback (segment-level alignment) when `words` is empty.
- `DiarizationResult` (from `API-102`, EPIC-04b) — `segments` (exclusive view, no overlaps) and `overlappingSegments` (allowing simultaneous speakers). Use `segments` for the primary alignment; consult `overlappingSegments` only when you need to flag "two speakers talking at once" in the formatter output.
- Both types are `Sendable` + `Equatable` + `Codable`. They're already in memory by the time the formatter runs — no I/O.

**Concurrency** (Swift 6 strict + EPIC-03/04 lessons):

- If `TranscriptFormatter` could be called concurrently, wrap it in `AsyncTaskQueue` (the queue from `Transcription/AsyncTaskQueue.swift`). The EPIC-04b cancellation-propagation fix is now in that queue — cancelling the caller propagates to the queued work. Use the queue if formatting is non-trivial (e.g., long transcripts where you don't want two formatters to thrash).
- Likely you don't need a queue here — formatting is CPU-only, deterministic, and fast. But consider it for the orchestrator (EPIC-08) when audio + transcribe + diarize + format pipeline serially.
- `final class` + `NSLock.withLock { … }` is the established pattern when an `actor` would force a non-`Sendable` payload across an isolation boundary. `WhisperKitEngine` and `PyannoteSidecarDiarizationService` both use this pattern. EPIC-05's `TranscriptFormatter` is probably stateless enough to be a plain `struct` — but if it grows state (e.g., a configurable speaker-name dictionary), default to the class+lock pattern.

**Test discipline** (proven in EPIC-04):

- Inject every external dependency. The formatter's input is two Codable structs; it's the easiest EPIC to test exhaustively.
- Use **golden fixtures** for cross-stage contracts. EPIC-04a/04b shipped `sidecar/test_fixtures/golden-3spk.json` (and `-1spk.json`). EPIC-05 likely wants a golden `Transcript` fixture (or a builder helper) so alignment tests run without WhisperKit in scope. A markdown-output golden file is the tightest assertion for the formatter — diff comparison instead of regex matching.
- Per-pair markers > strict ordering. If you test alignment on multiple speakers concurrently, assert "all words for speaker X are inside speaker X's segments" rather than "the words appear in this exact order across speakers".

**SDK / module name collisions** (EPIC-03):

- WhisperKit's module shadows the class name; we use `Transcript` (not `TranscriptionResult`). When you build `FormattedTranscript`, watch for any collision with WhisperKit or pyannote-bridged types. If a clash arises, rename **our** type — precedent is strong.

**Float-comparison + rounding**:

- The diarization JSON envelope rounds floats to 3 decimal places at serialization (millisecond resolution). Word timestamps from WhisperKit are higher precision but inherit the same rounding when re-serialized. For alignment math, work in `TimeInterval` (Double seconds); compare with a tolerance epsilon (BR/UJ specifies ±1.0s as the alignment tolerance, but for boundary equality use ±0.001 to absorb rounding drift).

**Codex review cadence (mandatory before EPIC close)** — now 5/5 EPICs since EPIC-02 have shipped with a Codex pass that surfaced real bugs:

| EPIC | Codex Gate findings (P0/P1/P2) |
|---|---|
| EPIC-02 | 4 (initial review) |
| EPIC-02b | 6 (synthesis review) |
| EPIC-03 | 3 (downloadBase, AsyncTaskQueue, CancellationError) |
| EPIC-04a | 3 (P0 torch pin, P1 ProgressHook stdout, P1 vacuous test) |
| EPIC-04b | 10 (2 P0, 6 P1, 2 P2 — including the pre-existing AsyncTaskQueue race that had been latent since EPIC-03) |

Plan one for EPIC-05 too. **Single-ask discipline**: pose Codex one specific question with a length cap (e.g., "Find bugs in `TranscriptFormatter` that EPIC-03/04 lessons should have prevented — alignment off-by-one at speaker boundaries, word-without-segment fallback, Codable shape stability for EPIC-06 storage. P0/P1/P2, file:line, no fixes."). Pre-flight via `/codex-budget-check check codex-review`.

**EPIC-04b-specific carry-forwards that DON'T apply here** (skip past):

- Foundation `Process` vs swift-subprocess — EPIC-05 doesn't spawn anything.
- App-sandbox + hardened-runtime + entitlement matrix — EPIC-05 is pure Swift, no native dependencies.
- Bottom-up codesign — same.
- Pipe / FileHandle.bytes streaming — same.
- Pre-existing `AsyncTaskQueue` race — fixed in EPIC-04b commit `c20051e`. EPIC-05 inherits the fix.

<!-- HANDOFF -->

---

## Objective & Scope

> **Goal**: Merge transcription word timestamps with diarization speaker segments, then format as speaker-labeled markdown.

- **Deliverables**:
  - [ ] `TranscriptFormatter` protocol + implementation (API-201)
  - [ ] Word-to-speaker alignment algorithm (±1.0s tolerance)
  - [ ] Markdown output with speaker labels and `[HH:MM:SS]` timestamps
  - [ ] Speaker rename support (SPEAKER_00 → custom name)
  - [ ] `FormattedTranscript` data type with metadata
  - [ ] Tests: TEST-301, TEST-302, TEST-303
- **Out of Scope**: Obsidian export (EPIC-06), UI display (EPIC-07)

---

## Context & IDs

- **APIs**: API-201
- **Business Rules**: BR-301
- **Features**: FEA-003, FEA-004
- **Tests**: TEST-301, TEST-302, TEST-303
- **Risks**: RISK-005

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: Read API-201, BR-301, RISK-005
- [ ] **Strategy**: Alignment algorithm first (hardest), then formatting (straightforward)

### Phase B: Design

- [ ] Define alignment algorithm: for each transcription word, find overlapping diarization segment
- [ ] Handle edge cases: words in silence, overlapping speakers, gaps

### Phase C: Build (The "Context Window")

**Context Window 1: Alignment**

- [ ] Implement word-to-speaker mapping with timestamp overlap
- [ ] Configurable tolerance (default ±1.0s)
- [ ] Handle unmatched words (assign to nearest speaker or "Unknown")
- [ ] **Test**: TEST-303 (alignment accuracy)

**Context Window 2: Markdown Formatter**

- [ ] Format aligned segments as markdown with speaker labels
- [ ] Timestamp format: `[HH:MM:SS]`
- [ ] Speaker name substitution from `speakerNames` map
- [ ] Generate `FormattedTranscript` with metadata (duration, speaker count, etc.)
- [ ] **Test**: TEST-301 (markdown output), TEST-302 (rename propagation)

### Phase D: Validate

- [ ] All 3 TEST-XXX cases pass
- [ ] Manual test: format a real transcription+diarization pair (use the `golden-3spk.json` fixture for the diarization side; build a paired `Transcript` golden fixture for repeatability)
- [ ] Verify markdown renders correctly in Obsidian preview
- [ ] **Codex review pass (mandatory, single-ask)**: "Find bugs in `TranscriptFormatter` that EPIC-03/04 lessons should have prevented — alignment off-by-one at speaker boundaries, word-without-segment fallback, Codable + Sendable shape stability for EPIC-06 storage. P0/P1/P2, file:line, no fixes." Pre-flight via `/codex-budget-check check codex-review`.
- [ ] Code traceability: `// @implements API-201`

### Phase E: Finish (Harvest)

- [ ] Temp cleanup (delete `temp/epic-05-*` if any)
- [ ] Update API-201 status to Implemented in `SoT/SoT.API_CONTRACTS.md`
- [ ] Update TEST-301..303 to Implemented in `SoT/SoT.TESTING.md`
- [ ] Update RISK-005 mitigation row in `PRD.md` with measured alignment accuracy on the golden pair
- [ ] Append a Lifecycle Change Log row in `PRD.md`
- [ ] Update README backlog: EPIC-05 → ✅ Complete, flip Active EPIC pointer to whatever runs next (EPIC-06 if no parallelism, else EPIC-07 with mock formatter)
- [ ] Session audit

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | | | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-09 | Claude Agent | EPIC promoted to Active after EPIC-04 close (PR #5 merged). Cumulative carry-forward block added to Session State / above Objective: documents the inputs (Transcript + DiarizationResult — both Codable Sendable structs in memory), the AsyncTaskQueue cancellation-propagation fix that EPIC-05 inherits, the test-discipline pattern (golden fixtures for cross-stage contracts), and the now-mandatory Codex review cadence (5/5 EPICs since EPIC-02 caught real bugs). EPIC-05 deliverables call out the Codex Gate explicitly in Phase D. |
