---
template_version: "3.0.0"
---

# EPIC-04b Diarization Sidecar — Swift `DiarizationService` Bridge

> **State**: ✅ Complete (2026-05-09)
> **Lifecycle**: v0.7 Build Execution
> **Epic Lead**: Claude Agent (Opus 4.7)
> **Depends On**: EPIC-01 (Xcode scaffold), EPIC-04a (frozen JSON contract + working binary)
> **Unblocks**: EPIC-05 (Transcript Formatting & Alignment) now active

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

- **Last Action**: 2026-05-09 — Phase C (CW1+CW2+CW3) + Phase D + Phase E
  complete. Swift `DiarizationResult` Codable types decode the EPIC-04a
  golden fixture cleanly. `PyannoteSidecarDiarizationService` spawns the
  bundled binary via Foundation `Process` (not swift-subprocess; deviation
  documented), streams `PROGRESS:` lines via `FileHandle.bytes.lines`,
  serializes via `AsyncTaskQueue`, surfaces cancellation as `.cancelled`
  (not `.binaryFailed`). Production entitlements gained the +5 EPIC-04b
  additions; child binary entitlements are `inherit`-only. `project.yml`
  has a postBuildScripts Run Script that copies and bottom-up codesigns
  the embedded tree. Codex Gate 2 caught 10 bugs (2 P0, 6 P1, 2 P2),
  including a pre-existing AsyncTaskQueue race from EPIC-03 — all
  resolved before commit. SoT (API-102, INT-102, TEST-201/204, DEP-002),
  PRD (RISK-007 mitigated, change log), and README updated. Branch
  `feat/epic-04-split` is at `<sha>` with 2 EPIC-04b commits + 1 Phase E.
- **Stopping Point**: EPIC-04b is closed for execution. No further work
  needed in this EPIC.
- **Next Steps**: EPIC-05 (Transcript Formatting & Alignment) is now
  Active. The Codable types + golden fixtures from EPIC-04a/04b are the
  inputs to the alignment algorithm. The Active EPIC pointer in README
  has been flipped.
- **Context**: The bridge worked first try at the contract level (the
  Codable types decoded the EPIC-04a fixture without modification). The
  hard work was in the concurrency model — Foundation `Process` +
  `AsyncTaskQueue` cancellation propagation + the cancel-vs-timeout split.
  Codex Gate 2 was high signal — caught a pre-existing AsyncTaskQueue
  race that's been present since EPIC-03.

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
  - [x] `DiarizationService` protocol + `DiarizationResult` / `SpeakerSegment` Swift types matching EPIC-04a's JSON schema 1.0
  - [x] `PyannoteSidecarDiarizationService` final-class implementation that locates the bundled binary, spawns it via Foundation `Process` (Foundation, not swift-subprocess — see Decision 1 deviation in observations), parses stdout for progress + stderr for errors, parses the JSON output file
  - [x] Sandbox + entitlement adjustments: +5 production entitlements per Phase B matrix; child `inherit`-only entitlements file; Debug-only override for unsandboxed test target
  - [x] Binary embedding via XcodeGen: postBuildScripts Run Script copies `sidecar/dist/diarize/` → `Resources/diarize/`
  - [x] HF token plumbing: env var passthrough sourced from a `hfTokenProvider` closure (defaults to `ProcessInfo.processInfo.environment["HF_TOKEN"]`)
  - [x] Cancellation: `withTaskCancellationHandler` + SIGTERM via Foundation `Process.terminate`; surfaces `DiarizationError.cancelled` (verified by `testCancellationSurfacesCancelledNotBinaryFailed`, hardened in Codex Gate 2 P2)
  - [x] Timeout handling: 600 s default; SIGTERM + 5 s grace + SIGKILL fallback
  - [x] `FakeDiarizationService` test double + tests using golden JSON from EPIC-04a
  - [x] Tests: `TEST-201` (Codable round-trip on golden fixture) + `TEST-204` (exit-code → `DiarizationError` mapping) + 12 integration tests against shell-script fakes — 22 new XCTests, 74 total in the suite
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

