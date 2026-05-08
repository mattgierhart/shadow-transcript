---
template_version: "3.0.0"
---

# EPIC-04 Speaker Diarization Sidecar

> **State**: `Planned` (next active EPIC)
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-01 (scaffold), EPIC-02b (audio artifact contract), EPIC-03 (transcription handoff shape)

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-08 — EPIC ready to begin. EPIC-03 closed; the upstream `AudioCaptureService.stopCapture()` URL is stable, the `Transcript`/`TranscriptSegment` shape is locked, and `Models/` already lives in Application Support so the diarization model can use a parallel `Sidecar/` (or co-locate per ARC-002). Carry-forward checklist + Codex-flagged risk profile are documented below.
- **Stopping Point**: N/A — not yet started.
- **Next Steps**: Per Codex's 2026-05-07 path-forward recommendation, **start with a CLI/benchmark spike** (prove `pyannote.audio` accuracy + JSON shape + PyInstaller bundling on a known recording) **before** building the Swift `Process` bridge. The CLI/benchmark and the Swift bridge are different risk profiles and worth treating as separable milestones.
- **Context**: Highest-risk EPIC by far — pyannote CPU performance (RISK-001), PyInstaller bundle size (RISK-003), Hugging Face token + model-licence acceptance (latent), sandbox + Process-spawn semantics (latent — sandboxed app spawning a bundled binary needs `disable-library-validation` and embedding under `Contents/Resources/`).

---

## Cumulative Carry-Forward from EPIC-01 → EPIC-03

> **Read once at start, then `<!-- HANDOFF -->` past it.** These are the
> patterns that have already cost us cycles in earlier EPICs and that
> EPIC-04 will hit again unless explicitly checked.

**Concurrency / Swift 6 strict mode** (EPIC-02, EPIC-02b, EPIC-03 all hit this):
- Non-Sendable Apple/3rd-party types (e.g. `AVAudioPCMBuffer`, `WhisperKit`) cannot cross actor boundaries via `await`. Use `@unchecked Sendable` envelope structs OR a `final class` + `NSLock` instead of `actor`. Document the choice inline.
- `NSLock.lock()/unlock()` is banned in `async` contexts; always use `lock.withLock { … }`.
- "Validate, then mutate after dropping the lock" is fundamentally racy. Single critical section or accept the bug.
- Async observer registration via `Task { await actor.register(...) }` has an entry-order race against subsequent actor calls. Use a synchronous lock-protected bus (see `MilestoneBus` / `LevelBus` / `LevelGate` in EPIC-02b for the pattern).
- A separate serial queue (`AsyncTaskQueue` from EPIC-03) is the right tool when an SDK call must not run twice concurrently on the same instance.

**Cancellation** (EPIC-03 Codex):
- Always pre-catch `is CancellationError` *before* the generic catch. Never collapse cancellation into "transcription/diarization failed" — `.cancelled` is a meaningful product state.
- Long-running SDK callbacks should consult `Task.isCancelled` and return early.

**SDK / module name collisions** (EPIC-03):
- WhisperKit's module shadows the class name — `WhisperKit.TranscriptionResult` parses as the class's nested type, not the module's top-level. Solution: rename **our** type to avoid the collision (we now use `Transcript`). Watch for this on `pyannote`-bridge types if any of pyannote's CLI JSON keys collide with our `Transcript` shape.

**SDK initializer parameters matter** (EPIC-03 Codex P1):
- `WhisperKit(modelFolder:)` vs `downloadBase:` looked equivalent and isn't. Always re-read the SDK docs for "is this where the file lives or where the file goes?". For `pyannote`, watch for `cache_dir` vs `model_dir` etc.

**File lifecycle / artifact contract** (EPIC-02b):
- Unique filenames need ≥32 bits of entropy in any suffix; 4-char UUID hits birthday-paradox at hundreds of calls. Use 8 chars or full UUID.
- `AVAudioFile` only flushes on release — release the instance in `finish()`, not just a flag.
- Refuse to overwrite existing files at the writer; rely on the URL generator for uniqueness.
- Atomic test: `totalFrameCount` after `finish()` must equal `AVAudioFile(forReading:).length` on disk under concurrent writes.

