# Lifecycle Gates

- **Do Not Skip**: Verify the Gate Checklist in `PRD.md` or `README.md` (PRD Lifecycle) before advancing.
- **Blockers**: If a gate cannot be passed, update the EPIC and STOP.

## Codex Gate (mandatory before every EPIC close)

> Local methodology extension, canonized 2026-05-09 (commit `b2608cc`). Every gated EPIC since EPIC-02 has shipped with a Codex pass that surfaced real bugs (4+6+3+3+10+6+4 findings through EPIC-08, including a pre-existing `AsyncTaskQueue` race). See [LL-001](../../SoT/SoT.LESSONS_LEARNED.md).

- **When**: EPIC Phase D, before close. If local build verification is impossible (no Mac), run it post-CI-green.
- **Single-ask discipline**: pose Codex ONE specific, scoped question with an explicit length cap (e.g. "Find bugs in X that EPIC-03/04 lessons should have prevented — P0/P1/P2, file:line, no fixes"). Never "review the whole module."
- **Pre-flight**: `/codex-budget-check` before the call; use the workspace `/codex-review` skill, not raw codex.
- **Resolution**: P0/P1 findings are resolved before the EPIC closes; deferred P2s are documented in the EPIC's Agent Observations with an owner EPIC.
- **Plan it early**: sketch the single-ask prompt at the bottom of the EPIC file during Phase A (see EPIC-07/08 for the pattern).
