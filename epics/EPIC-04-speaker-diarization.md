---
template_version: "3.0.0"
---

# EPIC-04 Speaker Diarization Sidecar — INDEX (Split)

> **State**: `Split` (no work happens directly in this file)
> **Lifecycle**: v0.7 Build Execution
> **Replaced by**: [EPIC-04a](EPIC-04a-diarization-cli.md) + [EPIC-04b](EPIC-04b-diarization-swift-bridge.md)
> **Date**: 2026-05-08

---

## Why this file is now an index

The original EPIC-04 bundled three different risk profiles into one
workstream — pyannote pipeline accuracy on Apple Silicon, PyInstaller
bundling, and Swift `Process` semantics under the app sandbox. After the
EPIC-01..03 closure, two signals pushed for a split:

1. The `UserPromptSubmit` context-density hook was firing **BROAD** on
   every prompt because EPIC-04 referenced 12 SoT items.
2. Codex's 2026-05-07 synthesis review explicitly recommended "start with
   a CLI/benchmark spike before the Swift bridge" and noted that the
   risk profiles are "categorically different and worth treating as
   separable milestones."

Splitting now (before any code) keeps each session's scope clean and
lets each EPIC complete on its own timeline.

---

## Where the work lives now

| EPIC | Scope | SoT footprint | Status | Blocks |
|------|-------|---------------|--------|--------|
| **[EPIC-04a — Diarization CLI & Packaging](EPIC-04a-diarization-cli.md)** | `diarize.py` real impl + JSON schema lock + PyInstaller bundle. Python-only. | 8 IDs (API-102 CLI half, ARC-002, TECH-006, BR-101, FEA-003, TEST-201..204, RISK-001/003) | Active | EPIC-04b |
| **[EPIC-04b — Swift `DiarizationService` Bridge](EPIC-04b-diarization-swift-bridge.md)** | Swift Process consumer + sandbox/entitlement work + `DiarizationResult` types + tests via golden JSON. | 7 IDs | Blocked on 04a's JSON contract being frozen | — |

Each child EPIC carries a "Cumulative Carry-Forward" pointer back here.
The full carry-forward block is below — read once at the start of either
child, then `<!-- HANDOFF -->` past it.

---

## Cumulative Carry-Forward from EPIC-01 → EPIC-03

> The patterns that have already cost us cycles in earlier EPICs. The
> two child EPICs both depend on these — read once before starting.

**Concurrency / Swift 6 strict mode** (EPIC-02, EPIC-02b, EPIC-03 all hit this):

- Non-Sendable Apple/3rd-party types (`AVAudioPCMBuffer`, `WhisperKit`, and very likely the bridge's `Process` wrappers) cannot cross actor boundaries via `await`. Use `@unchecked Sendable` envelope structs OR a `final class` + `NSLock` instead of `actor`. Document the choice inline.
- `NSLock.lock()/unlock()` is banned in `async` contexts; always use `lock.withLock { … }`.
- "Validate, then mutate after dropping the lock" is fundamentally racy. Single critical section or accept the bug.
- Async observer registration via `Task { await actor.register(...) }` has an entry-order race against subsequent actor calls. Use a synchronous lock-protected bus (see `MilestoneBus` / `LevelBus` / `LevelGate` in EPIC-02b for the pattern).
- A separate serial queue (`AsyncTaskQueue` from EPIC-03) is the right tool when an SDK call must not run twice concurrently on the same instance — applies to the Swift Process bridge too if multiple diarizations could ever overlap.

**Cancellation** (EPIC-03 Codex):

- Always pre-catch `is CancellationError` *before* the generic catch. Never collapse cancellation into "diarization failed" — `.cancelled` is a meaningful product state.
- Long-running SDK callbacks should consult `Task.isCancelled` and return early.
- For the Swift bridge: cancel = SIGTERM the subprocess; SIGKILL after 5s.

**SDK / module name collisions** (EPIC-03):

- WhisperKit's module shadows the class name — `WhisperKit.TranscriptionResult` parses as the class's nested type, not the module's top-level. Solution: rename **our** type (we now use `Transcript`). Watch for this on `pyannote`-bridge types if any of pyannote's CLI JSON keys collide with our `DiarizationResult` shape.

**SDK initializer parameters matter** (EPIC-03 Codex P1):

- `WhisperKit(modelFolder:)` vs `downloadBase:` looked equivalent and isn't. Always re-read the SDK docs for "is this where the file lives or where the file goes?". For `pyannote`, watch for `cache_dir` vs `model_dir`, `use_auth_token` vs `token`, etc.

**File lifecycle / artifact contract** (EPIC-02b):

- Unique filenames need ≥32 bits of entropy in any suffix; 4-char UUID hits birthday-paradox at hundreds of calls. Use 8 chars or full UUID.
- `AVAudioFile` only flushes on release — release the instance in `finish()`, not just a flag.
- Refuse to overwrite existing files at the writer; rely on the URL generator for uniqueness.
- For the JSON contract between 04a and 04b: freeze it, version it (`"version": "1.0"`), and refuse to break it without an explicit EPIC update.

**Test discipline**:

- Inject every external dependency (sources, clocks, engines) so tests run with no hardware, no network, no model weights.
- Per-pair markers > strict ordering when verifying serialization. Concurrent dispatch ordering is not guaranteed; non-interleave is.
- Synthetic fixture WAVs (`SyntheticPCMBuffer`, `FixtureWAV`) are how every audio-adjacent test should drive the unit under test. Real-engine integration tests are deferred until a CI tier exists for them.
- Golden-JSON fixtures from 04a are how 04b tests run without invoking real pyannote.

**Tooling friction**:

- macOS codesign rejects xattrs (`com.apple.provenance`) added by some editors. `xattr -rc TranscriptShadow/ TranscriptShadowTests/` clears them; do this before `xcodebuild` if a clean build fails on `CodeSign`.
- Duplicate `*.xcodeproj` (Finder/Spotlight artifacts) confuse `xcodebuild`'s auto-discovery. Delete the dupe; XcodeGen owns the canonical one.
- `package` access modifier requires `-package-name`; XcodeGen-generated projects don't set it. Use `internal` + `@testable import` instead.

**Codex review cadence (mandatory before EPIC close)**:

- Every EPIC since EPIC-02 has shipped with a Codex review pass that surfaced real bugs the initial implementation missed (4 in EPIC-02, 6 in EPIC-02b synthesis, 3 in EPIC-03). Plan one for each of 04a and 04b too.
- Single-ask discipline: pose Codex *one specific question* with a length cap, not "review the whole module."

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC-04 (single workstream covering Python + Swift sides) |
| 2026-05-08 | Claude Agent | Pre-execution review: added cumulative-carry-forward block from EPIC-01..03, locked Codex's path-forward (CLI/benchmark spike before Swift bridge) into Phase A, expanded deliverables and phase plans with the lessons paid for in earlier EPICs. |
| 2026-05-08 | Claude Agent | **Split** into EPIC-04a (Python CLI + bundle) and EPIC-04b (Swift Process bridge). This file converted to an index. Reason: the BROAD-scope hook firing on every prompt (12 SoT items) and Codex's recommendation that the two halves are "categorically different risk profiles." |
| 2026-05-09 | Claude Agent | **EPIC-04a closed**. Real pyannote 4.x sidecar shipped, JSON envelope frozen at schema 1.0, golden fixtures committed for cross-language contract testing, 30 pytest cases passing, Codex Gate 1 found + resolved 3 bugs. EPIC-04b is now Active and unblocked. |