**Test discipline**:
- Inject every external dependency (sources, clocks, engines) so tests run with no hardware, no network, no model weights.
- Per-pair markers > strict ordering when verifying serialization. Concurrent dispatch ordering is not guaranteed; non-interleave is.
- Synthetic fixture WAVs (`SyntheticPCMBuffer`, `FixtureWAV`) are how every audio-adjacent test should drive the unit under test. Real-engine integration tests are deferred until a CI tier exists for them.

**Tooling friction**:
- macOS codesign rejects xattrs (`com.apple.provenance`) added by some editors. `xattr -rc TranscriptShadow/ TranscriptShadowTests/` clears them; do this before `xcodebuild` if a clean build fails on `CodeSign`.
- Duplicate `*.xcodeproj` (Finder/Spotlight artifacts) confuse `xcodebuild`'s auto-discovery. Delete the dupe; XcodeGen owns the canonical one.
- `package` access modifier requires `-package-name`; XcodeGen-generated projects don't set it. Use `internal` + `@testable import` instead.

**Codex review cadence (mandatory before EPIC close)**:
- Every EPIC since EPIC-02 has shipped with a Codex review pass that surfaced real bugs the initial implementation missed (4 in EPIC-02, 6 in EPIC-02b synthesis, 3 in EPIC-03). Plan for one in EPIC-04 too.
- Single-ask discipline: pose Codex *one specific question* with a length cap, not "review the whole module."

<!-- HANDOFF -->

---

---

## Objective & Scope

> **Goal**: Build and package the pyannote-audio diarization sidecar as a standalone PyInstaller binary invokable from Swift.

- **Deliverables** (suggest splitting into EPIC-04a "CLI spike" + EPIC-04b "Swift bridge" if the Phase A risk-spike surprises us):
  - [ ] `sidecar/diarize.py` — full implementation with pyannote pipeline (API-102)
  - [ ] CLI interface: `--audio`, `--output`, `--num-speakers`, `--hf-token` flags (token may be required for community-1)
  - [ ] JSON output matching API-102 contract; **freeze the schema before the Swift bridge starts** — once consumed, breaking it is expensive
  - [ ] Progress reporting via stdout `PROGRESS:XX`
  - [ ] Error handling with exit code 1 + stderr
  - [ ] PyInstaller ARM64 binary builds and runs (target: < 500 MB compressed; benchmark before targeting any specific number)
  - [ ] Swift `DiarizationService` subprocess bridge that consumes the same WAV URL `AudioCaptureService.stopCapture()` returns (no second audio conversion path; see Codex 2026-05-07 path-forward)
  - [ ] Tests: TEST-201, TEST-202, TEST-203, TEST-204 — fakes for the Swift side (a `FakeDiarizationEngine` paralleling `FakeTranscriptionEngine`); golden-JSON fixtures for the CLI side
- **Out of Scope**: WeSpeaker alternative, real-time diarization, GPU/MPS acceleration, alignment of speaker turns to transcript words (that's EPIC-05).

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

### Phase A: Plan (Risk Spike First — Codex 2026-05-07)

- [ ] **Context Loaded**: Read API-102, ARC-002, TECH-006, RISK-001, RISK-003, the cumulative carry-forward block above, and the EPIC-02b/EPIC-03 agent-observation tables
- [ ] **Strategy**: Codex's recommendation, accepted: prove the CLI works *before* writing any Swift. The risk profile of the CLI/packaging spike (does pyannote actually run? does community-1 require a HF token? does PyInstaller bundle clean? what's the M-series RTF?) is categorically different from the bridge work (process spawn semantics under sandbox, JSON parsing, progress regex, timeout handling). Treat them as two milestones; the spike's results inform whether to tighten Phase C scope.
- [ ] **Spike deliverable**: a 1-page `temp/epic-04-spike-results.md` covering — (a) does `pyannote.audio` install on Python 3.11 with our pinned deps?, (b) does `speaker-diarization-community-1` need a HF token at first download?, (c) RTF on a known 5-minute 3-speaker recording on Apple Silicon, (d) PyInstaller bundle size, (e) golden JSON shape for the API-102 contract.

### Phase B: Design

