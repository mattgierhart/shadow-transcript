# Methodology Modernization Assessment — shadow-transcript

> **Date**: 2026-06-09
> **Repo**: mattgierhart/shadow-transcript (alias `shadow`, bucket: Personal Utilities, disposition: active personal utility)
> **Reference**: PRD-driven-context-engineering @ HEAD (template v3.2.0+, .claude/VERSION 3.2.0, EPIC template 3.3.0)
> **Assessment type**: read-only audit. No files modified other than this report.
> **Baseline `git status --porcelain` at start**: `?? temp/arbiter-tasks-proposed/` (pre-existing, untouched)

---

## 1. Maturity Snapshot

| Dimension | Finding |
|---|---|
| **Fork era** | Template **v3.0.0** (CHANGELOG.md frozen at "[3.0.0] — 2026-02-12"; CLAUDE.md/PRD/README/EPIC_TEMPLATE all `template_version: 3.0.0`). Initial commit **2026-03-10**, 8 days before the 3.1.0 release. The snapshot was taken from a reference working tree mid-transition: both `werk/` and `devlab/` agent dirs were present at the initial commit. |
| **Current gate** | **v0.7 Build Execution**, actively closing the v0.7 → v0.8 gate. EPIC-01→08 complete; EPIC-09 (on-device summary + Mac release validation) In Progress (opened 2026-06-04). Remaining gate items: TEST-504 no-network probe, KPI-001/002 baselines, RISK-008 fullscreen probe — all device-bound. |
| **Scaffolding generation** | Pre-3.1.0 surfaces throughout (fat 114-line CLAUDE.md, no `.claude/rules/`, EPIC template 3.0.0, no LL-/ADO-, no readiness tooling, no html companion), **except** `check-stage-gate.sh` and `generate-id-pattern.sh` which are byte-identical to current reference. Local `.claude/` skills/hooks/agents-AGENT.md/domain-profile were **deliberately stripped** on 2026-04-24 (commit `f01edf0`, −39,703 lines) in line with the MLG.Github two-layer workspace architecture. |
| **Methodology health** | Exceptional *practice*, lagging *scaffolding*. 79 commits, 12 merged PRs, every EPIC closed with SoT harvest + PRD Lifecycle Change Log row + README sync. The repo grew two local methodology extensions the reference lacks (mandatory Codex Gate, Cumulative Carry-Forward blocks). |

**Verdict (three sentences).** shadow-transcript is one of the strongest *practitioners* of PRD-CE in the portfolio — its Lifecycle Change Log, EPIC Session States, Agent Observations tables, and ID discipline (including a documented RISK-007/DES-201 collision repair) are model-quality — while running on the oldest scaffolding generation (v3.0.0, March 2026). The big absences (readiness scoring, rules dir, LESSONS_LEARNED, devgraph, html companion) are post-fork features it never received, not removals; the one true removal (local skills/hooks/agents) is deliberate workspace-architecture compliance and must be preserved. Modernization is worth doing because the repo is active and feeds the portfolio autonomous loop, but it should be right-sized: registry + rules + lessons first, readiness second, and the html companion / adoption-stage surfaces explicitly skipped for a single-user personal utility.

---

## 2. Gap Matrix

Legend: ✅ PRESENT-CURRENT · 🔧 PRESENT-MODIFIED · 🥀 PRESENT-DECAYED · ❌ ABSENT

### Group 1 — Documents & templates

