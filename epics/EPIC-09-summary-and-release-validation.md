---
template_version: "3.0.0"
---

# EPIC-09 On-Device Summary + Mac Release Validation

> **State**: `In Progress` (opened 2026-06-04)
> **Lifecycle**: v0.7 → v0.8 gate (See `README.md`)
> **Epic Lead**: Claude Agent
> **Depends On**: EPIC-05 (formatter output), EPIC-06 (store + export), EPIC-07 (UI), EPIC-08 (orchestrator)
> **Environment Requirement**: macOS 15+ with Xcode 16+ for build/test. The
> **on-device LLM path** (Apple Foundation Models) additionally requires
> **macOS 26 + Xcode 26 + Apple Intelligence**; on anything older the build
> compiles and runs against the deterministic `ExtractiveSummarizer` fallback.

---

## Session State (The "Brain Dump")

- **Strategic note (2026-07-07, cloud session)**: Evaluated forking/replicating
  [Meetily](https://github.com/Zackriya-Solutions/meetily) as an alternative
  base. **Conclusion: stay the course** — Meetily's MIT Community Edition lacks
  our three defining P0 features (FEA-003 diarization is Pro-only/proprietary,
  FEA-004 speaker-labeled markdown, FEA-005 Obsidian export), while this repo
  already ships all of them with 213 tests green. Full analysis + harvest list
  + decision options: `temp/meetily-evaluation-2026-07-07.md`. No change to
  Phase D next steps below; decision on Option A vs B rests with the user.
- **Last Action**: 2026-06-04 (Mac build + validation session):
  - **Build + full suite green on the Mac** (macOS 26.5 / Xcode 26.4.1, macOS
    26.4 SDK). The app compiles *including* `FoundationModelsSummarizer` — its
    first compile on a real Xcode 26 SDK (the prior cloud session wrote it
    blind; it was API-correct). **213 tests pass.**
  - **Root-caused + fixed the `macos-15` CI red** (PR #12). It was **not** a
    compile error: `SummarizationTests`' `sampleTranscript` built `speakerMap`
    with `Dictionary(uniqueKeysWithValues:)`, which traps on its repeated
    speakers — crashing exactly the 6 tests CI reported. Fixed with
    `Dictionary(_:uniquingKeysWith:)` (commit `1943027`).
  - **Foundation Models runs for real here**: Apple Intelligence is active, so
    `DefaultSummarizationService` selects the on-device LLM (footer "Apple
    Foundation Models"), not the extractive fallback. The live path passes in
    ~2.9 s, no hang.
  - **Hardened golden-fixture tests** to read from the test bundle (commit
    `53f06a0`). The repo sits in **iCloud-synced `~/Documents`**; the app
    binary's `open()` of source-tree fixtures stalls in-kernel via CloudDocs
    FileProvider, which hung the Diarization tests and froze `xcodebuild test`.
    Bundling fixtures into the `.xctest` (read via `Bundle(for:)`) makes them
    local + instant. Not a code bug; doesn't affect CI.
  - **F-2** (commit `c2a5217`): `#if DEBUG`-gated all demo scaffolding (Demo
    menu, `.demo*` handlers/names, mock VM state, demo `onStop`). Release
    compiles clean (0 Swift errors).
  - **F-1** (commit `1f9d97c`): auto-export failures are no longer swallowed —
    `process()` returns `PipelineResult { id, exportWarning }`; the orchestrator
    logs the failure and the UI shows a dismissible banner. SoT API-202 updated.
- **Stopping Point**: 4 code commits + SoT/EPIC docs on
  `claude/codebase-review-next-steps-92HST`. A **new PR → `main`** lands the fix
  (PR #12 already merged with the failing test, so `main`'s CI is red).
- **Next Steps** — the remaining Phase D gate is **device-bound + needs the
  user**, and is blocked only by the iCloud file-mediation environment, not by
  code:
  1. **Resolve iCloud `~/Documents` for the real app.** If the Obsidian vault
     path is also under iCloud sync, real-app export I/O may stall like the
     tests did. Cleanest: move the repo/workspace to a non-synced path
     (e.g. `~/Developer`). See memory `env-icloud-documents-fileprovider`.
  2. **Real-audio E2E**: record a ~30 s, 2–3 speaker clip; run the pipeline;
     confirm the summary lands in the Obsidian note + Copy + Save As, footer
     "Apple Foundation Models".
  3. **TEST-504** no-network probe (Wi-Fi off / Little Snitch / `tcpdump`):
     zero outbound during a run, post model-download. BR-101/BR-104 blocker.
  4. **KPI-001** (≤5 min / 30-min) + **KPI-002** (>80% diarization) baselines
     → README, measured with summary on and off.
  5. **RISK-008** notch-HUD vs menu-bar fallback + fullscreen occlusion probe.
  6. Cancel mid-stage → no orphan WAV; force-quit mid-recording → relaunch →
     orphan gone.
  7. (Stretch, still open) surface the summary in the SCR-004 view + preserve
     it on manual re-export (Known Limitations #1/#2).
- **Context**: macOS 26 + Apple Intelligence → the real on-device LLM (BR-104).
  The automated suite is fully green locally; what remains is the manual,
  device-bound walkthrough.

---

## Objective & Scope

> **Goal**: Make the pipeline produce a useful **meeting summary** on-device
> and close the remaining v0.7 → v0.8 validation gate so the app is a usable
> daily driver.

### Deliverables

- [x] **API-401 `SummarizationService`** — protocol + typed `SummarizationError`.
- [x] **`ExtractiveSummarizer`** — deterministic, dependency-free fallback
  (overview + key points + action-item cue detection). Always available on
  macOS 15.
- [x] **`FoundationModelsSummarizer`** — Apple on-device LLM (macOS 26+),
  isolated behind `#if canImport(FoundationModels)` so the macOS-15 SDK build
  is unaffected (TECH-008).
- [x] **`DefaultSummarizationService`** — prefers the LLM, falls back to
  extractive on any unavailability/failure. On-device end to end (BR-104).
- [x] **Orchestrator wiring** — non-fatal summarize stage between format and
  save; summary embedded into markdown (reaches SQLite + Obsidian, no schema
  change). Gated by `summarize_on_complete` (default true).
- [x] **Tests** — TEST-601 (extractive oracle) + TEST-602 (orchestrator embed
  / disable / non-fatal failure) + renderer + service-selection.
- [ ] **Mac validation gate** (carried from EPIC-08): TEST-504 no-network
  probe, KPI-001 + KPI-002 baselines, RISK-008 fullscreen HUD probe,
  real-audio E2E (single + multi-speaker), cancel/force-quit orphan checks.
- [ ] **Summary UX** (stretch): show the summary in SCR-004 and preserve it on
  manual re-export.

### Out of Scope

- Cloud LLMs / any network summarization (explicitly rejected — BR-104).
- A new DB column for the summary (deferred; markdown-embed avoids a migration).
- Notarization / signing / release packaging — that's the broader v0.8 release
  work, tracked separately (see § Follow-on).

---

## Context & IDs

- **Features**: FEA-007 (On-Device Meeting Summary) — new.
- **APIs**: API-401 (SummarizationService) — new. Consumes API-201
  (`FormattedTranscript`); embeds via API-202 (export) + DBT-001 (markdown).
- **Business Rules**: BR-104 (on-device summarization) — new; refines BR-101.
- **Technical**: TECH-008 (on-device LLM = Apple Foundation Models w/
  extractive fallback) — new.
- **Tests**: TEST-601, TEST-602 — new; plus the carried TEST-504 / KPI-001 /
  KPI-002 / RISK-008.
- **Architecture**: ARC-001 (sequential pipeline — summary is a new in-line
  stage), ARC-003 (unchanged).

---

## Execution Plan (The 5 Phases)

### Phase A: Plan ✅

- [x] Decided on-device-only (BR-104). LLM = Apple Foundation Models with a
  deterministic extractive fallback so the feature works on every macOS 15+
  machine and lights up the LLM on macOS 26.
- [x] Decided **markdown-embed** over a DB column to avoid a migration and ship
  today; the summary flows to SQLite + Obsidian via the existing markdown path.

### Phase B: Design ✅

- [x] `SummarizationService.summarize(transcript:) -> MeetingSummary`.
- [x] `MeetingSummary { overview, keyPoints, actionItems, generator }`.
- [x] Non-fatal contract: orchestrator swallows summarizer errors (mirrors
  auto-export). Quality feature, not a gate.
- [x] Engine selection resolved at runtime (`DefaultSummarizationService`).

### Phase C: Build ✅ (this session)

**Context Window 1: Summarization module**
- [x] `Summarization/MeetingSummary.swift`, `SummarizationService.swift`
  (+ `SummaryMarkdownRenderer` + `FormattedTranscript.replacingMarkdown`),
  `ExtractiveSummarizer.swift`, `FoundationModelsSummarizer.swift`,
  `DefaultSummarizationService.swift`.
- [x] `Previews/PreviewSummarizationService.swift` + `MeetingSummary.preview`.

**Context Window 2: Pipeline + settings wiring**
- [x] `summarize_on_complete` setting (default true).
- [x] `DefaultPipelineOrchestrator` summarize stage + `AppEnvironment` wiring.
- [x] `TranscriptShadowTests/Summarization/SummarizationTests.swift`.

### Phase D: Validate (Mac — in progress)

- [x] **Build + full suite green on the Mac** (macOS 26.5 / Xcode 26.4.1) —
  213 tests, incl. the `FoundationModels` compile and the live LLM path. The
  `macos-15` CI red (PR #12) was a test-fixture crash, now fixed; CI confirms
  on the new PR.
- [ ] Real recording on the Mac → summary present in Obsidian note + copied md.
- [ ] If macOS 26: confirm Foundation Models engine activates.
- [ ] **TEST-504** no-network probe (BR-101/BR-104 — release blocker if violated).
- [ ] **KPI-001** (≤5 min / 30-min meeting) + **KPI-002** (>80% diarization)
  baselines logged to README. Note: summarization adds to processing time —
  measure with it on and off.
- [ ] **RISK-008** notch HUD vs menu-bar fallback + fullscreen probe.
- [ ] Cancel mid-stage → no orphan; force-quit mid-recording → relaunch → gone.

### Phase E: Finish (Harvest)

- [ ] Confirm SoT entries (API-401, TECH-008, BR-104, FEA-007, TEST-601/602)
  match shipped code.
- [ ] Record measured KPI baselines + RISK-008 outcome in README.
- [ ] Append PRD Lifecycle Change Log row; advance README dashboard to
  v0.8 Active once the Mac gate passes.

---

## Known Limitations / Follow-ups

| # | Limitation | Follow-up |
|---|------------|-----------|
| 1 | Summary shows in the exported Obsidian note, the **Copy**, and **Save As** (all read `stored.markdown`), but **not** in the SCR-004 turn-list view, which projects from `segments`. | Add a summary header to `TranscriptDisplayModel` / SCR-004. |
| 2 | Manual **re-export** from SCR-004 (`makeFormattedTranscript(from:)`) re-emits the body from `turns` and drops the embedded summary. The pipeline's initial auto-export keeps it. | Persist the summary (DB column) or re-summarize on manual export. |
| 3 | Summary is regenerated each run; not editable. | Post-MVP: editable summary + regenerate button. |
| 4 | ~~FoundationModels API surface is young; may need adjustment when first compiled on Xcode 26.~~ **Resolved 2026-06-04** — compiled clean on Xcode 26.4.1 (macOS 26.4 SDK); no source changes needed. | — |

---

## Follow-on (separate EPIC-10, not this one)

Release packaging: Developer ID signing + notarization (app + `diarize`
sidecar), PyInstaller release bundle, first-launch model-download UX
(WhisperKit INT-101 + pyannote INT-102), and `DEP/MON/RUN` SoT specs.

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-06-04 | Claude Agent | Created EPIC; shipped the on-device summarization stage (API-401/FEA-007/BR-104/TECH-008) + tests; carried the EPIC-08 Mac validation gate forward into Phase D. |
| 2026-06-04 | Claude Agent | Mac build/validation: fixed the CI test-fixture crash (dup speaker keys); verified compile + 213 tests on Xcode 26 with the live Foundation Models LLM; hardened golden-fixture loading for iCloud `~/Documents`; resolved F-1 (auto-export surfacing) + F-2 (DEBUG-gate demo scaffolding). Remaining Phase D = the manual, device-bound walkthrough. |
