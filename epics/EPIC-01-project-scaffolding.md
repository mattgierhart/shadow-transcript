---
template_version: "3.0.0"
---

# EPIC-01 Project Scaffolding & Dev Environment

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD

---

## Session State (The "Brain Dump")

> **Crucial**: Update this section before ending every session.

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Create Xcode project, add SPM deps, scaffold folder structure, build pyannote sidecar
- **Context**: This is the foundation EPIC — all others depend on it

---

## Objective & Scope

> **Goal**: Set up the Xcode project, Swift package dependencies, Python sidecar build, and folder structure so all subsequent EPICs can build on a working skeleton.

- **Deliverables**:
  - [ ] Xcode project with SwiftUI app target + test target (macOS 15+ deployment)
  - [ ] WhisperKit added via SPM
  - [ ] GRDB.swift added via SPM
  - [ ] Info.plist with required permission descriptions (mic, screen recording)
  - [ ] App sandbox entitlements configured
  - [ ] Python `sidecar/` directory with `requirements.txt`, `diarize.py`, and `diarize.spec` (PyInstaller)
  - [ ] Sidecar builds successfully via `pyinstaller diarize.spec`
  - [ ] CI-compatible build verification (`xcodebuild build`)
- **Out of Scope**: Implementing any service logic — this is structure only

---

## Context & IDs

- **Technical Decisions**: TECH-001, TECH-002, TECH-006, TECH-007
- **Architecture**: ARC-002
- **Environment**: ENV-001
- **Business Rules**: BR-201 (macOS only), BR-401 (Apple Silicon)

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: Read PRD.md, SoT/, README.md
- [ ] **Strategy**: Scaffold Xcode project first, then add SPM deps, then sidecar build

### Phase B: Design

- [ ] **Folder Structure**: Define `TranscriptShadow/`, `TranscriptShadowTests/`, `sidecar/`
- [ ] **Entitlements**: Draft entitlements file with audio-input + screencapture

### Phase C: Build (The "Context Window")

**Context Window 1: Xcode Project**

- [ ] Create Xcode project (SwiftUI App, macOS 15+, Apple Silicon)
- [ ] Add WhisperKit SPM dependency
- [ ] Add GRDB.swift SPM dependency
- [ ] Configure Info.plist (NSMicrophoneUsageDescription, etc.)
- [ ] Configure .entitlements (audio-input, screencapture)
- [ ] **Test**: `xcodebuild build -scheme TranscriptShadow` succeeds

**Context Window 2: Python Sidecar**

- [ ] Create `sidecar/requirements.txt` (pyannote.audio, torch, torchaudio)
- [ ] Create `sidecar/diarize.py` (CLI skeleton: argparse, stub pipeline)
- [ ] Create `sidecar/diarize.spec` (PyInstaller config for ARM64)
- [ ] **Test**: `pyinstaller diarize.spec` produces working binary

### Phase D: Validate

- [ ] Xcode project builds without errors
- [ ] Test target runs (even if empty)
- [ ] Sidecar binary executes `./diarize --help` without error
- [ ] Code traceability: `// @implements ENV-001` in setup files

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Spec finalization
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
