---
template_version: "3.0.0"
---

# EPIC-08 Pipeline Integration & Audio Lifecycle

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-02, EPIC-03, EPIC-04, EPIC-05, EPIC-06, EPIC-07

---

## Session State (The "Brain Dump")

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Wire all services into the end-to-end pipeline orchestrator
- **Context**: Integration EPIC — connects all services, implements temp audio lifecycle, and validates the full pipeline end-to-end

---

## Objective & Scope

> **Goal**: Wire all pipeline stages (capture → transcribe → diarize → format → store → export) into a single orchestrator, implement temp audio cleanup, and validate the full system end-to-end including privacy guarantees.

- **Deliverables**:
  - [ ] Pipeline orchestrator (coordinates all services in sequence per ARC-001)
  - [ ] `TempAudioCleanup` service (API-301)
  - [ ] Cleanup on: success, cancel, app quit, crash recovery (ARC-003)
  - [ ] End-to-end pipeline test with real audio
  - [ ] Privacy validation: no network calls (TEST-504)
  - [ ] Tests: TEST-501, TEST-502, TEST-503, TEST-504
- **Out of Scope**: Performance optimization, streaming pipeline

---

## Context & IDs

- **APIs**: API-301
- **Architecture**: ARC-001, ARC-003
- **Business Rules**: BR-101, BR-102, BR-103
- **Tests**: TEST-501, TEST-502, TEST-503, TEST-504
- **Risks**: RISK-006

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: Read ARC-001, ARC-003, API-301, BR-101→103
- [ ] **Strategy**: Pipeline orchestrator first, then cleanup, then E2E validation

### Phase B: Design

- [ ] Define PipelineOrchestrator interface (start, cancel, state observation)
- [ ] Define cleanup trigger points

### Phase C: Build (The "Context Window")

**Context Window 1: Pipeline Orchestrator**

- [ ] `PipelineOrchestrator` class coordinating: AudioCapture → Transcription → Diarization → Formatter → Database → Export
- [ ] State machine: idle → recording → processing → complete / error
- [ ] Progress aggregation across stages
- [ ] Cancellation support at any stage

**Context Window 2: Audio Lifecycle**

- [ ] `TempAudioCleanup` implementation (API-301)
- [ ] Cleanup after successful processing
- [ ] Cleanup on user cancel
- [ ] Register cleanup in `applicationWillTerminate`
- [ ] Orphaned file scan on app launch
- [ ] **Test**: TEST-501, TEST-502, TEST-503

**Context Window 3: End-to-End Validation**

- [ ] Record a real meeting → full pipeline → verify transcript in SQLite + Obsidian
- [ ] Run with network disabled → verify no outbound connections (TEST-504)
- [ ] Verify all KPIs: processing time < 5 min for 30 min audio, diarization accuracy > 80%

### Phase D: Validate

- [ ] All 4 TEST-XXX cases pass
- [ ] E2E pipeline succeeds with real audio
- [ ] No audio files remain in temp after any path (success, cancel, crash)
- [ ] Privacy: confirmed no network activity
- [ ] Code traceability: `// @implements API-301`, `// @implements ARC-001`

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Update ARC-001, ARC-003, API-301 statuses
- [ ] Record KPI baseline measurements in README
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
