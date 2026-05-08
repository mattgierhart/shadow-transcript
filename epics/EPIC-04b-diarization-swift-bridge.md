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

### Phase A: Plan — Research-Driven Decisions (2026-05-08)

- [x] **Context Loaded**: EPIC-04a Phase B (JSON schema), API-102 SoT entry, EPIC-01 entitlements file, EPIC-03 cancellation + `AsyncTaskQueue` patterns. Web research synthesized below.

**Decision 1 — `Process` vs `swift-subprocess`**: Adopt **`swiftlang/swift-subprocess`** (pre-1.0, currently 0.4.x; `Process` + `readabilityHandler` is a documented foot-gun under Swift 6 strict concurrency — captures non-Sendable state, fires after EOF). swift-subprocess provides `for try await line in outputSequence.lines()`, `PlatformOptions.teardownSequence = [.gracefulShutDown(allowedDurationToNextStep: .seconds(5))]` for SIGTERM-then-SIGKILL, and clean Task cancellation. Acceptable for v0.7 milestone; flag for revisit before public ship if it hasn't reached 1.0.

**Decision 2 — Binary location**: `.app/Contents/Resources/diarize/` (the `--onedir` tree from EPIC-04a). Located via `Bundle.main.url(forResource: "diarize", withExtension: nil, subdirectory: "Resources/diarize")`. **Not** an XPC service — XPC's serialization overhead would slow down audio path passing, and we'd lose the ability to stream stdout for progress.

**Decision 3 — File access (audio path → child)**: **Security-scoped bookmarks**. The child does not inherit Powerbox grants from `NSOpenPanel` even though `inherit=true` propagates the sandbox. Parent calls `url.bookmarkData(options: .withSecurityScope)`, base64-encodes, passes via `Process.environment["TRANSCRIPT_SHADOW_AUDIO_BOOKMARK"]`. Child resolves with `URL(resolvingBookmarkData:options:.withSecurityScope...)` and brackets reads with `startAccessingSecurityScopedResource()`. FD-passing is the alternative but breaks for >2 GB files and complicates streaming for the Python side.

**Decision 4 — HF token storage**: **Env var passthrough at spawn**, sourced from a configurable location. For MVP: a settings file under `~/Library/Application Support/TranscriptShadow/`. Keychain wrapping comes when EPIC-07 builds the settings UI. The child reads `HF_TOKEN`; if missing and the model isn't cached, exits with code 3 → mapped to `DiarizationError.huggingFaceAuthRequired`.

**Decision 5 — Concurrency**: A diarization run holds the entire pyannote pipeline in memory; running two simultaneously would 2× memory + thrash. **Add `AsyncTaskQueue` upfront** (same one we shipped in EPIC-03 for `WhisperKitEngine`). Cheaper than discovering the bug from a UI race in EPIC-07.

### Phase B: Design — Sandbox + Entitlements Matrix

**Parent app (`TranscriptShadow.entitlements`)** — additions to the EPIC-01 baseline:

| Entitlement | Reason | Status |
|------------|--------|--------|
| `com.apple.security.app-sandbox` | (existing) | Keep |
| `com.apple.security.device.audio-input` | (existing — mic) | Keep |
| `com.apple.security.network.client` | (existing — WhisperKit model download) | Keep |
| **`com.apple.security.cs.disable-library-validation`** | **Required** — PyInstaller bootloader loads `*.dylib` / `*.so` under `Resources/diarize/_internal/` not signed by our Team ID. Without this, dyld refuses under hardened runtime. | Add |
| **`com.apple.security.cs.allow-unsigned-executable-memory`** | **Required** — CPython bytecode + ctypes paths and torch's runtime memory. Documented in every PyInstaller-on-mac entitlements file in the wild (Buzz, txoof gist). | Add |
| `com.apple.security.cs.allow-jit` | Recommended alongside `allow-unsigned-executable-memory`. PyTorch MPS goes through Metal compilers; cheap to add, expensive to debug if missing. | Add |
| `com.apple.security.files.user-selected.read-only` | `NSOpenPanel` returns a usable URL for the audio file picker. | Add |
| `com.apple.security.files.bookmarks.app-scope` | Persist bookmarks across launches (settings + recent recordings). | Add |

**Child binary (`Resources/diarize/diarize.entitlements`)** — separate file:

| Entitlement | Value | Reason |
|------------|-------|--------|
| `com.apple.security.app-sandbox` | true | Inherit sandbox |
| `com.apple.security.inherit` | true | Pull sandbox from parent — **only entitlement that may be set on the child**. Per Apple's helper-tool doc + indie-stack post, any other sandbox entitlement on the child causes `_libsecinit_appsandbox` crash. |

