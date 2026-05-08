---
template_version: "3.0.0"
---

# EPIC-04b Diarization Sidecar — Swift `DiarizationService` Bridge

> **State**: `Planned` (blocked on EPIC-04a)
> **Lifecycle**: v0.7 Build Execution
> **Epic Lead**: TBD
> **Depends On**: EPIC-01 (Xcode scaffold), EPIC-04a (frozen JSON contract + working binary)

---

## Why this is its own EPIC

Split from the original EPIC-04 alongside EPIC-04a. The Swift side has its
own risk profile that has nothing to do with pyannote accuracy or
PyInstaller bundling:

- **Sandbox + entitlements**: spawning a bundled binary from a sandboxed
  `.app` requires `com.apple.security.cs.disable-library-validation` (and
  on hardened runtime, possibly `com.apple.security.cs.allow-unsigned-executable-memory`
  if torch's MPS path JIT-loads). EPIC-01 left the sandbox tight; this EPIC
  owns the loosening + documenting why.
- **`Process` lifecycle**: stdout/stderr piping, timeouts, cancellation
  (SIGTERM strategy), exit code → typed error mapping.
- **Cancellation parity** with EPIC-03: `CancellationError` must surface
  cleanly as `.cancelled`, not collapse into `.diarizationFailed`.
- **Test seam**: a `FakeDiarizationEngine` paralleling
  `FakeTranscriptionEngine` so unit tests don't invoke the real binary.

Starting this EPIC requires the EPIC-04a JSON schema to be **frozen and
committed**. Otherwise we'd be building a parser against a moving target.

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-08 — split from EPIC-04. Planning underway.
- **Stopping Point**: N/A — not yet started; blocked on EPIC-04a.
- **Next Steps**: Once EPIC-04a's JSON contract is committed, write the
  `DiarizationService` protocol matching the parsed shape, then implement
  the `Process` bridge against the bundled binary path.
- **Context**: Lower technical risk than 04a (Process is well-trodden
  ground), but the sandbox + bundling story has macOS-specific quirks
  worth careful design before any code.

---

## Cumulative Carry-Forward

> See `EPIC-04-speaker-diarization.md` for the full block. Swift-side
> highlights:

- **Cancellation handling** (EPIC-03 P2): pre-catch `CancellationError`
  *before* the generic catch. The bridge must propagate cancellation as
  SIGTERM to the subprocess and surface `.cancelled`, not
  `.diarizationFailed`.
- **Async serialization** (EPIC-03): if multiple diarization requests
  could overlap, serialize via `AsyncTaskQueue` (or accept that only one
  pipeline can run at a time anyway because pyannote loads the model into
  memory).
- **Module/class name collisions** (EPIC-03): `DiarizationResult` is
  unlikely to collide with anything we ship, but watch for clashes if we
  ever bring in a 3rd-party SDK that exports the same name. If a clash
  arises, rename **our** type (precedent: `Transcript`).
- **Test discipline**: golden-JSON fixtures from EPIC-04a + a fake binary
  path that returns those fixtures via stdin or pre-written files. Real-
  binary integration test is one or two cases at most.
- **xattr/codesign friction**: same `xattr -rc` workaround if codesign
  fails on a fresh build.

---

## Objective & Scope

> **Goal**: Implement `DiarizationService` (Swift) that consumes the
> EPIC-04a binary as a subprocess and returns a `DiarizationResult` Swift
> value matching the frozen JSON contract. End-to-end: pass it the WAV URL
> from `AudioCaptureService.stopCapture()`, get speaker segments back.

- **Deliverables**:
  - [ ] `DiarizationService` protocol + `DiarizationResult` / `SpeakerSegment` Swift types matching EPIC-04a's JSON schema
  - [ ] `PyannoteSidecarDiarizationService` final-class implementation that locates the bundled binary, spawns it via `Process`, parses stdout for progress + stderr for errors, parses the JSON output file
  - [ ] Sandbox + entitlement adjustments: minimum `com.apple.security.cs.disable-library-validation` for the bundled binary, with rationale documented in this EPIC and the entitlements file
  - [ ] Binary embedding via XcodeGen: `Resources/diarize` (or equivalent path inside `.app/Contents/Resources/`)
  - [ ] HF token plumbing: read from a configurable source (`UserDefaults`? Keychain? — design decision in Phase B), inject via `Process.environment["HF_TOKEN"]`
  - [ ] Cancellation: `Task.checkCancellation()` + SIGTERM to the subprocess on cancel; surfaces `DiarizationError.cancelled`
  - [ ] Timeout handling for hung processes
  - [ ] `FakeDiarizationEngine` test double + tests using golden JSON from EPIC-04a
  - [ ] Tests: `TEST-201` (Swift parses the golden JSON correctly) + Swift-side TEST-204-equivalent (each exit code maps to the expected `DiarizationError`)
- **Out of Scope**: pyannote pipeline implementation (EPIC-04a),
  word-level speaker attribution (EPIC-05), end-to-end pipeline
  integration with the UI (EPIC-07).

---

## Context & IDs

- **APIs**: API-102 (Swift consumer half — completes the contract)
- **Architecture**: ARC-002 (Python sidecar pattern — Swift side)
- **Tech**: (none new — relies on Foundation `Process` + EPIC-04a artifact)
- **Business Rules**: BR-101 (local-only — verify subprocess inherits sandbox correctly)
- **Features**: FEA-003 (speaker diarization)
- **Tests**: Subset of TEST-201..204 implemented Swift-side; 04a covers the binary side
- **Risks**: Sandbox + library-validation friction (will record as EPIC observations if it surprises us)

7 SoT references — comfortably under the BROAD threshold.

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: EPIC-04a closing artifacts (JSON schema, golden fixture, exit code map), API-102 SoT entry, EPIC-01 entitlements file, EPIC-03 cancellation patterns
- [ ] **Strategy**: Build the protocol + types from the schema, then the `Process` bridge against the binary path. Tests use the golden JSON fixture from 04a + a `FakeDiarizationEngine` for non-binary paths.
- [ ] **Decision points** (filled in during planning research; see below):
  - HF token storage: env-var-only for MVP vs Keychain
  - Binary location strategy: `.app/Contents/Resources/diarize` vs an XPC service
  - Whether to add `AsyncTaskQueue` upfront or wait for evidence of concurrent use

### Phase B: Design — Sandbox + Entitlements

- [ ] Document the entitlement deltas vs EPIC-01's tight default:
  - Add `com.apple.security.cs.disable-library-validation` (required for any embedded binary)
  - Add `com.apple.security.cs.allow-unsigned-executable-memory` if torch MPS path JIT-loads (TBD from 04a's runtime behavior)
  - **Keep** `com.apple.security.app-sandbox = true`
- [ ] Document the bundle-embedding approach in `project.yml`: copy `sidecar/dist/diarize` into `Contents/Resources/` via a Run Script Build Phase or XcodeGen `buildPhases.copyFiles`
- [ ] Decide HF token source: env var (passthrough at spawn) vs Keychain (more secure, more code). For MVP: env var or app config; Keychain comes when EPIC-07 builds the settings UI.
- [ ] Decide cancellation contract: `Task.checkCancellation()` polled at the I/O boundary; SIGTERM on cancel; if process doesn't exit in 5s, SIGKILL.

### Phase C: Build

**Context Window 1: Types + Protocol**

- [ ] `DiarizationResult`, `SpeakerSegment`, `Speaker` Swift types decoded from the EPIC-04a JSON schema via `Codable`
- [ ] `DiarizationError` enum: `.audioFileMissing`, `.modelLoadFailed`, `.huggingFaceAuthRequired`, `.outOfMemory`, `.binaryMissing(URL)`, `.binaryFailed(exitCode: Int32, stderr: String)`, `.cancelled`, `.timeout(seconds: TimeInterval)`
- [ ] `DiarizationService` protocol; convenience init pinning the binary URL

**Context Window 2: Process Bridge**

- [ ] `PyannoteSidecarDiarizationService` final class (parallel to `WhisperKitEngine`'s class-not-actor pattern)
- [ ] Locate binary: `Bundle.main.url(forResource: "diarize", withExtension: nil, subdirectory: "Resources")` (path TBD)
- [ ] Spawn via `Process`, stdin closed, stdout piped (progress regex parser), stderr piped (capture for error messages), output file path passed via `--output`
- [ ] Per-line progress parsing (`PROGRESS:0.42`) → forward to a `progress: (Double) -> Void` closure
- [ ] Wait + parse JSON file → `DiarizationResult`
- [ ] Map exit codes → typed errors per the matrix in EPIC-04a
- [ ] Cancellation: spawn the wait inside a `Task` that monitors `Task.isCancelled`, SIGTERM on cancel, SIGKILL after 5s

**Context Window 3: Tests**

- [ ] Unit tests with `FakeDiarizationEngine` (no Process involved) — verify the protocol surface, error mapping, cancellation propagation
- [ ] One integration test using a tiny shell script binary that emits the golden JSON + a fake `PROGRESS:` line — verifies the parser end-to-end without invoking real pyannote
- [ ] Optional: a `// @available(.*)` integration test that invokes the real bundled binary if it's present, skipped otherwise

### Phase D: Validate

- [ ] All Swift-side TEST-XXX cases pass
- [ ] Manual end-to-end run: `AudioCaptureService.stopCapture()` URL → `DiarizationService.diarize(audioURL:)` → speaker segments returned, `.app` builds + runs in Xcode without sandbox-related crashes
- [ ] **Codex review pass** before EPIC close (single-ask: "Find bugs in DiarizationService that EPIC-03's `WhisperKitEngine` lessons should have prevented")
- [ ] Code traceability: `// @implements API-102` markers

### Phase E: Finish (Harvest)

- [ ] API-102 status in `SoT/SoT.API_CONTRACTS.md` flipped from "Implemented (Python only)" to "Implemented (full)" with both signatures
- [ ] Record entitlement additions in `SoT/SoT.DEPLOYMENT.md` (if it exists; otherwise capture in this EPIC's observations)
- [ ] Update `epics/EPIC-04-speaker-diarization.md` index pointing at this EPIC's outcomes
- [ ] Session audit

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | | | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-05-08 | Claude Agent | EPIC created via split from EPIC-04 to isolate the Swift bridge from the Python pipeline + packaging risk profile. |
