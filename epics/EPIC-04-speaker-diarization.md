---
template_version: "3.0.0"
---

# EPIC-04 Speaker Diarization Sidecar

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-01

---

## Session State (The "Brain Dump")

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Implement diarize.py with pyannote pipeline, then PyInstaller packaging
- **Context**: Highest risk EPIC — pyannote CPU performance (RISK-001) and bundle size (RISK-003). Can develop in parallel with EPIC-02/03 using test fixtures.

---

## Objective & Scope

> **Goal**: Build and package the pyannote-audio diarization sidecar as a standalone PyInstaller binary invokable from Swift.

- **Deliverables**:
  - [ ] `sidecar/diarize.py` — full implementation with pyannote pipeline (API-102)
  - [ ] CLI interface: `--audio`, `--output`, `--num-speakers` flags
  - [ ] JSON output matching API-102 contract
  - [ ] Progress reporting via stdout `PROGRESS:XX`
  - [ ] Error handling with exit code 1 + stderr
  - [ ] PyInstaller ARM64 binary builds and runs
  - [ ] Swift subprocess bridge to invoke sidecar
  - [ ] Tests: TEST-201, TEST-202, TEST-203, TEST-204
- **Out of Scope**: WeSpeaker alternative, real-time diarization, GPU/MPS acceleration

---

## Context & IDs

- **APIs**: API-102
- **Architecture**: ARC-002
- **Tech**: TECH-006
- **Business Rules**: BR-101
- **Features**: FEA-003
- **Tests**: TEST-201, TEST-202, TEST-203, TEST-204
- **Risks**: RISK-001, RISK-003

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: Read API-102, ARC-002, TECH-006
- [ ] **Strategy**: Python CLI first, verify accuracy, then PyInstaller packaging, then Swift bridge

### Phase B: Design

- [ ] Test pyannote-audio on sample recordings (measure timing on Apple Silicon)
- [ ] Validate community-1 model accuracy on multi-speaker audio

### Phase C: Build (The "Context Window")

**Context Window 1: Python Diarization CLI**

- [ ] Implement `diarize.py` with argparse CLI
- [ ] pyannote Pipeline initialization with community-1 model
- [ ] Process audio → speaker segments JSON
- [ ] Progress reporting to stdout
- [ ] Error handling + exit codes
- [ ] **Test**: TEST-201 (valid JSON), TEST-202 (single speaker)

**Context Window 2: PyInstaller Packaging**

- [ ] Create `diarize.spec` for ARM64 macOS
- [ ] Bundle pyannote + torch + torchaudio dependencies
- [ ] Test binary runs standalone (no Python required)
- [ ] Measure binary size (target: < 500MB)
- [ ] **Test**: TEST-203 (progress), TEST-204 (error handling)

**Context Window 3: Swift Bridge**

- [ ] Swift `DiarizationService` that invokes sidecar via `Process`
- [ ] Parse stdout for progress, stderr for errors
- [ ] Parse JSON output into `DiarizationResult` struct
- [ ] Timeout handling for hung processes

### Phase D: Validate

- [ ] All 4 TEST-XXX cases pass
- [ ] Manual test: 10-minute, 3-speaker recording
- [ ] Benchmark: processing time for 30-minute audio on M1
- [ ] Binary size acceptable (< 500MB)
- [ ] Code traceability: `// @implements API-102`, `// @implements ARC-002`

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Update API-102 status to "Implemented"
- [ ] Record benchmark results in RISK-001 mitigation notes
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
