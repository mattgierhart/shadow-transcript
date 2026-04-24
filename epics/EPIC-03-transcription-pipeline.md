---
template_version: "3.0.0"
---

# EPIC-03 Transcription Pipeline

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-01

---

## Session State (The "Brain Dump")

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Implement WhisperKit wrapper service
- **Context**: Can be developed in parallel with EPIC-02 using test audio fixtures

---

## Objective & Scope

> **Goal**: Wrap WhisperKit into a TranscriptionService that transcribes WAV → segments with word-level timestamps, with model download/cache management.

- **Deliverables**:
  - [ ] `TranscriptionService` protocol + WhisperKit implementation (API-101)
  - [ ] Model download on first launch + cache management (INT-101)
  - [ ] Progress callback during transcription
  - [ ] `TranscriptionResult` and `TranscriptSegment` data types
  - [ ] Tests: TEST-101, TEST-102, TEST-103, TEST-104
- **Out of Scope**: Diarization (EPIC-04), multi-language, streaming/real-time

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

- [ ] **Context Loaded**: Read API-101, TECH-002, INT-101
- [ ] **Strategy**: Start with model loading, then transcription, then progress reporting

### Phase B: Design

- [ ] Review WhisperKit API (current Swift Package docs)
- [ ] Decide on test audio fixtures (short clips, known text)

### Phase C: Build (The "Context Window")

**Context Window 1: Model Management**

- [ ] WhisperKit initialization with model download to Application Support
- [ ] Model selection (base.en default, small.en, medium.en options)
- [ ] Skip download if model cached
- [ ] **Test**: TEST-104 (download + cache)

**Context Window 2: Transcription Service**

- [ ] `TranscriptionService` protocol implementation
- [ ] WhisperKit `transcribe()` wrapper with word-level timestamps
- [ ] Progress callback mapping from WhisperKit progress
- [ ] Error handling (invalid audio, model not loaded)
- [ ] **Test**: TEST-101 (transcribe), TEST-102 (timestamps), TEST-103 (progress)

### Phase D: Validate

- [ ] All 4 TEST-XXX cases pass
- [ ] Manual test: transcribe a 5-minute meeting recording
- [ ] Verify word timestamps are sensible
- [ ] Code traceability: `// @implements API-101`

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Update API-101 status to "Implemented"
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