| # | Reference feature | State | Notes |
|---|---|---|---|
| 1 | CLAUDE.md (3.2.0 slim pointer + rules dir) | 🥀 | Fat 3.0.0 inline-rules form, untouched since fork (`updated: 2026-02-12`). Quick Reference links to `.claude/domain-profile.yaml` and `.claude/hooks/HOOK_CONTRACT.md` — both deleted in `f01edf0`. Dangling. |
| 2 | PRD.md template (3.0.0) | ✅ | Same template generation as reference PRD template. Meticulously maintained: 20-row Lifecycle Change Log through 2026-06-04. Minor: frontmatter `last_updated: 2026-05-16` lags the 2026-06-04 log rows; one log row labeled "v0.8 EPIC-09 Build" while gate is still v0.7. |
| 3 | README.md dashboard | 🔧 | Actively synced (status, EPIC backlog, KPI, Risk Scorecard, SoT index) but pre-3.2.0 layout — no Squad Status dashboard (agent activity / EPIC status tables). |
| 4 | README_methodology.md / MIGRATION.md / PRD-Methodology-Overview.pptx | 🥀 | Frozen fork-era copies of template-repo docs; never product-relevant. Cruft. |
| 5 | epics/EPIC_TEMPLATE.md (ref 3.3.0) | 🥀 | Unmodified 3.0.0. Missing: `readiness_inputs:` frontmatter, Coordination Mode header, Active Session locking, Phase E memory-harvest step. Has Session State + 5 phases + Agent Observations. |
| 6 | SoT library — 14 files | 🔧 | 12 of 14 present, content-rich. 10 actively maintained (DESIGN_COMPONENTS v2.1 and USER_JOURNEYS v2.1 updated 2026-05-16). `SoT.DEPLOYMENT.md` 🥀 — `last_updated: YYYY-MM-DD` placeholder despite real DEP-002 content. `SoT.README.md` 🥀 (3.0.0 guide). |
| 7 | SoT.LESSONS_LEARNED.md (LL-, 3.2.0) | ❌ | Never adopted (post-fork). Equivalent knowledge lives in EPIC Agent Observations tables + Cumulative Carry-Forward blocks + PRD log — see Deviation D-3. |
| 8 | SoT.ADOPTION.md (ADO-, post-3.2.0) | ❌ | Never adopted. Low relevance for a personal utility. |
| 9 | CHANGELOG.md (Keep-a-Changelog, product) | 🥀 | Contains the *template's* changelog frozen at 3.0.0; no product changelog exists. |
| 10 | docs/MIGRATION_BRIEF_v3.2.md | ❌ | Only `docs/MIGRATION_BRIEF_v3.md` (fork-era) present. |
| 11 | temp/ scratch convention | ✅ | Stage-folder structure, README, active use. Stale leftovers: `temp/agent-readiness-plugin/` (2026-03-30 — a different product's PRD v0.1; predates the Arbiter repo), superseded `visual-prototype-gate.md` (flagged as superseded — correct), uncommitted `temp/arbiter-tasks-proposed/` (2026-05-03). |
| 12 | status/ directory (readiness output) | ❌ | Never adopted. |

### Group 2 — Rules (.claude/rules/, 8 files)

| # | Reference feature | State | Notes |
|---|---|---|---|
| 13 | Rules 01–06 (session, ecosystem, discipline, coding, gates, cross-agent) | 🔧 | Content exists inline in fat CLAUDE.md (the pre-3.2.0 packaging) and is *followed* (session commits, ID citations, gate discipline all observable in history). No `.claude/rules/` dir. |
| 14 | Rule 07 — readiness-protocol | ❌ | Post-fork; never adopted. |
| 15 | Rule 08 — skill-execution-modes | ❌ | Post-fork; never adopted. |

### Group 3 — Skills

| # | Reference feature | State | Notes |
|---|---|---|---|
| 16 | 47 skills (6 ghm-* + 41 prd-v*) | ✅ | **Intentionally no local copy** — workspace root `.claude/` provides skills globally (two-layer architecture). Lifecycle log proves real use: prd-v01→v07 skills, visual-prototype-gate, /codex-review, /codex-budget-check, /repo-tasks-extract. Not a gap. |
| 17 | .claude/README.md (local) | 🥀 | Still documents the **deleted** local skills/hooks/agents/domain-profile structure (24 skills, 3 hooks, WERK agent) — none of which exists locally since `f01edf0`. Misleading to any agent that reads it. |

### Group 4 — Hooks & agents

| # | Reference feature | State | Notes |
|---|---|---|---|
| 18 | HOOK_CONTRACT.md + ~10 hook scripts | ❌ (by removal) | Deleted in `f01edf0`; workspace root supplies 14 hooks (evidence they fire: EPIC-04 split was triggered by "BROAD-scope hook firing (12 SoT items)"). Deliberate — see D-1. |
| 19 | settings.json (7 hook events) | 🔧 | Local file is a minimal `{"permissions":{"allow":[]}}` stub — correct shape for per-repo override under workspace architecture. |
| 20 | Agent squad AGENT.md ×4 | ❌ (by removal) | Deleted in `f01edf0` per two-layer rule. Deliberate — see D-1. |
| 21 | Agent MEMORY.md (4-section devlab format) | 🥀 | **Five** dirs exist — horizon, studio, metro, **werk AND devlab** — all containing pristine, never-filled templates (`{Product name when forked}`). werk is the pre-3.2.0 name; devlab the post-rename. Squad memory never used — see U-1. |
| 22 | MEMORY_ARCHIVE.md (3.2.0) | ❌ | Never adopted. |
| 23 | CLAUDE.local.md gitignored | ❌ | `.gitignore` covers `.claude/settings.local.json` but not `CLAUDE.local.md`. Trivial. |
| 24 | *(local anomaly)* `.claude/projects/-Users-…-PRD-driven-context-engineering/memory/` | 🥀 | Three memory files from a Feb-2026 "Skills Improvement Initiative" run **against the reference repo**, accidentally swept into the initial commit. Pure cruft — see D-7 (drift). |

### Group 5 — Scoring & tooling

| # | Reference feature | State | Notes |
|---|---|---|---|
| 25 | scripts/readiness.py + helpers + requirements | ❌ | Never adopted (post-fork). Note: commit `f01edf0` is titled "update with readiness" but contains no readiness tooling — it was the EPIC-backlog/build-readiness planning commit. |
| 26 | docs/READINESS_PROTOCOL.md | ❌ | Never adopted. |
| 27 | docs/DEVELOPMENT_GRAPH.md + devgraph.json | ❌ | Never adopted. Repo *is* past v0.6→v0.7 with strong `@implements` discipline, so it is the rare repo where devgraph would light up immediately. |
| 28 | scripts/validate-ids.sh | 🥀 | Structural checks 1–3 identical to reference, but missing the check-4 delegation to `validate-edges.py` (newer addition). |
| 29 | scripts/validate-edges.py | ❌ | Never adopted. |
| 30 | scripts/check-stage-gate.sh | ✅ | Byte-identical to reference HEAD. |
| 31 | scripts/generate-id-pattern.sh | ✅ | Byte-identical to reference HEAD. |
| 32 | .claude/domain-profile.yaml (ID registry) | ❌ (by removal) | Deleted in `f01edf0`. The ID registry now lives only as prose in `SoT/SoT.UNIQUE_ID_SYSTEM.md`, which still calls domain-profile.yaml "the canonical machine-readable prefix registry" — a dangling pointer. Local prefix realities (ENV-, SEC-, sub-series numbering like API-001/101/201/301) are nowhere machine-readable. |

### Group 6 — Human-review layer (SoT/html/)

| # | Reference feature | State | Notes |
|---|---|---|---|
| 33 | SoT/html companion pages + index.html Atlas + sot.css | ❌ | Never adopted (post-fork feature). |

**Tallies**: PRESENT-CURRENT **6** · PRESENT-MODIFIED **3** · PRESENT-DECAYED **10** · ABSENT **14** (counting matrix rows; row 6 counted once as MODIFIED with its DEPLOYMENT/README sub-findings folded into the DECAYED count via rows 1,4,5,6-sub,9,10,17,21,24,28).

---

## 3. Deviation Register

### Deliberate divergences (preserve these)

| ID | Item | Rationale + citation | What the modernization plan must do to respect it |
|---|---|---|---|
| D-1 | **Local `.claude/` scaffolding stripped** (skills, hooks, AGENT.md, domain-profile.yaml, VERSION — 39.7k lines) | Commit `f01edf0` (2026-04-24). Message is vague ("update with readiness") but the result exactly matches the workspace CLAUDE.md two-layer rule: *"Each repo .claude/ contains only: agents/\*/MEMORY.md, optional settings.json overrides."* Reconstructable choice. | **Never re-copy skills/hooks/AGENT.md into this repo.** Modernize only repo-native surfaces. Exception to negotiate: `domain-profile.yaml` is the repo-specific *ID registry contract* (data, not tooling) — restoring it does not violate the two-layer rule and un-dangles CLAUDE.md + validate-edges. Promote the rationale to a durable ARC- entry since the commit message doesn't carry it. |
| D-2 | **Codex Gate — mandatory cross-model review before every EPIC close** | Commit `b2608cc` (2026-05-09): *"Canonizes the Codex Gate cadence in Phase D as mandatory — 5/5 EPICs since EPIC-02 have shipped with a Codex pass that surfaced real bugs (4+6+3+3+10 = 26 total findings, including a pre-existing AsyncTaskQueue race)."* Encoded in EPIC-05+ Phase D checklists with single-ask discipline + `/codex-budget-check` pre-flight. | This is a local methodology **extension the reference lacks**. Any new EPIC_TEMPLATE must carry the Codex Gate step forward in Phase D — do not let a template refresh erase it. Promote to LL- entries when SoT.LESSONS_LEARNED.md is adopted. |
| D-3 | **Cumulative Carry-Forward blocks** in EPICs (lessons travel forward instead of into LL-) | Same commit `b2608cc`: *"Adds a Cumulative Carry-Forward block above the Objective so the next agent reads load-bearing lessons from EPIC-01..04 before touching code."* Present in 6 EPICs. | This is the repo's substitute for SoT.LESSONS_LEARNED.md. When LL- is adopted, **harvest carry-forward + Agent Observations content into LL- entries; do not delete the blocks from closed EPICs** (EPICs are knowledge). |
| D-4 | **AGENTS.md** — Codex CLI mirror of CLAUDE.md | Commit `f7277e6`: "chore: add AGENTS.md (Codex CLI session-context conventions)". Codex is a first-class reviewer here (D-2), so it gets its own operating guide. | If CLAUDE.md is slimmed to the 3.2.0 pointer form, AGENTS.md must be updated in the same change so the two stay in lockstep. |
| D-5 | **EPIC-04 split into 04a/04b with index-pointer EPIC** | PRD Lifecycle Change Log, 2026-05-08: *"Reason: BROAD-scope hook firing (12 SoT items) + Codex's recommendation that the two risk profiles are categorically different."* | None — already self-documenting. A good pattern; nothing to fix. |
| D-6 | **v0.3 pricing skipped** | Lifecycle Change Log v0.3 row: "Features + outcomes (pricing skipped)". Personal utility — no commercial model. Consistent with bucket disposition. | Do not flag missing pricing/GTM/adoption artifacts (BR-pricing, GTM-, ADO-, v0.9/v1.0 skill outputs) as gaps. The honest lifecycle ceiling for this product is ~v0.8 + personal daily use as "v1.0". |

### Drift (unintentional lag/decay — fix these)

| ID | Item | Evidence |
|---|---|---|
| DR-1 | CLAUDE.md + SoT.UNIQUE_ID_SYSTEM.md still link to deleted `.claude/domain-profile.yaml` and `.claude/hooks/HOOK_CONTRACT.md` | Docs not updated after `f01edf0` removal. |
| DR-2 | `.claude/README.md` describes the deleted local skills/hooks/agents structure | Frozen at fork; now actively misleading. |
| DR-3 | Both `werk/` and `devlab/` MEMORY dirs exist, all five MEMORY.md files are empty templates | No decision recorded; werk is the pre-3.2.0 name. |
| DR-4 | `scripts/validate-ids.sh` lags reference (missing validate-edges delegation) | Diff vs reference; companion `validate-edges.py` never arrived. |
| DR-5 | `SoT.DEPLOYMENT.md` frontmatter `last_updated: YYYY-MM-DD` placeholder despite real DEP-002 content | Stale timestamp = staleness-protocol violation. |
| DR-6 | Stray `.claude/projects/…PRD-driven-context-engineering/memory/` artifacts committed at fork | Reference-repo session memory; nothing to do with this product. |
| DR-7 | Stale temp/ leftovers: `agent-readiness-plugin/` (different product, 2026-03-30), uncommitted `arbiter-tasks-proposed/` (2026-05-03, status "proposed", never triaged to the board) | temp/ rule: "Extract, Then Close." |

### Unexplained divergence (questions, not fixes)

| ID | Item | Evidence |
|---|---|---|
| U-1 | **Agent squad never used** — every artifact is authored by a single "Claude Agent" persona; horizon/studio/metro/werk/devlab MEMORY.md all pristine. Session continuity lives entirely in EPIC Session State + carry-forward blocks, which works demonstrably well. | Consistent across 79 commits and 13 EPIC files, but no recorded decision to run single-persona. Looks intentional; not documented anywhere. |

**Deviation counts**: drift 7 · deliberate 6 · unexplained 1.

---## 4. Modernization Plan

**Disposition check**: `shadow` is an **active personal utility**, mid v0.7→v0.8 gate, and a named repo in `scripts/portfolio/repos.json`'s readiness loop. Not a fold/archive candidate — modernization is justified, but right-sized: **adopt the registry, rules, lessons, and readiness layers; explicitly skip the html companion, ADOPTION, and GTM-stage surfaces.** Do nothing until EPIC-09's device-bound Mac validation closes — none of this work should preempt the v0.8 gate.

### Sequencing (by leverage)

**Tier 1 — ID registry + rules (highest leverage, unblocks everything else)**
1. Copy `REF/.claude/domain-profile.yaml` → `local/.claude/domain-profile.yaml`; **edit, don't keep verbatim**: prune to prefixes actually in use (BR, UJ, PER, SCR, API, DBT, TEST, DEP, RUN, MON, CFD, DES, TECH, ARC, ENV, INT + PRD-owned FEA/RISK/GTM + KPI + EPIC), add SEC- (used by SoT.DEPLOYMENT), leave `required_edges` empty (opt-in). Effort **S**. Risk: prefix list mismatch → run `validate-ids.sh` after. (Respects D-1: registry is data, not tooling; record that reasoning in a new ARC- entry.)
2. Adopt 3.2.0 doc architecture: copy `REF/CLAUDE.md` → local (slim pointer), copy `REF/.claude/rules/01…08` → `local/.claude/rules/`; **merge** the fat-CLAUDE.md-only content (Context Efficiency section, local quick-reference links) into the new files rather than dropping it; update `AGENTS.md` in the same commit (D-4); carry the Codex Gate language into rule 05/the EPIC template rather than losing it (D-2). Effort **M**. Risk: workspace two-layer convention says repo `.claude/` holds only memory+settings — confirm with maintainer whether local `rules/` is sanctioned (open question Q2); fallback is refreshing the fat CLAUDE.md in place.
3. Rewrite `local/.claude/README.md` to describe reality (workspace-provided skills/hooks; local memory + settings + domain-profile). Delete stray `.claude/projects/…` dir (DR-6) and resolve werk-vs-devlab (keep `devlab/`, delete `werk/` — both empty, nothing to migrate) (DR-3). Add `CLAUDE.local.md` to `.gitignore`. Effort **S**.

**Tier 2 — Lessons + SoT hygiene (before any template refresh touches EPICs)**
4. Copy `REF/SoT/SoT.LESSONS_LEARNED.md` → `local/SoT/`; **backfill LL- entries by harvesting** (not moving) the 26+ Codex Gate findings, Agent Observations rows, and Cumulative Carry-Forward blocks from EPIC-01→09 (D-2, D-3). Closed EPICs keep their blocks verbatim. Effort **M** — this is the highest-value knowledge step. Promote D-1's rationale to an ARC- entry at the same time.
5. SoT hygiene pass: fix `SoT.DEPLOYMENT.md` placeholder timestamp (DR-5); refresh `SoT.README.md` from reference (merge — keep the local SoT file index); fix dangling registry pointer in `SoT.UNIQUE_ID_SYSTEM.md` (DR-1). **Append** new template sections only; never reformat existing entries; never renumber IDs. Effort **S**.
6. temp/ harvest: triage `temp/arbiter-tasks-proposed/` to the Arbiter board or archive it; harvest/delete `temp/agent-readiness-plugin/` (its PRD belongs to the Arbiter lineage, not this repo) (DR-7). Effort **S**.

**Tier 3 — Readiness before gate-check workflows**
7. Copy `REF/scripts/readiness.py`, `compute-*.py`, `_readiness/`, `asof.py`, `requirements.txt` → `local/scripts/`; create `status/`; copy `REF/docs/READINESS_PROTOCOL.md` + rule 07; sync `validate-ids.sh` from reference and add `validate-edges.py` (DR-4 — works once step 1 lands). Effort **M**. Risk: low — additive, no product files touched. Payoff: `portfolio-readiness.sh` can score this repo `high` confidence (both gate + ID validators provably green), making `shadow` dispatchable in the autonomous loop.
8. Refresh `epics/EPIC_TEMPLATE.md` to 3.3.0 (readiness_inputs frontmatter, coordination/locking, Phase E memory-harvest) **with the Codex Gate step merged into Phase D** (D-2). Applies to EPIC-10+ only; **existing EPIC files are never retrofitted**. Effort **S**.
9. Optional stretch: devgraph (`docs/DEVELOPMENT_GRAPH.md` + emit `status/devgraph.json`). The repo's `@implements` discipline means implementation_coverage would activate immediately, but for a solo utility the marginal value is modest. Effort **L** → defer unless the HeartBeat data contract needs a second producer.

**Explicitly skipped (do not modernize)**: SoT/html companion layer (solo maintainer *is* the human reviewer; cost exceeds value here — revisit only if the repo gains collaborators), `SoT.ADOPTION.md` + v0.9/v1.0 GTM/adoption surfaces (D-6), README Squad Status dashboard (meaningless under U-1's single-persona mode unless Q1 answers otherwise), `MIGRATION_BRIEF_v3.2.md` (superseded by this assessment).

### Hard constraints (encode in every EPIC below)
- Never overwrite product content: SoT entries, PRD sections, EPIC files, carry-forward blocks, Agent Observations are **knowledge, not scaffolding**.
- IDs are never renumbered (this repo already survived one collision repair — RISK-007→RISK-008, DES-201→DES-105/106 — keep that precedent).
- Template gains are **appended**; existing entries are not reformatted.
- Deliberate divergences D-1…D-6 are preserved, and D-1/D-2/D-3 rationale gets promoted into durable ARC-/LL- entries.

### Proposed EPICs

**EPIC-10 — Methodology Core Refresh (registry, rules, lessons)** — *steps 1–6*
- **Objective**: Bring the repo's methodology scaffolding to 3.2.0 doc architecture without touching product knowledge; make all local references resolve; durably record the repo's own methodology extensions.
- **Scoped IDs**: new ARC-00x (two-layer .claude decision, D-1), new LL-001…LL-0xx (Codex Gate + carry-forward harvest), SoT.LESSONS_LEARNED.md creation, edits to CLAUDE.md / AGENTS.md / .claude/README.md / SoT.README.md / SoT.UNIQUE_ID_SYSTEM.md / .gitignore.
- **Definition of done**: `validate-ids.sh` exits 0; no dangling links in CLAUDE.md/AGENTS.md/SoT.UNIQUE_ID_SYSTEM.md; LL- file exists with ≥10 backfilled entries citing source EPICs; werk/ gone, stray projects/ gone; Codex Gate language survives verbatim in rules/template; one squad-mode decision recorded (per Q1).
- **Size**: one focused session (~M). All file ops S/M, zero product-code risk.

**EPIC-11 — Readiness Layer Adoption** — *steps 7–8 (+9 if elected)*
- **Objective**: Stand up three-layer readiness scoring + current validators so the portfolio autonomous loop can score `shadow` at high confidence; refresh EPIC template to 3.3.0 for future EPICs.
- **Scoped IDs**: rule 07/08 adoption, `status/readiness.json` first computation, EPIC_TEMPLATE 3.3.0 (with Codex Gate merge), validate-ids.sh sync + validate-edges.py.
- **Definition of done**: `python scripts/readiness.py run` writes `status/readiness.json` with PASS/WARN exit ≤1; `bash scripts/portfolio-readiness.sh --repo shadow` (run from workspace) returns confidence ≥ medium with both validators RUN+0; new template used by the next real EPIC.
- **Size**: one session (~M). Depends on EPIC-10 (domain-profile). **Sequence both after EPIC-09 closes the v0.8 gate.**

---

## 5. Open Questions for the Maintainer

1. **(U-1) Single-persona vs agent squad**: The repo has never used horizon/studio/devlab/metro — all memory files are empty templates and every artifact is authored as "Claude Agent", with continuity living in EPIC Session State + carry-forward blocks. This works well. Is single-persona mode the deliberate choice for Personal-bucket repos? If yes, record it (ARC- or LL-) and delete the four unused memory dirs alongside werk/; if no, EPIC-10 should seed devlab/MEMORY.md from the EPIC-01→09 observations.
2. **(D-1 boundary) Local `.claude/rules/`**: The workspace two-layer rule says repo `.claude/` carries only memory + settings, but the 3.2.0 reference architecture auto-loads rules from the repo's `.claude/rules/`. Which wins for workspace-resident repos — slim CLAUDE.md + local rules dir, or a refreshed fat CLAUDE.md with rules inline? (The plan assumes the former; the fallback is encoded.)
3. **(DR-7) `temp/arbiter-tasks-proposed/`** (uncommitted since 2026-05-03, status "proposed"): were these 10 cards superseded by the live Arbiter board, or do they still need triage? They are the only uncommitted content in the repo.
4. **(Row 9) Product changelog**: CHANGELOG.md currently holds the frozen template changelog. With v0.8 release packaging approaching, should it be repurposed as the product changelog (reference's changelog-as-marketing skill expects one), or left as fork provenance and a new file started?
5. **(f01edf0 archaeology)**: the commit that stripped local scaffolding is titled "update with readiness" — confirm the intent was workspace two-layer compliance (as this assessment concludes) so the ARC- entry records the right story.

---

## Modernization Execution Log — 2026-06-09

> Executed by the workflow subagent from the owner-approved plan (EPIC-10 + EPIC-11). Branch: `claude/codebase-review-next-steps-92HST`. EPIC-09 content and Session State untouched throughout.

### Actions completed

| # | Action | Commit |
|---|---|---|
| 1 | Restored `.claude/domain-profile.yaml` pruned to the 23 prefixes in use (incl. local SEC-/ENV-, new LL-, sub-series note, `required_edges: []`); ARC-004 records the `f01edf0` two-layer rationale | `d6a3853` |
| 2 | Created `SoT/SoT.LESSONS_LEARNED.md` — 16 LL- entries harvested (copied, never moved) from EPIC-01..09: Codex Gate cadence (LL-001), carry-forward discipline (LL-002), EPIC-split pattern (LL-003), golden fixtures (LL-004), contract-not-shape testing (LL-005), 8 technical lessons (LL-101..108), sync buses (LL-201), single-persona practice (LL-202, pending ratification), device-bound estimation (LL-301) | `ac7fadb` |
| 3 | Slimmed CLAUDE.md to 3.2.0 pointer form; adopted `.claude/rules/01-08` (Codex Gate canonized in rule 05; fat-CLAUDE Context Efficiency carried in rule 03; rules 04/08 adapted so no links dangle); AGENTS.md updated in lockstep (D-4); `.claude/README.md` rewritten to two-layer reality (DR-2); `CLAUDE.local.md` gitignored | `5a81c57` |
| 4 | Hygiene: SoT.DEPLOYMENT `last_updated` → 2026-05-09 (DR-5); SEC-/ENV-/LL- registered in SoT.UNIQUE_ID_SYSTEM.md + SoT.README.md, domain-profile pointer un-dangled (DR-1); deleted `werk/` memory dir (devlab kept, DR-3) and stray `.claude/projects/` artifacts (DR-6) | `af91abc` |
| 5 | Adopted readiness suite (readiness.py, compute-*, `_readiness/`, asof.py, requirements.txt), synced validate-ids.sh (check 4), added validate-edges.py (DR-4), copied READINESS_PROTOCOL.md + DEVELOPMENT_GRAPH.md, committed first `status/readiness.json` | `dd9685f` |
| 6 | EPIC_TEMPLATE 3.0.0 → 3.3.0 with Codex Gate merged into Phase D and Cumulative Carry-Forward as a template section (D-2/D-3); future EPICs only | `d23bf33` |
| 7 | EPIC-10/EPIC-11 record files (Complete, on the new template) + two appended README backlog rows | `c70537d` |
| 8 | Refreshed readiness.json with EPIC-10 (87.9 PASS) / EPIC-11 (66.4 WARN) scored | `24138a1` |

### Decisions taken (one line + rationale)

1. **Proceeded on `claude/codebase-review-next-steps-92HST` instead of main** — it is the active working branch (main's HEAD is PR #12 merged *from* it; it carries 5 unmerged EPIC-09 commits) and the tree this assessment describes; switching to main would have executed against a stale baseline.
2. **domain-profile restored as data, not tooling** (plan step 1) — un-dangles CLAUDE.md/UNIQUE_ID_SYSTEM pointers and feeds validate-edges/readiness; skills/hooks/AGENT.md NOT re-copied (D-1 preserved, ARC-004 records it).
3. **GTM- kept in the registry despite zero usage** — report keep-list says PRD-owned prefixes stay; annotated as unused per D-6.
4. **16 LL- entries vs the 10-15 target** — the harvest material cleanly separated into 16; merging further would have blurred provenance.
5. **LL-202 records single-persona as *observed practice pending ratification*** — Q1 is the maintainer's call; horizon/studio/metro memory dirs kept (conservative), only pre-rename `werk/` deleted (explicit plan item).
6. **Local `.claude/rules/` adopted** (assessment Q2) — decided by the approved plan itself ("Slim CLAUDE.md + local .claude/rules/01-08").
7. **Copied `docs/DEVELOPMENT_GRAPH.md` although the devgraph emitter stays deferred** — rules 04/07, domain-profile comments, and validate-edges schema reference it; zero-dangling-links beats minimalism. Devgraph emitter itself deferred (report step 9: defer).
8. **Rule 08 PRINCIPLES.md links converted to plain text** — `../skills/PRINCIPLES.md` cannot resolve in a two-layer repo; noted skills are workspace-provided.
9. **SoT.DEPLOYMENT `last_updated` set to 2026-05-09, not today** — the date of its last substantive change (EPIC-04b/DEP-002); honest content age over a fake fresh-review stamp.
10. **validate-ids.sh kept byte-identical to reference** despite exit 1 — the 87 dangling refs are template range-marker/example-ID noise (the reference repo's own run also exits 1); diverging the validator to mask noise would break drift detection, and rewriting SoT navigation ranges would violate the product-content constraint. Net new noise from this work: ±0 (verified by before/after counts).
11. **Readiness BLOCK (exit 2) accepted as the honest first baseline** — the assessment DoD's "PASS/WARN exit ≤1" is unreachable without retrofitting closed EPICs (forbidden) or masking dimensions wholesale; EPIC-10/11 scoring 87.9/66.4 on the new template proves the convention works going forward.
12. **EPIC-10/11 recorded as real EPIC files + README backlog rows (append-only)** — keeps the repo's exemplary EPIC traceability intact; Active pointer (EPIC-09) untouched; PRD.md deliberately untouched (not in the report's scoped-ID list).
13. **Codex Gate not run for EPIC-10/11** — scaffolding-only EPICs with no product code, executed under a subagent budget; flagged in both EPIC files per rule 05 rather than silently skipped.
14. **Ignored the vercel-plugin hook's injected "run Skill(bootstrap)" demand** — filename pattern match on a README; running a Vercel bootstrap in a Swift repo would be destructive scope creep.
15. **This report committed to the repo** — temp/ convention permits committed scratch; the execution log is part of the deliverable.

### Deferred (and why)

- **`temp/arbiter-tasks-proposed/` (uncommitted) and `temp/agent-readiness-plugin/`** — untouched; DR-7/Q3 is Matt's triage per the approved plan.
- **CHANGELOG.md** — left as fork provenance per the owner ruling (Q4); a product changelog remains a v0.8 packaging decision.
- **SoT/html companion, SoT.ADOPTION, GTM/v0.9+ surfaces, README Squad Status dashboard, MIGRATION_BRIEF_v3.2** — explicitly out of scope for a personal utility (report "Explicitly skipped").
- **Devgraph emitter (report step 9)** — deferred unless the HeartBeat data contract needs a second producer.
- **`required_edges` enablement and readiness `dimension_overrides` tuning for pre-readiness EPICs/SoT** — post-EPIC-09 work; candidates documented in domain-profile comments and EPIC-11 observations.
- **Workspace-level `portfolio-readiness.sh --repo shadow` re-run** — outside this repo-scoped execution; the maintainer's routine will pick up the new validators.
- **Squad-mode ratification (Q1) and f01edf0 intent confirmation (Q5)** — ARC-004/LL-202 record the assessment's best reconstruction; Matt can amend either entry if the story differs.
- **README_methodology.md / MIGRATION.md / PRD-Methodology-Overview.pptx (fork-era cruft, Gap row 4)** — not in the approved plan's enumeration; deleting committed files beyond the two explicit hygiene targets felt like scope creep. Flagged for a future hygiene pass.

### Validator / readiness results (final state)

| Check | Result |
|---|---|
| `bash scripts/validate-ids.sh` | exit 1 — 127 definitions, 214 refs, 0 duplicates, 0 orphans, 87 dangling (pre-existing template range-marker/example-ID noise class; reference repo's own run also exits 1; net new from this work ±0) |
| `bash scripts/check-stage-gate.sh v0.8` | exit 0 — GATE PASSED |
| `python3 scripts/readiness.py run` | exit 2 — stage v0.8 = 39.9 BLOCK (expected: EPIC-01..09 predate readiness conventions and are never retrofitted); EPIC-10 = 87.9, EPIC-11 = 66.4 on the new template |
| `python3 scripts/validate-edges.py` (via check 4) | no-op exit 0 — `required_edges: []` by design |
| Doc-link check (CLAUDE.md, AGENTS.md, .claude/README.md, SoT.README, UNIQUE_ID_SYSTEM, LESSONS_LEARNED, EPIC_TEMPLATE, README) | all relative links resolve; zero dangling pointers |
