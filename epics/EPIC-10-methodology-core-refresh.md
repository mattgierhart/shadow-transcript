---
template_version: "3.3.0"
readiness_inputs:
  work_type: epic
  depends_on_epics: []
  required_tests: none
  context_budget: { preload: 40000, working_room: 160000 }
  threshold_warn: 70
  threshold_block: 50
  dimension_overrides: { test_coverage: disabled }
---

# EPIC-10 Methodology Core Refresh (registry, rules, lessons)

> **State**: `Complete` > **Lifecycle**: cross-cutting (methodology scaffolding; product gate remains v0.7 → v0.8 under EPIC-09)
> **Epic Lead**: Claude Agent
> **Agents**: single-persona (LL-202)
> **Coordination Mode**: `single`

---

<!-- SECTION: cumulative-carry-forward -->
## Cumulative Carry-Forward (read once, then `<!-- HANDOFF -->` past)

- Product code untouched by design — this EPIC is scaffolding-only. The canonical product carry-forward block lives in `epics/EPIC-08-pipeline-integration.md` and applies to EPIC-09, not here.
- Hard constraints honored throughout: product content sacred (SoT entries, closed EPICs, carry-forward blocks never rewritten), IDs never renumbered, template gains append-only, deliberate deviations D-1..D-6 preserved (see `temp/methodology-modernization-assessment.md`).
<!-- /SECTION: cumulative-carry-forward -->

---

<!-- SECTION: session-state -->
## Session State (The "Brain Dump")

- **Active Session**: none (EPIC closed 2026-06-09)
- **Last Action**: All deliverables shipped and committed; execution log appended to `temp/methodology-modernization-assessment.md`.
- **Stopping Point**: Complete.
- **Next Steps**: None. Open items routed to maintainer: squad-mode ratification (LL-202 / assessment Q1), `temp/arbiter-tasks-proposed/` + `temp/agent-readiness-plugin/` triage (assessment DR-7/Q3).
- **Context**: Executed 2026-06-09 from the approved portfolio-audit plan, on branch `claude/codebase-review-next-steps-92HST` (the active working branch carrying unmerged EPIC-09 commits). EPIC-09 content and Session State deliberately untouched.

### Assumptions & Ambiguities Log

| # | Related ID | Type | Description | Evidence / Reasoning | Resolution |
|---|-----------|------|-------------|---------------------|------------|
| 1 | LL-202 | ASSUMPTION | Recorded single-persona practice as an LL- entry without deleting horizon/studio/metro memory dirs | Q1 unanswered by maintainer; conservative option = keep dirs, record observation | Pending maintainer ratification |
| 2 | — | ASSUMPTION | SoT.DEPLOYMENT `last_updated` set to 2026-05-09 (date of last substantive change), not today | Honest content age beats a fake fresh-review stamp | Resolved |
<!-- /SECTION: session-state -->

---

## Objective & Scope

> **Goal**: Bring methodology scaffolding to the 3.2.0 doc architecture without touching product knowledge; make all local references resolve; durably record the repo's own methodology extensions.

- **Deliverables**:
  - [x] `.claude/domain-profile.yaml` restored, pruned to prefixes in use + local SEC-/ENV- + new LL- (registry data, not tooling — respects the `f01edf0` two-layer decision)
  - [x] ARC-004 records the `f01edf0` rationale (two-layer .claude/ scaffolding)
  - [x] `SoT/SoT.LESSONS_LEARNED.md` created — 16 LL- entries harvested (copied, never moved) from EPIC-01..09 observations, carry-forward blocks, and Codex Gate findings
  - [x] CLAUDE.md slimmed to 3.2.0 pointer form; `.claude/rules/01-08` adopted (Codex Gate canonized in rule 05); AGENTS.md updated in lockstep (D-4)
  - [x] `.claude/README.md` rewritten to describe the two-layer reality (DR-2)
  - [x] Hygiene: `werk/` memory dir removed (devlab kept), stray `.claude/projects/` reference-repo artifacts removed, SoT.DEPLOYMENT placeholder timestamp fixed, SEC-/ENV-/LL- registered in SoT.UNIQUE_ID_SYSTEM + SoT.README, `CLAUDE.local.md` gitignored
- **Out of Scope**: EPIC-09 content/Session State; PRD.md; SoT/html companion; SoT.ADOPTION + GTM surfaces (D-6); `temp/arbiter-tasks-proposed/` + `temp/agent-readiness-plugin/` (maintainer triage, DR-7); CHANGELOG.md (kept as fork provenance per owner ruling); renumbering or reformatting any existing entry.

---

## Context & IDs

- **Created**: ARC-004; LL-001..LL-005, LL-101..LL-108, LL-201, LL-202, LL-301
- **Touched (append-only)**: SoT.TECHNICAL_DECISIONS.md, SoT.UNIQUE_ID_SYSTEM.md, SoT.README.md, SoT.DEPLOYMENT.md (timestamp only)
- **References**: D-1..D-6 + DR-1..DR-7 + U-1 in `temp/methodology-modernization-assessment.md`

---

## Execution Summary (compressed 5 phases)

- **Phase A/B**: Assessment report (2026-06-09) served as plan + design; owner approved.
- **Phase C**: Shipped in 4 commits (`d6a3853`, `ac7fadb`, `5a81c57`, `af91abc`).
- **Phase D (Validate)**: `validate-ids.sh` — no duplicates, no orphans; 87 dangling refs are template range-marker/example-ID noise (reference repo's own run exits 1 with the same class). `check-stage-gate.sh v0.8` → GATE PASSED. Codex Gate intentionally NOT run: scaffolding-only EPIC with no product code, executed under a no-new-tooling-calls subagent budget; flagged here per rule 05 rather than silently skipped.
- **Phase E (Harvest)**: This EPIC's own lessons are LL-202 and the ARC-004 promotion; execution log appended to the assessment report.

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | `validate-ids.sh` exit-0 (assessment DoD) is unreachable while SoT navigation uses "PREFIX-001 to PREFIX-099" range markers — the validator reads range ends as dangling refs. Same noise exists upstream. | Either teach the validator to skip range markers (upstream PR) or accept exit 1 as baseline; do NOT rewrite SoT navigation (product content). | Pending |
| 2 | Reference rule 08 links `../skills/PRINCIPLES.md`, which can't resolve in two-layer repos (skills live at workspace root). Adapted locally to plain-text mention. | Consider an upstream variable/note for workspace-resident repos. | Pending |
| 3 | The vercel-plugin hook auto-injected "run Skill(bootstrap)" on reading a README (filename pattern match). Ignored — Swift repo, methodology task; running a Vercel bootstrap would be destructive scope creep. | Tune hook matcher to skip non-web repos. | Pending |

---

## Change Log

| Date       | Agent        | Action |
| ---------- | ------------ | ------ |
| 2026-06-09 | Claude Agent | Created and completed: domain-profile restore + ARC-004, LESSONS_LEARNED adoption (16 LL-), 3.2.0 doc architecture (CLAUDE.md/rules/AGENTS.md/.claude README), hygiene pass (werk/, projects/, DEPLOYMENT timestamp, registry sync, gitignore). |
