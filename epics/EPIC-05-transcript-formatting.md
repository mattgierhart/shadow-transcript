---
template_version: "3.0.0"
---

# EPIC-05 Transcript Formatting & Alignment

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-03, EPIC-04 (needs TranscriptionResult + DiarizationResult types)

---

## Session State (The "Brain Dump")

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Implement word↔speaker alignment algorithm, then markdown formatter
- **Context**: RISK-005 (alignment accuracy) is the key challenge here

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
- [ ] Manual test: format a real transcription+diarization pair
- [ ] Verify markdown renders correctly in Obsidian preview
- [ ] Code traceability: `// @implements API-201`

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Update API-201 status, RISK-005 status
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
