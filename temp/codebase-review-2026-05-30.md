# Codebase Review & Next Steps — 2026-05-30

> **Scope**: Full repo review at the v0.7 → v0.8 gate. Identifies bugs/risks
> (with `file:line`), confirms what the history already fixed, and lays out the
> next steps to advance the PRD lifecycle.
> **Reviewer**: Claude Agent (branch `claude/codebase-review-next-steps-92HST`)
> **State at review**: EPIC-01→08 closed, 183 XCTests green (per EPIC-08 close
> note), no open PRs, no open issues. Last merge `#11` (CI hygiene).

---

## 1. Executive Summary

The codebase is **mature and unusually well-reviewed**. Every EPIC since EPIC-02
ran a "Codex Gate" single-ask review that caught and fixed real bugs (env-var
leakage to the sidecar, busy-wait on cancellation, ISO8601 thread-safety,
main-actor cleanup deadlock, orphan-scan race, per-stage error mapping). The
service layer (audio → transcribe → diarize → format → store → export) is wired
behind `Sendable` protocols through `AppEnvironment`, and `DefaultPipelineOrchestrator`
correctly enforces single-point temp-WAV cleanup, cancellation pre-catch, and
monotonic progress.

There are **no P0/P1 correctness bugs** in the reviewed paths. The findings below
are one real data-flow gap (P2), pre-release scaffolding that should be removed
(P3), and a couple of minor observations. The dominant theme of "next steps" is
**not more code — it is the Mac-only validation gate** that EPIC-08 explicitly
deferred, plus standing up the v0.8 release EPIC.

> ⚠️ **Environment note**: this review ran in a Linux container with no Swift /
> Xcode toolchain, so the XCTest suite could not be re-run here. Build/test
> verification of any fix must happen on a Mac (the CI `macos-15` runner covers
> this on PR).

---

## 2. Findings

### F-1 (P2 — real gap): Auto-export failure is completely silent

**Where**: `TranscriptShadow/Pipeline/DefaultPipelineOrchestrator.swift:188-192`
(and the `try?` on `markExported` at `:186`).

```swift
} catch {
    // Non-fatal — the transcript is saved. Snap progress to 1 ...
    progress(PipelineProgress(stage: .export, stageFraction: 1, aggregateFraction: 1.0))
}
```

The export error is caught and **discarded with no log and no UI signal**.
`process()` returns the saved transcript's UUID exactly as it would on a
successful export, so `ProcessingViewModel` has no way to know the Obsidian
write failed.

This contradicts the EPIC-08 risk callout, which specifies:
> "Auto-export is best-effort. … Export error **surfaces in UI** but does not
> invalidate the save."

The existing test `DefaultPipelineOrchestratorTests.test_exportFailure_doesNotInvalidateSave`
asserts the save survives and `markExported` doesn't run — but asserts **nothing
about surfacing the failure**, so the gap passed the gate unnoticed.

