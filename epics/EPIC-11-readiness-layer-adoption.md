---
template_version: "3.3.0"
readiness_inputs:
  work_type: epic
  depends_on_epics: [EPIC-10]
  required_tests: none
  context_budget: { preload: 40000, working_room: 160000 }
  threshold_warn: 70
  threshold_block: 50
  dimension_overrides: { test_coverage: disabled }
---

# EPIC-11 Readiness Layer Adoption

> **State**: `Complete` > **Lifecycle**: cross-cutting (methodology scaffolding; product gate remains v0.7 → v0.8 under EPIC-09)
> **Epic Lead**: Claude Agent
> **Agents**: single-persona (LL-202)
> **Coordination Mode**: `single`

---

<!-- SECTION: cumulative-carry-forward -->
## Cumulative Carry-Forward (read once, then `<!-- HANDOFF -->` past)

- From EPIC-10: domain-profile.yaml is restored and is the contract validate-edges.py reads; deliberate deviations D-1..D-6 preserved; existing EPICs are never retrofitted.
<!-- /SECTION: cumulative-carry-forward -->

---

<!-- SECTION: session-state -->
## Session State (The "Brain Dump")

- **Active Session**: none (EPIC closed 2026-06-09)
- **Last Action**: Readiness suite committed; first `status/readiness.json` computed; EPIC_TEMPLATE 3.3.0 shipped with Codex Gate merged into Phase D.
- **Stopping Point**: Complete.
- **Next Steps**: After EPIC-09 closes the v0.8 gate, consider (a) tuning `dimension_overrides` for pre-readiness EPICs/SoT conventions so scores reflect reality, (b) enabling starter `required_edges` rules one at a time, (c) the deferred devgraph emitter if the HeartBeat data contract needs a second producer.
- **Context**: First readiness computation scores stage v0.8 at 38.4 BLOCK (exit 2). Expected and honest: EPIC-01..09 and the SoT entry conventions predate readiness (no `readiness_inputs` frontmatter, no confidence markers, TEST- mapping differs), and retrofitting closed EPICs is forbidden. The suite's value here is forward-looking (EPIC-12+ on template 3.3.0) plus machine-readable status for the portfolio loop.

### Assumptions & Ambiguities Log

| # | Related ID | Type | Description | Evidence / Reasoning | Resolution |
|---|-----------|------|-------------|---------------------|------------|
| 1 | — | ASSUMPTION | Copied `docs/DEVELOPMENT_GRAPH.md` although the devgraph emitter is deferred | Rules 04/07, domain-profile comments, and validate-edges §14 reference its schema; doc ≠ tooling | Resolved |
| 2 | — | AMBIGUITY | Assessment DoD asked for readiness "PASS/WARN exit ≤1"; actual first run is BLOCK/exit 2 | Reaching ≤1 would require retrofitting closed EPICs or masking dimensions wholesale — both rejected | Logged for maintainer; tune overrides post-EPIC-09 |
<!-- /SECTION: session-state -->

---

## Objective & Scope

> **Goal**: Stand up three-layer readiness scoring + current validators so the portfolio autonomous loop can score `shadow` from proof, not absence; refresh the EPIC template to 3.3.0 for future EPICs.

- **Deliverables**:
  - [x] `scripts/readiness.py` + `compute-*.py` + `_readiness/` + `asof.py` + `requirements.txt` (verbatim from reference @ HEAD)
  - [x] `scripts/validate-ids.sh` synced to reference (check 4 delegation, DR-4); `scripts/validate-edges.py` added
  - [x] `docs/READINESS_PROTOCOL.md` + `docs/DEVELOPMENT_GRAPH.md`; rules 07/08 (shipped with EPIC-10's rules commit)
  - [x] `status/readiness.json` first computation committed
  - [x] `epics/EPIC_TEMPLATE.md` 3.0.0 → 3.3.0 with the Codex Gate merged into Phase D and Cumulative Carry-Forward as a template section (D-2/D-3) — future EPICs only
- **Out of Scope**: devgraph emitter (deferred — modest marginal value for a solo utility), retrofitting EPIC-01..09, `required_edges` enablement (left empty/opt-in), README Squad Status dashboard.

---

## Context & IDs

- **Touched**: scripts/ (additive + validate-ids.sh sync), docs/ (additive), status/ (new), epics/EPIC_TEMPLATE.md
- **References**: LL-001 (Codex Gate carried into template), ARC-004, rule 07

---

## Execution Summary (compressed 5 phases)

- **Phase A/B**: Assessment report Tier 3 plan, owner-approved.
- **Phase C**: Shipped in 2 commits (`dd9685f`, `d23bf33`).
- **Phase D (Validate)**: `python3 scripts/readiness.py run` → writes `status/readiness.json`, stage v0.8 = 38.4 BLOCK exit 2 (expected, see Context). `bash scripts/validate-ids.sh` → exit 1: 0 duplicates, 0 orphans, 87 dangling refs (template range-marker noise class, same as reference repo's own run). `check-stage-gate.sh v0.8` → GATE PASSED exit 0. Codex Gate not run (scaffolding-only; see EPIC-10 Phase D note).
- **Phase E (Harvest)**: Observations below; execution log in `temp/methodology-modernization-assessment.md`.

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | Readiness heuristics under-score pre-readiness repos (test_coverage_zero on EPICs whose 100+ tests live in SoT.TESTING prose; spec_resolution_low on closed work). | Post-EPIC-09: tune per-item `dimension_overrides` instead of editing closed EPICs. | Pending |
| 2 | `portfolio-readiness.sh --repo shadow` (workspace-level) not run from this subagent — workspace root is out of write/run scope for repo-scoped execution. | Maintainer or workspace-level routine should re-run to pick up the new validators' presence. | Pending |

---

## Change Log

| Date       | Agent        | Action |
| ---------- | ------------ | ------ |
| 2026-06-09 | Claude Agent | Created and completed: readiness suite + validators + protocol docs + first status/readiness.json + EPIC_TEMPLATE 3.3.0 (Codex Gate preserved). |
