---
template_version: "3.0.0"
---

# EPIC-07 SwiftUI Interface

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-02, EPIC-05, EPIC-06 (needs services to wire up)

---

## Session State (The "Brain Dump")

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Implement screens SCR-001→006 in SwiftUI
- **Context**: Design reference is ElevenLabs UI (dark, minimal, audio-centric). Can start UI shells earlier with mock data.

---

## Objective & Scope

> **Goal**: Implement all 6 screens (SCR-001→006) in SwiftUI, wired to services from EPICs 02-06, completing all user journeys (UJ-001→003).

- **Deliverables**:
  - [ ] SCR-001: Main Window (entry point, record button)
  - [ ] SCR-002: Recording View (active recording state, audio levels)
  - [ ] SCR-003: Processing View (transcription + diarization progress)
  - [ ] SCR-004: Transcript View (review, speaker rename, export)
  - [ ] SCR-005: Settings View (audio source, vault path, model selection)
  - [ ] SCR-006: Transcript History (list + search)
  - [ ] Design components: DES-001 (Record Button), DES-002 (Audio Level), DES-003 (Transcript Block), DES-101 (Speaker Label), DES-102 (Progress Pipeline)
  - [ ] Navigation flow between screens
  - [ ] First-launch onboarding for permissions (RISK-004 mitigation)
- **Out of Scope**: Custom themes, keyboard shortcuts, menu bar app mode

---

## Context & IDs

- **Screens**: SCR-001, SCR-002, SCR-003, SCR-004, SCR-005, SCR-006
- **Design**: DES-001, DES-002, DES-003, DES-101, DES-102, DES-301
- **User Journeys**: UJ-001, UJ-002, UJ-003
- **Personas**: PER-001, PER-002
- **Risks**: RISK-004

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: Read UJ-001→003, SCR-001→006, DES-XXX
- [ ] **Strategy**: Build with mock data first, then wire to real services

### Phase B: Design

- [ ] Review ElevenLabs UI patterns for dark audio-centric aesthetic
- [ ] Define SwiftUI color tokens + design system (DES-301)

### Phase C: Build (The "Context Window")

**Context Window 1: Core Flow (Record → Process → View)**

- [ ] SCR-001: Main window with record button + sidebar
- [ ] SCR-002: Recording view with waveform/level indicator + timer
- [ ] SCR-003: Processing view with pipeline progress stages
- [ ] SCR-004: Transcript view with speaker labels + export button
- [ ] Wire to AudioCaptureService, TranscriptionService, DiarizationService, TranscriptFormatter

**Context Window 2: Settings & History**

- [ ] SCR-005: Settings with audio device picker, vault path browser, model selector
- [ ] SCR-006: Transcript history list with search bar
- [ ] Wire to SettingsStore, database queries

**Context Window 3: Polish & Onboarding**

- [ ] First-launch permission request flow
- [ ] Empty states for no transcripts
- [ ] Error states for pipeline failures
- [ ] Speaker rename inline editing in SCR-004

### Phase D: Validate

- [ ] Manual walkthrough of UJ-001, UJ-002, UJ-003
- [ ] All screens render without crashes
- [ ] Permission flows work correctly
- [ ] Dark mode aesthetic matches reference

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Update SCR-XXX, DES-XXX statuses
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