**Impact**: a user with `autoExport == true` and (e.g.) a bad/moved vault path
gets a transcript saved to SQLite but **silently no Obsidian file**, with zero
indication anything went wrong. Low blast radius (data isn't lost), but it
violates the documented contract and is a bad day for the daily-driver use case.

**Recommended fix** (small, but touches the closed orchestrator contract, so
flagging rather than applying unilaterally): carry a non-fatal `exportWarning`
back to the caller — either as part of a richer success result, a dedicated
warning callback, or at minimum a logged message consistent with the rest of the
cleanup layer. Then surface it on SCR-003/SCR-004 as a dismissible banner. Add a
test asserting the warning is observable.

---

### F-2 (P3 — pre-release cleanup): Demo scaffolding still ships in the app

EPIC-08 is closed, but the demo navigation it was supposed to replace is still
present in the release-candidate build:

- `TranscriptShadow/TranscriptShadowApp.swift:51-84` — the `CommandMenu("Demo")`
  (Cmd+1..6) with the literal comment *"remove when EPIC-08 wires real state
  transitions."* EPIC-08 wired them; the menu remains.
- `TranscriptShadow/Screens/ProcessingViewModel.swift:12-15` — initial state is
  mock copy: `title = "Q3 Planning · Eng + Design"`, `elapsed = "47:12 captured"`,
  `stages = ProcessingView.mockStages`. These are overwritten once a real
  `audioURL` arrives, but a shipped build still flashes mock content in the
  `audioURL == nil` demo path.
- `TranscriptShadow/Screens/MainWindowViewModel.swift:47-50, 113-116` — the
  default `hud.onStop` routes to `.processing(audioURL: nil)`, i.e. the canned
  demo flow, and is restored after every real recording.

**Impact**: a notarized v0.8 build would expose a Demo menu that drives the UI
into mock states. Not a correctness bug, but it should be gated behind a
`#if DEBUG` (or removed) before release.

**Recommended fix**: wrap the Demo `CommandMenu` and the mock initial values in
`#if DEBUG`; default `ProcessingViewModel` to empty/neutral state in release.

---

### F-3 (P3 — observation): `estimatedRemaining` is dead, `elapsed` is static

**Where**: `ProcessingViewModel.swift:13-14, 54-56` — `estimatedRemaining` is
only ever set to `""` (so SCR-003 hides it, `ProcessingView.swift:68`), and
`elapsed` is set once to the static string `"Processing locally"`.

**Impact**: cosmetic. But KPI-001 (processing speed) is a headline metric and a
live ETA / elapsed timer would both help the user and make the KPI visible. Low
priority; worth a follow-up once KPI-001 baselines exist.

---

### F-4 (P3 — design tradeoff to confirm): orphan-scan in-flight window weakens crash recovery

**Where**: `TranscriptShadow/Pipeline/TempAudioCleanup.swift:81` —
`scanForOrphans()` skips any WAV modified within `inFlightWindow` (30s).

The window was added (Codex Gate 6 P2) to avoid racing a *fresh* capture. But
`scanForOrphans()` only runs at `applicationDidFinishLaunching`
(`TranscriptShadowApp.swift:98-105`), **before** the user can start a recording
(capture needs a click that comes later, and a fresh capture file would itself
be <30s old and thus protected regardless). So at launch the race it guards
against can't actually occur.

The cost of the window: if the app crashes mid-recording (RISK-006) and the user
relaunches **within 30 s**, the orphan WAV is *skipped* and survives until a
later launch >30 s after its mtime. Functionally self-healing (a future launch
deletes it), but it slightly undercuts the RISK-006 mitigation the file claims
to implement.

**Recommended action**: confirm the tradeoff is intentional. Either (a) keep
as-is and note it in ARC-003, or (b) gate capture-start on scan completion (the
synchronization the EPIC-08 risk callout originally specified) and drop the
window so crash orphans are always reaped at next launch.

---

### F-5 (no action — positive observations)

- **Cancellation discipline is excellent**: every stage in the orchestrator and
  both the diarization subprocess (`PyannoteSidecarDiarizationService.swift:135-157`)
  and transcription service (`DefaultTranscriptionService.swift:66-75`) pre-catch
  `CancellationError`/`Task.isCancelled` before generic error mapping — exactly
  the EPIC-03 lesson.
- **Subprocess handling is hardened**: curated env whitelist (no parent-env leak,
  `:205-236`), AsyncSequence stdout (no `readabilityHandler` footgun), SIGTERM →
  5s → SIGKILL via POSIX `kill(2)`, detached drain to avoid busy-wait, and
  schema-version enforcement on the JSON envelope (`:191-195`).
- **Privacy invariants (BR-101/102/103)** are structurally respected: single
  awaited cleanup point, no network in the core pipeline. *The actual TEST-504
  no-network probe is still unrun* — see Next Steps.
- **Single-window scene + singleton HUD** (Codex Gate 5a) prevents the duplicate
  NSPanel/NSStatusItem fan-out that would break BR-501.

---

## 3. Next Steps (the real path forward)

The v0.7 → v0.8 gate has **one substantive blocker**, and it is **Mac-only**:

### 3.1 — Run the deferred manual Mac walkthrough (blocks v0.8)
Per the EPIC-08 close note and README status line, these were explicitly
deferred and cannot be done in this container:
- **TEST-504** — no-network probe (Wi-Fi off / Little Snitch / `tcpdump`),
  asserting zero outbound connections post model-download. **BR-101 is
  non-negotiable** — a stray SDK telemetry call is a release blocker.
- **KPI-001** — processing speed for a 30-min meeting (<5 min target) baseline.
- **KPI-002** — diarization accuracy (>80% target) baseline.
- **RISK-008** — notch-HUD vs menu-bar fallback parity + fullscreen occlusion probe.
- Real-audio E2E (single- and multi-speaker), cancel-mid-stage → no orphan,
  force-quit-mid-recording → relaunch → orphan gone.

Log results into README KPI/Risk tables and the SoT TEST entries.

### 3.2 — Stand up the v0.8 Release EPIC (currently no file)
`README` lists "Active EPIC: v0.8 Release & Deployment planning" but there is no
`epics/EPIC-09-*.md`, and PRD §"v0.8 Release & Deployment" reads *"Not yet
started."* Create the EPIC to cover:
- Code signing + notarization of the app **and** the bundled `diarize` sidecar
  (bottom-up signing).
- PyInstaller release-bundle build (multi-GB; currently out of CI scope by
  design — `.github/workflows/build.yml` comment).
- First-launch model-download UX (WhisperKit INT-101 + pyannote INT-102) — the
  one sanctioned network exception; needs a real progress/consent surface.
- `DEP-XXX` deployment config, `MON-XXX` local KPI logging, `RUN-XXX` runbooks
  (these IDs are owned by SoT and not yet created).

### 3.3 — Pre-release polish (from findings above)
- **F-2**: gate/remove demo scaffolding before notarization.
- **F-1**: decide and implement auto-export error surfacing + test.
- **F-4**: confirm orphan-scan window tradeoff; reflect decision in ARC-003.
- **F-3**: (optional) live elapsed/ETA on SCR-003 to expose KPI-001.

### 3.4 — Housekeeping
- The `DefaultPipelineOrchestrator` calls `transcription.prepare(model:)` then
  `transcribe(...)`, which both run `loadIfNeeded` — harmless (short-circuits),
  but worth a one-line comment so a future reader doesn't "optimize" the prepare
  away and lose the explicit load-failure → `.transcriptionFailed` mapping.

---

## 4. Suggested sequencing

1. **Now (Mac)**: run §3.1 walkthrough → fill KPI/Risk/TEST tables. This is the
   gate; everything else is parallelizable.
2. **In parallel**: open EPIC-09 (§3.2) and knock out F-2 (cheap, DEBUG-gating)
   and the F-1 decision.
3. **Then**: advance README dashboard `v0.8 → 🔵 Active`, append PRD Lifecycle
   Change Log row, and proceed into release/notarization work.

> Nothing here changes shipped behavior except the recommended (not-yet-applied)
> fixes in §2; this document is a scratchpad artifact to be harvested into the
> EPIC-09 plan + SoT TEST/RISK/ARC updates per the Progressive Documentation
> Protocol.
</content>
</invoke>