- [ ] Lock the JSON contract (API-102) **before** writing the Swift consumer. Schema decisions: speaker IDs (string vs int), segment boundary precision, optional confidence, error envelope shape. Once `DiarizationService` parses it, breaking the contract is expensive.
- [ ] Decide where the bundled binary lives in the .app: `Contents/Resources/diarize` vs an XPC service. The simpler `Process`+bundle-Resources path needs entitlement adjustments tracked in observation #3 from EPIC-01 (sandbox + library validation).
- [ ] Decide HF token storage if required: env var injected by app at spawn time, or runtime download via separate one-shot. Avoid bundling weights into the .app (size + licence).

### Phase C: Build (The "Context Window")

**Context Window 1: Python Diarization CLI** *(separable — could become EPIC-04a)*

- [ ] Implement `diarize.py` with argparse CLI matching the SoT signature
- [ ] pyannote Pipeline initialization with community-1 model (HF token via `--hf-token` or env)
- [ ] Process audio → speaker segments JSON (frozen schema from Phase B)
- [ ] Progress reporting to stdout (`PROGRESS:0.42` or similar single-line format the Swift parser can grep)
- [ ] Error handling + exit codes (1 = audio unreadable, 2 = model load failed, 3 = HF auth required, 4 = OOM)
- [ ] **Test**: TEST-201 (valid JSON shape via golden fixture), TEST-202 (single-speaker recording → 1 speaker reported)

**Context Window 2: PyInstaller Packaging** *(separable — could close EPIC-04a)*

- [ ] Create `diarize.spec` for ARM64 macOS
- [ ] Bundle pyannote + torch + torchaudio dependencies (hidden imports may need extending — record any in EPIC observations)
- [ ] Test binary runs standalone (no Python required) on a fresh path
- [ ] Measure binary size (don't pre-target a number; record what we get and decide if it's acceptable)
- [ ] **Test**: TEST-203 (progress emitted at expected cadence), TEST-204 (each error exit code reachable from a fixture)

**Context Window 3: Swift Bridge** *(could become EPIC-04b)*

- [ ] `DiarizationService` protocol + `PyannoteSidecarDiarizationService` impl using `Process` to spawn the bundled binary
- [ ] Parse stdout for progress, stderr for errors; map exit codes to typed `DiarizationError` cases
- [ ] Parse JSON output into `DiarizationResult` struct
- [ ] Timeout + cancellation handling (pre-catch `CancellationError` per EPIC-03 lesson; kill the subprocess on cancel)
- [ ] Sandbox + entitlement adjustments: `com.apple.security.cs.disable-library-validation` for the bundled binary; verify `Process` spawn works under app-sandbox or document the workaround
- [ ] Inject the HF token (if required by the spike) via `Process.environment`
- [ ] **Tests**: `FakeDiarizationEngine` for the Swift side (mirroring EPIC-03's `FakeTranscriptionEngine`)

### Phase D: Validate

- [ ] All 4 TEST-XXX cases pass; total transcription + diarization test count documented
- [ ] Manual test: 10-minute, 3-speaker recording fed to the live Swift bridge → end-to-end pipeline produces sensible speaker turns
- [ ] Benchmark: processing time for 30-minute audio on Apple Silicon; record RTF in EPIC + RISK-001
- [ ] Binary size measured + decision recorded (not a pre-set target — see Phase B note)
- [ ] Code traceability: `// @implements API-102`, `// @implements ARC-002`
- [ ] **Codex review pass** before EPIC close (per the cadence established in EPIC-02b / EPIC-03). Single-ask scope: "Find bugs in DiarizationService + sidecar bridge that the EPIC-03 lessons should have prevented."

### Phase E: Finish (Harvest)

- [ ] Temp cleanup (especially `temp/epic-04-spike-results.md` → SoT or archive)
- [ ] Update API-102 status to "Implemented" in `SoT/SoT.API_CONTRACTS.md`; mirror the interface refinement pattern used for API-101
- [ ] Update `SoT/SoT.TESTING.md` for TEST-201..204
- [ ] Record benchmark results in RISK-001 mitigation notes
- [ ] Session audit (revisit the cumulative carry-forward block above — what's stale, what's new?)

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | | | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-08 | Claude Agent | Pre-execution review: added cumulative-carry-forward block from EPIC-01..03, locked Codex's path-forward (CLI/benchmark spike before Swift bridge) into Phase A, expanded deliverables and phase plans with the lessons paid for in earlier EPICs. |