**Decision 2 — Binary location**: `.app/Contents/Resources/diarize/` (the `--onedir` tree from EPIC-04a). Located via `Bundle.main.resourceURL?.appendingPathComponent("diarize/diarize")` — the `subdirectory:` parameter on `Bundle.url(forResource:)` is **already** relative to `Resources/`, so the path passed to it is just `"diarize"` (not `"Resources/diarize"`). **Not** an XPC service — XPC's serialization overhead would slow down audio path passing, and we'd lose the ability to stream stdout for progress.

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
- [ ] Locate binary: `Bundle.main.resourceURL?.appendingPathComponent("diarize/diarize")` (per Phase A Decision 2; `subdirectory:` is relative to `Resources/`, so use `resourceURL` directly to avoid the `Resources/Resources/diarize/...` mistake)
- [ ] Spawn via **`swiftlang/swift-subprocess`** (per Phase A Decision 1 — Foundation `Process` + `readabilityHandler` is the documented foot-gun under Swift 6 strict concurrency). Use `outputSequence.lines()` for stdout streaming; `errorSequence` for stderr capture; output file path passed via `--output`
- [ ] Per-line progress parsing (`PROGRESS:0.42`) → forward to a `progress: (Double) -> Void` closure
- [ ] Wait + parse JSON file → `DiarizationResult`
- [ ] Map exit codes → typed errors per the matrix in EPIC-04a
- [ ] Cancellation: rely on swift-subprocess's `PlatformOptions.teardownSequence = [.gracefulShutDown(allowedDurationToNextStep: .seconds(5))]` to do SIGTERM-then-SIGKILL automatically; wrap the call in `withTaskCancellationHandler` so a parent-Task cancel propagates

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
| 1 | swift-subprocess is **0.4.x / pre-1.0**. Implementation switched to **Foundation `Process` with FileHandle.bytes.lines + AsyncTaskQueue** instead of swift-subprocess. The readabilityHandler footgun is avoided by using `bytes.lines` (no closure captures, no fire-after-EOF). Cancellation is wired via `withTaskCancellationHandler` + `runHandle.terminate()` which sends SIGTERM, with a 5 s grace + SIGKILL fallback for genuine timeouts. | Revisit before public ship if swift-subprocess hits 1.0 with a stable API. Foundation Process is well-trodden ground; the trade-off was worth it. | Resolved (deviation documented; commit `c20051e`) |
| 2 | `com.apple.security.cs.allow-jit` is included defensively. Empirical test in EPIC-04a's spike work hasn't run yet; the entitlement is cheap to keep. | Document; remove if Spike A surfaces no MAP_JIT failures. | Open (verify in 04a spike — non-blocking) |
| 3 | First launch on Sequoia+ shows a "downloaded from internet" Gatekeeper prompt for the inner binary unless the `.app` is launched once via Finder (LaunchServices then trusts the spawn). | Document in QA plan; mention in EPIC-07 onboarding flow. | Carry-forward to EPIC-07 |
| 4 | Reference template for the codesign sequence is Buzz (`chidiwilliams/buzz`) — closest OSS precedent for a PyInstaller-bundled torch app shipped notarized. The Run Script Build Phase mirrors the Buzz pattern bottom-up. Notarization dry-run deferred to a release-prep EPIC. | Notarize against the `.app` in a release-prep EPIC; expect a few iterations on entitlement edge cases. | Carry-forward to release-prep EPIC |
| 5 | Audio file passing: the EPIC-04a binary supports `--audio <PATH>` directly. The `TRANSCRIPT_SHADOW_AUDIO_BOOKMARK` env var contract surface exists but errors with a deferred-implementation message — bookmark resolution in pure Python isn't feasible. EPIC-04b's Swift parent must resolve the bookmark itself and pass `--audio` with a resolved path (sandbox inheritance allows the child to read it). | When the UI flow lands in EPIC-07, the parent will resolve via `URL(resolvingBookmarkData:options:.withSecurityScope...)` and call `--audio` with the resolved path. | Carry-forward to EPIC-07 |
| 6 | **Codex Gate 2 P0 (2026-05-09)**: Pre-existing `AsyncTaskQueue` race from EPIC-03 — separate locks for read of `tail` and write of `voidTail` allow two concurrent enqueues to share the same predecessor and run concurrently. Single critical section in the fix. | Single `lock.withLock { … }` covering predecessor capture + tail install. Verified by passing test suite (queue serialization test in `PyannoteSidecarDiarizationServiceTests`). | Resolved (commit `c20051e`) |
| 7 | **Codex Gate 2 P0 (2026-05-09)**: Run Script used bash `done < <(find ...)` process substitution; Xcode build phases run `/bin/sh`. Switched to `find … -print0 \| xargs -0`. | Use `xargs -0` for the bottom-up codesign loop. | Resolved (commit `c20051e`) |
| 8 | **Codex Gate 2 P1 (2026-05-09)**: Foundation `Process` + unstructured `Task.value` does NOT propagate cancellation. Awaiting `outcomeTask.value` waits for the task to complete; the inner work runs unaware that the caller cancelled. | `AsyncTaskQueue.enqueue` now wraps the await in `withTaskCancellationHandler { try await outcomeTask.value } onCancel: { outcomeTask.cancel() }`. | Resolved (commit `c20051e`) |
| 9 | **Codex Gate 2 P1 (2026-05-09)**: Cancellation is treated identically to a genuine timeout in `runOnce`. The 5 s grace sleep `try? await Task.sleep(...)` is itself a cancellation point — in a cancelled task it returns immediately, so SIGKILL fires almost on top of SIGTERM, defeating the documented grace period. | Check `Task.isCancelled` before the timeout fallback path; only do SIGTERM-grace-SIGKILL on a non-cancelled timeout. | Resolved (commit `c20051e`) |
| 10 | **Codex Gate 2 P1 (2026-05-09)**: `waitForExitForever` busy-spins in cancelled tasks because `Task.sleep` throws immediately and `try?` swallows it without throttle. | Wrap the polling loop in `Task.detached` so cancellation does NOT propagate from the parent task to the polling sleeps. | Resolved (commit `c20051e`) |
| 11 | **Codex Gate 2 P1 (2026-05-09)**: `process.environment = ProcessInfo.processInfo.environment` leaks every parent / test runner env var into the child. | Curated whitelist (PATH/HOME/TMPDIR/locale/HF_*/NUMBA_CACHE_DIR/TRANSCRIPT_SHADOW_AUDIO_BOOKMARK). | Resolved (commit `c20051e`) |
| 12 | **Codex Gate 2 P1 (2026-05-09)**: `parseProgress` accepted `inf`, `nan`, exponents, negatives, and whitespace-padded forms because `Double(...)` is permissive. | Hand-rolled ASCII walk that enforces the EPIC-04a contract regex `^PROGRESS:(\d+(?:\.\d+)?)$` exactly. New test `testParseProgressRejectsLooseDoubleFormats`. | Resolved (commit `c20051e`) |
| 13 | **Codex Gate 2 P2 (2026-05-09)**: Schema version was decoded but never enforced. A `version: "2.0"` envelope with the same shape would silently parse. | Added `DiarizationResult.supportedSchemaVersion = "1.0"` constant; `runOnce` validates and throws `.decodeFailed` on mismatch. | Resolved (commit `c20051e`) |
| 14 | **Codex Gate 2 P2 (2026-05-09)**: `testCancellationSurfacesCancelledNotBinaryFailed` could pass for the wrong reason — if the cancel-vs-timeout split was buggy and the test reached the `.timedOut` branch, the post-conversion `Task.isCancelled` check would still re-emit `.cancelled` and the test would pass. | Bumped service `timeoutSeconds=600` and asserted total elapsed `< 10 s`, so a slow .cancelled outcome via the timeout branch fails loudly. | Resolved (commit `c20051e`) |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-05-08 | Claude Agent | EPIC created via split from EPIC-04 to isolate the Swift bridge from the Python pipeline + packaging risk profile. |
| 2026-05-08 | Claude Agent | Phase A planning round: locked decisions on swift-subprocess pick, binary location, security-scoped bookmarks, HF token storage, AsyncTaskQueue concurrency. Phase B entitlements matrix + codesign sequence designed. Codex review of planning docs caught 3 internal inconsistencies (binary location syntax, Process→swift-subprocess phrasing) — all fixed. |
| 2026-05-09 | Claude Agent | Phase C — three context windows: CW1 Codable types + service protocol + FakeDiarizationService (commit `57b1e03`); CW2 + CW3 combined as one PR-ready commit (Foundation Process bridge + production entitlements + child entitlements + codesign Run Script Build Phase, commit `c20051e`). Implementation deviated from planning's swift-subprocess pick — used Foundation Process with FileHandle.bytes.lines instead, documented in observations. |
| 2026-05-09 | Claude Agent | Codex Gate 2 — single-ask review of EPIC-04b code surfaced 10 bugs (2 P0, 6 P1, 2 P2), including a pre-existing `AsyncTaskQueue` race from EPIC-03. All resolved before close. 74 XCTests + 30 pytest = 104 total green. |
| 2026-05-09 | Claude Agent | Phase E harvest — SoT updates (API-102 → Implemented full, INT-102 → Implemented full, TEST-201/204 → Implemented full, DEP-002 entitlements + codesign procedure), PRD (RISK-007 mitigated, EPIC-04b complete row, backlog flip), README (EPIC-05 active). EPIC closed. |
