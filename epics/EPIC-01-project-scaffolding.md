---
template_version: "3.0.0"
---

# EPIC-01 Project Scaffolding & Dev Environment

> **State**: `✅ Complete`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: Claude Agent (session: 2026-05-06)

---

## Session State (The "Brain Dump")

> **Crucial**: Update this section before ending every session.

- **Last Action**: 2026-05-06 — Scaffolded the SwiftUI app via XcodeGen, added WhisperKit + GRDB SPM deps, created Python sidecar skeleton, wired up macOS-15 build CI. `xcodebuild build` and `xcodebuild test` both green locally; sidecar argparse stub verified.
- **Stopping Point**: All Phase A–E deliverables ticked. EPIC-01 closed.
- **Next Steps**: Begin EPIC-02 (Audio Capture Engine). Implement ScreenCaptureKit unified capture (mic + system audio) under `TranscriptShadow/Audio/`. First test target additions should validate the audio pipeline.
- **Context**: All downstream EPICs (02–08) can now build on a working skeleton. Generated `TranscriptShadow.xcodeproj` is gitignored — contributors regenerate via `xcodegen generate`.

---

## Objective & Scope

> **Goal**: Set up the Xcode project, Swift package dependencies, Python sidecar build, and folder structure so all subsequent EPICs can build on a working skeleton.

- **Deliverables**:
  - [x] Xcode project (XcodeGen-driven) with SwiftUI app target + test target (macOS 15+ deployment, arm64-only)
  - [x] WhisperKit added via SPM (resolved 0.18.0)
  - [x] GRDB.swift added via SPM (resolved 6.29.3)
  - [x] Info.plist with required permission descriptions (`NSMicrophoneUsageDescription`, `NSScreenCaptureUsageDescription`)
  - [x] App sandbox entitlements configured (sandbox + audio-input + network.client)
  - [x] Python `sidecar/` directory with `requirements.txt`, `diarize.py`, `diarize.spec`, `README.md`, `.gitignore`
  - [ ] Sidecar binary built via `pyinstaller diarize.spec` — **deferred to release time** (multi-GB / multi-minute build, not in CI). `python diarize.py --help` smoke verified.
  - [x] CI-compatible build verification (`.github/workflows/build.yml` — xcodebuild build + test + sidecar smoke on `macos-15`)
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

- [x] **Context Loaded**: Read PRD.md, SoT/, README.md
- [x] **Strategy**: XcodeGen-driven scaffolding (reproducible from `project.yml`); SPM packages declared in spec; sidecar as separate Python tree

### Phase B: Design

- [x] **Folder Structure**: `TranscriptShadow/`, `TranscriptShadowTests/`, `sidecar/`
- [x] **Entitlements**: sandbox + audio-input + network.client (ScreenCaptureKit handled at runtime via TCC + Info.plist usage strings)

### Phase C: Build (The "Context Window")

**Context Window 1: Xcode Project**

- [x] Create Xcode project (SwiftUI App, macOS 15+, Apple Silicon, via xcodegen)
- [x] Add WhisperKit SPM dependency (>= 0.16.0; resolved 0.18.0)
- [x] Add GRDB.swift SPM dependency (>= 6.29.0; resolved 6.29.3)
- [x] Configure Info.plist (NSMicrophoneUsageDescription, NSScreenCaptureUsageDescription, LSMinimumSystemVersion 15.0)
- [x] Configure .entitlements (app-sandbox, device.audio-input, network.client)
- [x] **Test**: `xcodebuild build -scheme TranscriptShadow -destination 'platform=macOS,arch=arm64'` exits 0 ✅

**Context Window 2: Python Sidecar**

- [x] Create `sidecar/requirements.txt` (pyannote.audio 3.x, torch 2.4.x, torchaudio, pyinstaller 6.x)
- [x] Create `sidecar/diarize.py` (argparse skeleton, JSON stub output)
- [x] Create `sidecar/diarize.spec` (PyInstaller arm64 onefile)
- [x] Create `sidecar/README.md` and `sidecar/.gitignore`
- [x] **Test**: `python3.11 diarize.py --help` and stub JSON write verified ✅
- [ ] **Deferred**: `pyinstaller diarize.spec` full bundle build — runs at release time, not on every push

### Phase D: Validate

- [x] Xcode project builds without errors (verified 2026-05-06)
- [x] Test target runs (`xcodebuild test` — 1 stub test passing)
- [x] Sidecar `python diarize.py --help` runs without error
- [x] Code traceability: `// @implements` / `# @implements` markers added across `project.yml`, Swift sources, sidecar, and CI workflow (TECH-001/002/006/007, ARC-002, ENV-001)

### Phase E: Finish (Harvest)

- [x] Generated `.xcodeproj` added to `.gitignore` (XcodeGen owns it; `project.yml` is the source of truth)
- [x] README.md Quick Commands updated to reflect xcodegen + macOS-15 + venv flow
- [x] CI workflow (`.github/workflows/build.yml`) wired (macos-15 runner, xcodebuild + sidecar smoke)
- [x] Session audit completed

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | XcodeGen overwrites Info.plist / entitlements when only `path` is given. Used `info.properties` + `entitlements.properties` so regeneration preserves required keys. | Documented inline in `project.yml`. | Resolved |
| 2 | Xcode 26.3 on this machine had a stale plug-in (`IDESimulatorFoundation` linkage error). Fixed by `xcodebuild -runFirstLaunch`. | Note in `sidecar/README.md` setup if encountered on a fresh box. | Resolved |
| 3 | Sandboxed app + bundled sidecar subprocess (EPIC-04) will need `com.apple.security.cs.disable-library-validation` and embedding under `Contents/Resources/`. | Tracked as a flag for EPIC-04. | Pending |
| 4 | PyInstaller bundle build is multi-GB and slow — kept out of CI. | Document in `sidecar/README.md` (done) + revisit at release time. | Resolved |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-06 | Claude Agent | Executed all phases — XcodeGen scaffold, SPM deps (WhisperKit 0.18.0, GRDB 6.29.3), entitlements, Python sidecar skeleton, CI workflow. Build + test green locally. |
