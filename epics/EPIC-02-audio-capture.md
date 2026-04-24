---
template_version: "3.0.0"
---

# EPIC-02 Audio Capture Engine

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-01

---

## Session State (The "Brain Dump")

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Implement AudioCaptureService with AVAudioEngine + ScreenCaptureKit
- **Context**: Core pipeline stage 1 — everything downstream depends on audio capture producing a WAV

---

## Objective & Scope

> **Goal**: Implement microphone capture (AVAudioEngine), system audio capture (ScreenCaptureKit), and audio mixing into a single WAV file.

- **Deliverables**:
  - [ ] `AudioCaptureService` protocol + concrete implementation (API-001)
  - [ ] `AudioMixer` utility for mic + system audio (API-002)
  - [ ] Microphone capture via AVAudioEngine (INT-201)
  - [ ] System audio capture via ScreenCaptureKit (INT-202)
  - [ ] Graceful fallback to mic-only when Screen Recording permission denied
  - [ ] Audio level stream for UI visualization
  - [ ] Duration limit guard (BR-402)
  - [ ] Tests: TEST-001, TEST-002, TEST-003, TEST-004, TEST-005
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

- [ ] **Context Loaded**: Read API-001, API-002, INT-201, INT-202
- [ ] **Strategy**: Implement AVAudioEngine mic first (simpler), then ScreenCaptureKit, then mixer

### Phase B: Design

- [ ] Review Azayaka source for ScreenCaptureKit patterns
- [ ] Draft permission request UX flow

### Phase C: Build (The "Context Window")

**Context Window 1: Microphone Capture**

- [ ] Implement `AudioCaptureService` protocol
- [ ] AVAudioEngine mic capture with tap-on-input-node
- [ ] Audio level stream via RMS calculation
- [ ] Write to temp WAV file continuously (crash safety per RISK-006)
- [ ] **Test**: TEST-001 (start/stop), TEST-002 (audio levels)

**Context Window 2: System Audio**

- [ ] ScreenCaptureKit audio-only capture (exclude video)
- [ ] Permission request handling + graceful fallback (TEST-005)
- [ ] `AudioMixer.mix()` for dual-source WAV output
- [ ] **Test**: TEST-003 (valid WAV), TEST-004 (duration limit)

### Phase D: Validate

- [ ] All 5 TEST-XXX cases pass
- [ ] Manual test: record a real meeting for 2 minutes
- [ ] Verify WAV file is valid (playable in QuickTime)
- [ ] Code traceability: `// @implements API-001`, `// @implements API-002`

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Update API-001, API-002 status to "Implemented"
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
