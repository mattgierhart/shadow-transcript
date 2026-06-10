---
title: "CLAUDE Agent Operating Guide"
updated: "2026-06-09"
authority: "PRD Led Context Engineering"
template_version: "3.2.0"
---

# CLAUDE.md — Agent Operating Guide

> **Mission**: Build software in lockstep with the PRD Version Lifecycle.
> **Authority**: Load `README.md` → `PRD.md` → `CLAUDE.md` → Active EPIC.
> **Core Rule**: If it's not in the ID Graph (Specs), it doesn't exist.

Rules are loaded automatically from `.claude/rules/*.md`.

## Repo-Local Notes

- **Two-layer workspace** (ARC-004): skills, hooks, and agent definitions are provided by the
  MLG.Github workspace root, NOT this repo. Local `.claude/` carries only the domain profile
  (ID registry), rules, agent MEMORY.md files, and a settings stub. Never re-copy
  skills/hooks/AGENT.md into this repo.
- **Codex Gate**: every EPIC closes through a mandatory single-ask Codex review
  (rule 05, LL-001). Plan the prompt during Phase A.
- **Lessons travel**: read the active EPIC's Cumulative Carry-Forward block before touching
  code; durable lessons live in `SoT/SoT.LESSONS_LEARNED.md` (LL-).

## Quick Reference

- **Lifecycle Guide**: [`README.md`](README.md)
- **ID System**: [`SoT/SoT.UNIQUE_ID_SYSTEM.md`](SoT/SoT.UNIQUE_ID_SYSTEM.md)
- **SoT Index**: [`SoT/SoT.README.md`](SoT/SoT.README.md)
- **Lessons Learned**: [`SoT/SoT.LESSONS_LEARNED.md`](SoT/SoT.LESSONS_LEARNED.md)
- **EPIC Template**: [`epics/EPIC_TEMPLATE.md`](epics/EPIC_TEMPLATE.md)
- **Active Work**: [`epics/`](epics/)
- **Domain Profile**: [`.claude/domain-profile.yaml`](.claude/domain-profile.yaml)
- **Rules**: [`.claude/rules/`](.claude/rules/)
- **Agent Memory**: [`.claude/agents/`](.claude/agents/) (memory-only; definitions live at workspace root)
- **Readiness Protocol**: [`docs/READINESS_PROTOCOL.md`](docs/READINESS_PROTOCOL.md)

**When in doubt, follow the Source of Truth.**