**Critical**: The `com.apple.security.get-task-allow` entitlement that Xcode auto-injects in debug builds **kills the child instantly**. Strip it post-build with `codesign --entitlements diarize.entitlements --force` overwriting the auto-generated one.

### Codesigning Sequence

Bottom-up, **never `--deep`** (deprecated since macOS 13; notarization-rejection trigger):

1. Every `.dylib` / `.so` under `Resources/diarize/_internal/` — `codesign --force --options=runtime --timestamp -s "Developer ID..."`
2. The inner `Resources/diarize/diarize` binary — same flags **plus** `--entitlements diarize.entitlements`
3. The app's `Contents/MacOS/TranscriptShadow` (Xcode handles)
4. The `.app` bundle — `--entitlements TranscriptShadow.entitlements`
5. Verify: `codesign --verify --deep --strict --verbose=2` (verify only — `--deep` is OK on verify, just not on sign)

XcodeGen note: this needs a **Run Script Build Phase** that walks the embedded tree and signs each binary individually before bundle-signing. Reference template: Buzz's Makefile at `chidiwilliams/buzz`.

### Phase B: Design — Process bridge contract

(Sandbox + entitlements are above in Phase A. This section locks the
Swift-side contract that consumes EPIC-04a's binary.)

- [x] **Stdout parsing**: line-by-line via swift-subprocess's `outputSequence.lines()`. Match `^PROGRESS:(\d+(?:\.\d+)?)$` → forward the float to the `progress: (Double) -> Void` closure. Anything else on stdout is logged as a warning (shouldn't happen in success path per 04a Phase B).
- [x] **Stderr parsing**: collect entirely; on non-zero exit, parse `^ERROR:(\d+):(.+)$` to extract code + message for the `DiarizationError.binaryFailed(...)` case.
- [x] **Output reading**: pass `--output <tmpfile>` to the binary. After exit, read the tmpfile and `JSONDecoder` it into `DiarizationResult`. Don't try to parse stdout for JSON.
- [x] **Cancellation**: `withTaskCancellationHandler { ... }` wrapping the `subprocess.run` call. swift-subprocess's `teardownSequence = [.gracefulShutDown(allowedDurationToNextStep: .seconds(5))]` handles SIGTERM-then-SIGKILL automatically.
- [x] **Timeout**: 30 s per minute of input audio (rough RTF×3 ceiling) with a 5-minute floor. Configurable via initializer parameter for future tuning.
- [x] **Concurrency**: All `diarize()` calls go through `AsyncTaskQueue` (the same one we shipped in EPIC-03). Two concurrent calls would 2× the pipeline's memory footprint.

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
| 1 | swift-subprocess is **0.4.x / pre-1.0**. Acceptable for a v0.7 internal milestone but flag for revisit before public ship. Alternative is to fall back to Foundation `Process` with the actor-wrap workaround documented in the Swift Forums thread on `Process+NSPipe` under strict concurrency. | Adopt swift-subprocess for now; create a follow-up issue to re-evaluate before EPIC-08 / public ship. | Pending |
| 2 | `com.apple.security.cs.allow-jit` may not be strictly required if pyannote / torch MPS doesn't actually JIT user code. Empirical test in EPIC-04a's spike — add only if "MAP_JIT" failures appear in Console. | Default to including it; cheap to add. | Pending (verify in 04a spike) |
| 3 | First launch on Sequoia+ shows a "downloaded from internet" Gatekeeper prompt for the inner binary unless the `.app` is launched once via Finder (LaunchServices then trusts the spawn). | Document in QA plan; mention in EPIC-07 onboarding flow. | Carry-forward to EPIC-07 |
| 4 | Reference template for the codesign sequence is Buzz (`chidiwilliams/buzz`) — closest OSS precedent for a PyInstaller-bundled torch app shipped notarized. **No public OSS macOS app shipping `pyannote.audio` + torch via PyInstaller specifically** — pyannote inheritance is ours to debug. | Mirror Buzz's Makefile; budget extra debugging time when notarization first runs. | Pending |
| 5 | Audio file passed to the child via security-scoped bookmark in `Process.environment["TRANSCRIPT_SHADOW_AUDIO_BOOKMARK"]` (base64-encoded). The child's CLI contract from EPIC-04a needs to support reading this env var as an alternative to `--audio <path>` when the path is sandboxed. | Coordinate with EPIC-04a Phase C to add bookmark-resolution to the binary. | Carry-forward to EPIC-04a |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-05-08 | Claude Agent | EPIC created via split from EPIC-04 to isolate the Swift bridge from the Python pipeline + packaging risk profile. |
