# .claude Directory — shadow-transcript (repo-local layer)

This repo runs under the **MLG.Github two-layer workspace architecture** (ARC-004 in
[`SoT/SoT.TECHNICAL_DECISIONS.md`](../SoT/SoT.TECHNICAL_DECISIONS.md)):

- **Workspace layer** (`MLG.Github/.claude/`) provides all skills (prd-v*, ghm-*, codex-*),
  hooks, and agent definitions. They are available when sessions launch from the workspace root.
  None of that tooling is duplicated here — the local copies were deliberately removed on
  2026-04-24 (commit `f01edf0`). **Never re-copy skills/hooks/AGENT.md into this repo.**
- **Repo layer** (this directory) carries only repo-specific data:

```text
.claude/
├── domain-profile.yaml   # THIS repo's ID-prefix registry (registry data, not tooling).
│                         # Consumed by scripts/validate-ids.sh, validate-edges.py, readiness.
├── rules/                # Operating rules, auto-loaded by Claude Code (01-08):
│   ├── 01-session-protocols.md
│   ├── 02-document-ecosystem.md
│   ├── 03-documentation-discipline.md
│   ├── 04-coding-standards.md
│   ├── 05-lifecycle-gates.md        # includes the local Codex Gate (LL-001)
│   ├── 06-cross-agent-communication.md
│   ├── 07-readiness-protocol.md
│   └── 08-skill-execution-modes.md
├── agents/               # MEMORY.md only (project knowledge harvest targets).
│   ├── horizon/  studio/  devlab/  metro/
│   └── (definitions/AGENT.md live at the workspace root; this repo has run
│        single-persona to date — see LL-202)
├── settings.json         # Minimal per-repo override stub
└── settings.local.json   # Machine-local permissions (gitignored)
```

## Notes

- **Standalone use**: cloning this repo outside the MLG.Github workspace loses skills and hooks.
  Run the workspace `/localize` command to copy the methodology in if that ever matters.
- **Validators stay local** (`scripts/validate-ids.sh`, `scripts/validate-edges.py`,
  `scripts/readiness.py`) so CI and the portfolio readiness loop work without the workspace.
- **History**: this file previously described the fork-era local skills/hooks/agents tree
  (24 skills, 3 hooks, WERK agent). That structure was removed in `f01edf0`; see git history
  if you need it.
