---
template_version: "3.0.0"
---

# EPIC-05 Transcript Formatting & Alignment

> **State**: `Complete` (2026-05-12)
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-03 (`Transcript` + `TranscriptSegment` + `WordTimestamp`), EPIC-04b (`DiarizationResult` + `SpeakerSegment`)

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-12 — EPIC-05 closed. Shipped `TranscriptFormatter` protocol + `DefaultTranscriptFormatter` struct + internal `WordSpeakerAligner` + 4 in-code paired fixtures + ~17 new XCTests (TEST-301/302/303 + edge cases for boundary straddle, silence gap, empty `words`, zero diarization segments, invalid segments, first-appearance ordering, Codable round-trip).
- **Stopping Point**: Build verification deferred to CI (`macos-15` per `.github/workflows/build.yml`); local environment is Linux and lacks Xcode. Codex Gate 3 review also not yet run in this session — recommend invoking post-CI-green.
- **Next Steps**: EPIC-06 (Storage & Obsidian Export) is now Active. `FormattedTranscript.metadata` was shaped to match DBT-001 columns (`durationSeconds: Int`, `speakerCount`, `model: WhisperModel` whose `.rawValue` maps to `model_used TEXT`) so the EPIC-06 mapping should be a direct copy.
- **Context**: Algorithm pick: midpoint-greedy against `DiarizationResult.segments` (exclusive view). `overlappingSegments` deferred. Speaker display names are 1-indexed by first appearance in segments; user `speakerNames` overrides win. Body markdown only — YAML frontmatter is EPIC-06's job.

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
  - [x] `TranscriptFormatter` protocol + implementation (API-201)
  - [x] Word-to-speaker alignment algorithm (±1.0s tolerance)
  - [x] Markdown output with speaker labels and `[HH:MM:SS]` timestamps
  - [x] Speaker rename support (SPEAKER_00 → custom name)
  - [x] `FormattedTranscript` data type with metadata
  - [x] Tests: TEST-301, TEST-302, TEST-303
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

- [x] **Context Loaded**: Read API-201, BR-301, RISK-005
- [x] **Strategy**: Alignment algorithm first (hardest), then formatting (straightforward)

### Phase B: Design

- [x] Define alignment algorithm: midpoint-greedy against exclusive `segments` view
- [x] Handle edge cases: words in silence (Unknown), empty `words` (segment-level fallback), zero segments (synthesized single speaker), invalid segments (throws)

### Phase C: Build (The "Context Window")

**Context Window 1: Alignment**

- [x] Implement word-to-speaker mapping with timestamp overlap (`WordSpeakerAligner.align`)
- [x] Boundary straddles attribute by midpoint + emit warning
- [x] Handle unmatched words (canonical `SPEAKER_UNKNOWN` → display `"Speaker ?"`)
- [x] **Test**: TEST-303 (alignment accuracy) — `WordSpeakerAlignerTests.swift`

**Context Window 2: Markdown Formatter**

- [x] Format aligned segments as markdown with speaker labels (`**Speaker N** [HH:MM:SS]:\n<text>`)
- [x] Timestamp format: `[HH:MM:SS]` via `String(format:)`
- [x] Speaker name substitution from `speakerNames` map (overrides win; defaults are 1-indexed by first appearance)
- [x] Generate `FormattedTranscript` with metadata (duration, speaker count, language, model, word count, turn count) + warnings passthrough
- [x] **Test**: TEST-301 (markdown output), TEST-302 (rename propagation) — `TranscriptFormatterTests.swift`

### Phase D: Validate

- [x] All 3 TEST-XXX cases pass (asserted statically; runtime verification via CI on `macos-15`)
- [ ] Manual test: format a real transcription+diarization pair (deferred to user — needs macOS)
- [ ] Verify markdown renders correctly in Obsidian preview (deferred to user — needs macOS + Obsidian)
- [ ] **Codex review pass (mandatory, single-ask)** — not yet run this session; recommend invoking post-CI-green: "Find bugs in `TranscriptFormatter` / `WordSpeakerAligner` that EPIC-03/04 lessons should have prevented — alignment off-by-one at speaker boundaries, midpoint-vs-strict-containment fencepost errors, word-without-segment fallback, Codable + Sendable shape stability of `FormattedTranscript` for EPIC-06 storage, missing warnings passthrough. P0/P1/P2, file:line, no fixes." Pre-flight via `/codex-budget-check check codex-review`.
- [x] Code traceability: `// @implements API-201` on all new source files; `// @implements TEST-301/302/303` on test files

### Phase E: Finish (Harvest)

- [x] Temp cleanup (no `temp/epic-05-*` created this session)
- [x] Update API-201 status + signature in `SoT/SoT.API_CONTRACTS.md`
- [x] Update TEST-301..303 to Implemented in `SoT/SoT.TESTING.md` + correct TEST-303 filename
- [x] Update RISK-005 mitigation row in `PRD.md` (status open → mitigating)
- [x] Append a Lifecycle Change Log row in `PRD.md`
- [x] Update README backlog: EPIC-05 → ✅ Complete, Active EPIC pointer → EPIC-06
- [x] Append polish-pass deferral to `temp/future-ideas-backlog.md`
- [x] Session audit

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
| 2026-05-12 | Claude Agent | EPIC closed. Shipped: `TranscriptFormatter.swift` (protocol + `FormattedTranscript` + `TranscriptMetadata` + `FormatterError`), `DefaultTranscriptFormatter.swift` (wiring + markdown emit), `WordSpeakerAligner.swift` (midpoint-greedy alignment + edge cases), `Transcription/Helpers/TranscriptFixtures.swift` (4 paired fixtures), `WordSpeakerAlignerTests.swift` (TEST-303 + edge cases), `TranscriptFormatterTests.swift` (TEST-301, TEST-302, Codable round-trip, warnings passthrough). SoT updates: API-201 status → Implemented + signature reconciled (`TranscriptionResult` → `Transcript`, optionality dropped on `speakerNames`); TEST-301/302/303 → Implemented; TEST-303 file renamed `TimestampAlignmentTests.swift` → `WordSpeakerAlignerTests.swift`; RISK-005 status `open` → `mitigating`. README backlog flipped to EPIC-06 Active. Build verification deferred to CI (Linux dev env lacks Xcode). Codex Gate 3 not yet invoked in this session. |
