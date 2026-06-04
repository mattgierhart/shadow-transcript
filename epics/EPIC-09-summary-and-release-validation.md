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

- **Last Action**: 2026-06-04 — Built the on-device summarization stage
  (API-401 / FEA-007). New `Summarization/` module: `SummarizationService`
  protocol, `ExtractiveSummarizer` (dependency-free fallback),
  `FoundationModelsSummarizer` (`#if canImport(FoundationModels)`,
  macOS 26+), `DefaultSummarizationService` (runtime engine selection),
  `SummaryMarkdownRenderer`. Wired a non-fatal summarize step into
  `DefaultPipelineOrchestrator` between format and save; the summary embeds
  into the transcript markdown (no DB migration) so it reaches SQLite +
  Obsidian. New `summarize_on_complete` setting (default on). 9 new tests.
- **Stopping Point**: Code pushed to `claude/codebase-review-next-steps-92HST`
  (PR #12). Awaiting `macos-15` CI build/test to confirm compile + green.
- **Next Steps**:
  1. Confirm CI green on the macOS-15 SDK (FoundationModels path compiles out
     there — that's expected; the extractive path is what CI exercises).
  2. **On the Mac**: build, run a real recording, confirm the summary appears
     in the exported Obsidian note + copied markdown. If on macOS 26, confirm
     the Foundation Models engine activates (summary footer reads "Apple
     Foundation Models"); otherwise it reads "Extractive (on-device)".
  3. Run the deferred **Mac validation walkthrough** (§ Phase D) — TEST-504
     no-network probe, KPI-001/002 baselines, RISK-008 fullscreen probe.
  4. (Polish, optional today) surface the summary in the SCR-004 view and
     preserve it through manual re-export (see Known Limitations).
- **Context**: User decision (2026-06-04): on-device LLM only (BR-104, no
  network); build today, validate on the user's Mac. Build verification is
  CI-driven (no Swift toolchain in the authoring container).

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

### Phase D: Validate (Mac — pending)

- [ ] CI green on `macos-15` (build + full suite incl. new tests).
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
| 4 | FoundationModels API surface is young; `FoundationModelsSummarizer` may need adjustment when first compiled on Xcode 26. | Verify on the Mac; fix in this file only. |

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
