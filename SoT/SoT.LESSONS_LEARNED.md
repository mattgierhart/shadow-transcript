---
version: 1.0
purpose: Source of Truth for cross-session behavioral corrections and validated patterns.
id_prefix: LL-XXX
last_updated: 2026-06-09
authority: This is a SoT file - entries harvested from EPIC Agent Observations tables and Cumulative Carry-Forward blocks (EPIC-01..09)
---

# Lessons Learned (SoT File)

> **Purpose**: Cross-session behavioral corrections and validated patterns that should persist across EPICs.
> **ID Prefix**: LL-XXX
> **Status**: Active SoT file (adopted 2026-06-09, EPIC-10)
> **Harvest Source**: EPIC-01→09 Agent Observations tables, Cumulative Carry-Forward blocks, and Codex Gate findings — **copied, never moved**. The source blocks remain verbatim in the closed EPICs (EPICs are knowledge). New entries arrive via EPIC Phase E harvest.
> **Audience**: All agents, all sessions
> **Cross-References**: Referenced by EPICs, `.claude/rules/05-lifecycle-gates.md`, ARC-004

## Navigation by Category

**Process** (LL-001 to LL-099):

- [LL-001](#ll-001-codex-gate-mandatory-cross-model-review-before-epic-close) - Codex Gate: mandatory cross-model review before EPIC close
- [LL-002](#ll-002-cumulative-carry-forward-blocks-make-lessons-travel) - Cumulative Carry-Forward blocks make lessons travel
- [LL-003](#ll-003-split-broad-scope-epics-by-risk-profile) - Split BROAD-scope EPICs by risk profile
- [LL-004](#ll-004-freeze-and-version-cross-stage-contracts-test-them-with-golden-fixtures) - Freeze + version cross-stage contracts; test them with golden fixtures
- [LL-005](#ll-005-test-the-contract-not-the-shape) - Test the contract, not the shape

**Technical** (LL-101 to LL-199):

- [LL-101](#ll-101-swift-6-strict-concurrency--non-sendable-sdk-types) - Swift 6 strict concurrency × non-Sendable SDK types
- [LL-102](#ll-102-validate-then-mutate-needs-a-single-critical-section) - Validate-then-mutate needs a single critical section
- [LL-103](#ll-103-cancellation-is-a-product-state-not-a-failure) - Cancellation is a product state, not a failure
- [LL-104](#ll-104-sdk-initializer-parameters-are-load-bearing) - SDK initializer parameters are load-bearing
- [LL-105](#ll-105-on-module-name-collisions-rename-our-type) - On module/name collisions, rename OUR type
- [LL-106](#ll-106-file-artifact-lifecycle-rules) - File artifact lifecycle rules
- [LL-107](#ll-107-subprocess-hygiene-curated-env-whitelist--binsh-compatible-build-scripts) - Subprocess hygiene: curated env whitelist + /bin/sh-compatible build scripts
- [LL-108](#ll-108-enforce-schema-versions-at-decode-time) - Enforce schema versions at decode time

**Collaboration** (LL-201 to LL-299):

- [LL-201](#ll-201-synchronous-lock-protected-buses-for-observer-registration) - Synchronous lock-protected buses for observer registration
- [LL-202](#ll-202-single-persona-continuity-via-epic-session-state) - Single-persona continuity via EPIC Session State

**Estimation** (LL-301 to LL-399):

- [LL-301](#ll-301-plan-device-bound-validation-as-its-own-session) - Plan device-bound validation as its own session

---

## Process

### LL-001: Codex Gate — mandatory cross-model review before EPIC close

- **Rule**: Every EPIC runs a Codex (`/codex-review`) pass in Phase D before close. **Single-ask discipline**: pose Codex one specific, scoped question with an explicit length cap (e.g. "Find bugs in `TranscriptFormatter` that EPIC-03/04 lessons should have prevented — P0/P1/P2, file:line, no fixes"), never "review the whole module." Pre-flight via `/codex-budget-check`. Resolve P0/P1 findings before the EPIC closes; document deferred P2s in the EPIC.
- **Why**: Every gated EPIC since EPIC-02 shipped with a Codex pass that surfaced real bugs the initial implementation missed: EPIC-02 (4), EPIC-02b synthesis (6), EPIC-03 (3), EPIC-04a (3, incl. a P0 dependency-pin failure), EPIC-04b (10 — 2 P0, 6 P1, 2 P2, including a pre-existing `AsyncTaskQueue` race latent since EPIC-03), EPIC-07 Gate 5b (2 P1 + 4 P2), EPIC-08 Gate 6 (4, incl. a P1 main-actor termination deadlock). Different model, different blind spots.
- **How to apply**: EPIC Phase D checklist item (canonized in commit `b2608cc`, 2026-05-09; carried in EPIC_TEMPLATE 3.3.0). Sketch the single-ask prompt at the bottom of the EPIC file during planning.
- **Source**: EPIC-02..08 Agent Observations; EPIC-05/07/08 carry-forward blocks; commit `b2608cc`
- **Verified**: 2026-06-09
- **Related IDs**: ARC-004, LL-002

### LL-002: Cumulative Carry-Forward blocks make lessons travel

- **Rule**: Each new EPIC opens with a "Cumulative Carry-Forward" block above the Objective summarizing the load-bearing lessons from all prior EPICs (or a pointer to the canonical block, as EPIC-04a/04b point at the EPIC-04 index). The next agent reads it once before touching code, then `<!-- HANDOFF -->` past it.
- **Why**: Patterns that cost cycles in EPIC-01..03 (Sendable boundaries, lock discipline, cancellation) would have been re-paid in EPIC-04+ without a forward-traveling digest. The blocks demonstrably prevented repeat bugs from EPIC-05 on.
- **How to apply**: When opening an EPIC, copy the prior block and append new lessons; mark sections that don't apply ("skip past"). Never delete the blocks from closed EPICs — they are knowledge, and this file harvests from them (copy, never move).
- **Source**: Commit `b2608cc`; EPIC-04/05/07/08 carry-forward blocks
- **Verified**: 2026-06-09
- **Related IDs**: LL-001, LL-202

### LL-003: Split BROAD-scope EPICs by risk profile

- **Rule**: When an EPIC's scope trips the BROAD-scope hook (≈12+ SoT items) or contains categorically different risk profiles, split it into child EPICs with an index-pointer parent (precedent: EPIC-04 → 04a Python CLI + 04b Swift bridge).
- **Why**: EPIC-04's two halves (ML sidecar packaging vs Swift process bridging) had different failure modes, test strategies, and review prompts. The split produced two clean Codex Gates (3 and 10 findings) instead of one diluted review.
- **How to apply**: At Phase A, if the hook fires or the deliverables span two risk domains, create `EPIC-XXa`/`EPIC-XXb` and turn `EPIC-XX` into the index carrying the shared carry-forward block.
- **Source**: PRD Lifecycle Change Log 2026-05-08; EPIC-04 index file
- **Verified**: 2026-06-09
- **Related IDs**: LL-001, LL-002

### LL-004: Freeze and version cross-stage contracts; test them with golden fixtures

- **Rule**: Any contract crossing a language or stage boundary (e.g. the sidecar JSON envelope between 04a Python and 04b Swift) gets frozen, versioned (`"version": "1.0"`), and may not change without an explicit EPIC update. Commit golden fixtures (e.g. `sidecar/test_fixtures/golden-3spk.json`) so each side tests against the contract without invoking the other side's runtime.
- **Why**: Golden fixtures let 74 XCTests run without pyannote in scope and 30 pytest cases run without Swift; the frozen envelope caught drift at decode time instead of in integration.
- **How to apply**: New pipeline stage or subprocess boundary → freeze the schema in SoT (API-), version it, commit fixtures for both sides, and add a decode-time version check (LL-108).
- **Source**: EPIC-04a/04b Agent Observations; EPIC-05 carry-forward
- **Verified**: 2026-06-09
- **Related IDs**: API-102, LL-108, TEST-201

### LL-005: Test the contract, not the shape

- **Rule**: A test that only checks `hasattr`/`callable` (or that an enum case exists) is vacuous. Assert observable behavior at the contract boundary — actual bytes emitted, actual error case surfaced, actual elapsed-time bound — and design tests so they fail loudly when the wrong branch produces the right value.
- **Why**: Codex Gate 1 flagged a progress test that verified only that a callback was callable; the replacement monkeypatch test asserted the real `PROGRESS:0.00`/`PROGRESS:1.00` byte stream. Codex Gate 2 flagged a cancellation test that could pass via the buggy timeout branch; bumping the timeout to 600 s and asserting elapsed < 10 s made the wrong path fail.
- **How to apply**: For every TEST- entry, ask "what wrong implementation would still pass this?" Inject dependencies so the assertion can reach real output (per-pair markers over strict ordering for concurrency).
- **Source**: EPIC-04a obs #8; EPIC-04b obs #14; carry-forward "Test discipline" sections
- **Verified**: 2026-06-09
- **Related IDs**: TEST-301..303, LL-004

---

## Technical

### LL-101: Swift 6 strict concurrency × non-Sendable SDK types

- **Rule**: Non-Sendable Apple/3rd-party types (`AVAudioPCMBuffer`, `WhisperKit`, Foundation `Process`, GRDB internals) cannot cross actor boundaries via `await`. Use a `final class` + `NSLock.withLock { … }` (or an `@unchecked Sendable` envelope struct) instead of an `actor`, and document the choice inline. `NSLock.lock()/unlock()` is banned in async contexts — always `withLock`.
- **Why**: An `actor` engine produced "sending 'whisperKit' risks causing data races" on every call (EPIC-03); the class+lock pattern keeps the same serialization invariants without actor-isolation analysis flagging the SDK. The pattern now anchors `WhisperKitEngine` and `PyannoteSidecarDiarizationService`.
- **How to apply**: Default to class+lock whenever wrapping a non-Sendable SDK. Use `AsyncTaskQueue` when an SDK call must never run twice concurrently on one instance. Beware actor reentrancy at the first `await` (EPIC-02's `isStarting` flag fix).
- **Source**: EPIC-02 obs #1/#2/#6b; EPIC-03 obs #2; carry-forward "Concurrency" sections
- **Verified**: 2026-06-09
- **Related IDs**: API-001, API-101, API-102

### LL-102: Validate-then-mutate needs a single critical section

- **Rule**: "Validate under lock, release, then mutate" is fundamentally racy. Any check-then-act pair on shared state runs in ONE critical section unless the validation result is provably stable.
- **Why**: `AudioFileWriter.write` validated then released the lock before writing — `finish()` slipped into the gap (EPIC-02b). The same bug class recurred at larger scale in `AsyncTaskQueue`: separate locks for reading `tail` and writing `voidTail` let two enqueues share a predecessor and run concurrently (EPIC-04b Codex Gate 2 P0, latent since EPIC-03).
- **How to apply**: Code-review heuristic on every lock: find the check and the act; if they're in different `withLock` blocks, merge them or justify in a comment.
- **Source**: EPIC-02b obs #1; EPIC-04b obs #6
- **Verified**: 2026-06-09
- **Related IDs**: LL-101

### LL-103: Cancellation is a product state, not a failure

- **Rule**: Pre-catch `is CancellationError` *before* any generic catch — never collapse cancellation into "stage failed". Long-running callbacks consult `Task.isCancelled`. Awaiting an unstructured `Task.value` does NOT propagate cancellation — wrap in `withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }`. For subprocesses: SIGTERM, grace period, then SIGKILL — and check `Task.isCancelled` before timeout fallbacks, because `Task.sleep` is itself a cancellation point that returns immediately in a cancelled task.
- **Why**: EPIC-03 Codex found `.cancelled` collapsed into `.transcriptionFailed`; EPIC-04b Codex Gate 2 found three distinct cancellation bugs (no propagation through `AsyncTaskQueue`, grace period defeated by cancelled sleep, busy-spin in `waitForExitForever`); EPIC-08 Codex Gate 6 found diarize-stage cancels surfacing as `.transcriptionFailed` again at the orchestrator.
- **How to apply**: Every new async surface gets a `.cancelled` path and a regression test (`test_engineCancellationError_isSurfacedAs_cancelled` pattern). This bug class recurred in 3 EPICs — check it explicitly in every Codex Gate prompt.
- **Source**: EPIC-03 obs #6c; EPIC-04b obs #8/#9/#10; EPIC-08 close notes (Gate 6 P2.1)
- **Verified**: 2026-06-09
- **Related IDs**: API-101, API-102, API-301

### LL-104: SDK initializer parameters are load-bearing

- **Rule**: For any SDK path/location parameter, re-read the docs for "is this where the file LIVES or where the file GOES?" — `WhisperKit(modelFolder:)` vs `downloadBase:` look equivalent and are not. Same trap family: `cache_dir` vs `model_dir`, `use_auth_token` vs `token`.
- **Why**: Passing the cache root as `modelFolder:` made WhisperKit treat it as an already-downloaded model and skip the download path entirely on fresh installs (EPIC-03 Codex P1) — a first-launch-only failure invisible on dev machines.
- **How to apply**: When wiring an SDK init, write a one-line comment stating the parameter's semantic; add a fresh-install test path when feasible.
- **Source**: EPIC-03 obs #6a; EPIC-04 carry-forward "SDK initializer parameters matter"
- **Verified**: 2026-06-09
- **Related IDs**: TECH-002, TECH-006

### LL-105: On module/name collisions, rename OUR type

- **Rule**: When a third-party module shadows a type name (WhisperKit's module + class share a name and export a top-level `TranscriptionResult`), rename **our** type rather than fighting qualification. Precedent: our result type is `Transcript`.
- **Why**: `WhisperKit.TranscriptionResult` parsed as a nested type of the class, not the module's top-level type, and failed to compile (EPIC-03). Renaming ours removed the ambiguity permanently.
- **How to apply**: On any "ambiguous type" / wrong-type-resolved error involving an SDK, check module-vs-class shadowing first; rename the local type and record it in the SoT API entry.
- **Source**: EPIC-03 obs #1; EPIC-04/05 carry-forward "SDK / module name collisions"
- **Verified**: 2026-06-09
- **Related IDs**: API-101, API-201

### LL-106: File artifact lifecycle rules

- **Rule**: (a) Unique filenames need ≥32 bits of suffix entropy — a 4-char UUID hits birthday-paradox collisions at hundreds of same-millisecond calls; use 8 chars or a full UUID. (b) `AVAudioFile` only flushes its header on release — `finish()` must nil the instance, not set a flag. (c) The writer refuses to overwrite existing files; uniqueness is the URL generator's job. (d) Format equality for buffers is structural (`isEquivalent`), not `==`.
- **Why**: All four shipped as real bugs in EPIC-02/02b/03 (truncated WAVs readable as zero-length, silent overwrites, collision flakes in the uniqueness regression test).
- **How to apply**: Any new file-emitting surface inherits these four checks; the EPIC-02b regression tests are the template.
- **Source**: EPIC-02 obs #3/#4/#7c; EPIC-02b fixes; EPIC-03 obs #4
- **Verified**: 2026-06-09
- **Related IDs**: API-002, BR-102, ARC-003

### LL-107: Subprocess hygiene — curated env whitelist + /bin/sh-compatible build scripts

- **Rule**: (a) Never pass `ProcessInfo.processInfo.environment` to a child process — it leaks every parent/test-runner var. Curate a whitelist (PATH/HOME/TMPDIR/locale/HF_*/task-specific vars). (b) Xcode Run Script build phases execute under `/bin/sh` — bashisms like `done < <(find …)` fail; use `find … -print0 | xargs -0`. (c) Security-scoped bookmark resolution is Foundation-only — the Swift parent resolves and passes plain paths to Python children.
- **Why**: EPIC-04b Codex Gate 2 caught the env leak (P1) and the process-substitution failure (P0, broke the codesign loop). The bookmark constraint shaped the whole 04a/04b transport contract.
- **How to apply**: Every `Process` launch site declares its whitelist inline; every Run Script is tested with `sh -n` mentally before commit; Buzz (`chidiwilliams/buzz`) is the codesign-sequence reference for PyInstaller-bundled children.
- **Source**: EPIC-04b obs #7/#11; EPIC-04a obs #9
- **Verified**: 2026-06-09
- **Related IDs**: ARC-002, DEP-002, SEC-001

### LL-108: Enforce schema versions at decode time

- **Rule**: A decoded-but-unchecked schema version is theater. Pin a `supportedSchemaVersion` constant and throw on mismatch. Likewise, parse wire formats with exact grammars — `Double("inf")` succeeds, so a permissive `Double(...)` accepted `inf`/`nan`/exponents where the contract regex was `^PROGRESS:(\d+(?:\.\d+)?)$`; hand-roll the walk when the contract is exact.
- **Why**: EPIC-04b Codex Gate 2 (P2 + P1): a `version: "2.0"` envelope with the same shape would have silently parsed, and loose float parsing accepted forms the Python side could never legally emit.
- **How to apply**: Every versioned contract (LL-004) gets a decode-time version assertion and a `testParseRejectsLooseFormats`-style negative test.
- **Source**: EPIC-04b obs #12/#13
- **Verified**: 2026-06-09
- **Related IDs**: API-102, LL-004

---

## Collaboration

### LL-201: Synchronous lock-protected buses for observer registration

- **Rule**: Registering stream observers via `Task { await actor.register(continuation) }` inside an `AsyncStream` builder has an entry-order race — registration can lose to actor calls issued immediately after. When subscribers register right before triggering work, use a synchronous lock-protected broadcast bus (`MilestoneBus`/`LevelBus` pattern). One shared `AsyncStream` is not broadcast; each subscriber needs its own continuation, finished per-session on stop.
- **Why**: EPIC-02's `audioLevels()` stream never terminated on stop and `milestones()` silently dropped early events; the bus pattern fixed both and is now the contract-safe default for stream surfaces.
- **How to apply**: Any new `AsyncStream` surface with multiple or registration-racing subscribers uses the bus pattern; assert stream termination in tests (`test_audioLevels_streamFinishes_whenCaptureStops`).
- **Source**: EPIC-02 obs #6c; EPIC-02b obs #2
- **Verified**: 2026-06-09
- **Related IDs**: API-001, LL-101

### LL-202: Single-persona continuity via EPIC Session State

- **Rule**: This repo runs single-persona ("Claude Agent") — session continuity lives in the active EPIC's Session State plus the Cumulative Carry-Forward blocks, not in per-agent MEMORY.md files. The four agent memory dirs (horizon/studio/devlab/metro) are retained as empty harvest targets.
- **Why**: 79 commits and 13 EPIC files were authored by a single persona with zero squad-memory use, and handoffs demonstrably worked (including Linux→Mac device handoffs in EPIC-07/08). Recording the observed practice keeps the next agent from "fixing" it by seeding squad memories nobody reads. **Status note**: this records de facto practice (assessment question U-1/Q1); maintainer ratification pending — if Matt opts into squad mode, seed `devlab/MEMORY.md` from EPIC-01..09 observations and deprecate this entry.
- **How to apply**: Keep updating EPIC Session State + carry-forward at every session end (rule 01). Do not split authorship across personas without a recorded decision.
- **Source**: Assessment U-1 (2026-06-09); EPIC-01..09 authorship record
- **Verified**: 2026-06-09
- **Related IDs**: ARC-004, LL-002

---

## Estimation

### LL-301: Plan device-bound validation as its own session

- **Rule**: Work that requires the physical Mac (Xcode builds, permission prompts, Gatekeeper first-launch, fullscreen/notch probes, KPI baselines) cannot be absorbed into a Linux/CI session — plan it as an explicit "Mac-handoff" phase with a prepared checklist, and keep heavy artifacts (multi-GB PyInstaller bundles) out of CI.
- **Why**: EPIC-05/06 closed with "build verification deferred to CI (`macos-15`)" because the dev environment was Linux; EPIC-07/08 shipped via prepared Mac-handoff blocks; EPIC-09's remaining gate items (TEST-504 no-network probe, KPI-001/002 baselines, RISK-008 fullscreen probe) are all device-bound. Estimating these as ordinary follow-on tasks stalls EPICs at 90%.
- **How to apply**: At Phase A, tag every device-bound deliverable; group them into a handoff checklist (the EPIC-08 14-step walkthrough is the template); sequence the Codex Gate post-CI-green when local build verification isn't possible.
- **Source**: EPIC-05/06 session states; EPIC-07/08 Mac-handoff prep rows; EPIC-09 gate items
- **Verified**: 2026-06-09
- **Related IDs**: TEST-504, KPI-001, KPI-002, RISK-008, DEP-002

---

## Deprecated Entries

> Entries that are no longer applicable. Keep for historical context.

_(None yet)_

---

## Cross-Reference Index

| LL ID | Related IDs | Category |
|-------|-------------|----------|
| LL-001 | ARC-004, LL-002 | Process |
| LL-002 | LL-001, LL-202 | Process |
| LL-003 | LL-001, LL-002 | Process |
| LL-004 | API-102, LL-108, TEST-201 | Process |
| LL-005 | TEST-301, LL-004 | Process |
| LL-101 | API-001, API-101, API-102 | Technical |
| LL-102 | LL-101 | Technical |
| LL-103 | API-101, API-102, API-301 | Technical |
| LL-104 | TECH-002, TECH-006 | Technical |
| LL-105 | API-101, API-201 | Technical |
| LL-106 | API-002, BR-102, ARC-003 | Technical |
| LL-107 | ARC-002, DEP-002, SEC-001 | Technical |
| LL-108 | API-102, LL-004 | Technical |
| LL-201 | API-001, LL-101 | Collaboration |
| LL-202 | ARC-004, LL-002 | Collaboration |
| LL-301 | TEST-504, KPI-001, RISK-008 | Estimation |

---

## Update Protocol

1. **When**: During EPIC Phase E harvest, promote Agent Observations / carry-forward items with cross-EPIC relevance (or 3+ occurrences) to LL- entries.
2. **Format**: Rule → Why → How to apply → Source → Verified date → Related IDs. Cite the source EPIC + observation row — provenance matters.
3. **Copy, never move**: source blocks stay verbatim in their EPICs. This file is the durable index, not a replacement.
4. **Review**: Entries older than 90 days without re-verification should be flagged as `⚠️ STALE`.
