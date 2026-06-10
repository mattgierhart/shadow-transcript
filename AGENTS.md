---
title: "Codex Agent Operating Guide"
updated: "2026-06-09"
authority: "PRD Led Context Engineering"
template_version: "3.2.0"
---

# AGENTS.md — Agent Operating Guide

> **Mission**: Build software in lockstep with the PRD Version Lifecycle.
> **Authority**: Load `README.md` → `PRD.md` → `AGENTS.md` → Active EPIC.
> **Core Rule**: If it's not in the ID Graph (Specs), it doesn't exist.

This file mirrors [`CLAUDE.md`](CLAUDE.md) for Codex CLI sessions and stays in lockstep with it.
Codex does not auto-load rule files — **read `.claude/rules/01…08` at session start**; they are
the operating rules (session protocols, document ecosystem, documentation discipline, coding
standards, lifecycle gates + Codex Gate, cross-agent communication, readiness, skill modes).

## Repo-Local Notes

- **Two-layer workspace** (ARC-004 in `SoT/SoT.TECHNICAL_DECISIONS.md`): skills/hooks/agent
  definitions are provided by the MLG.Github workspace root, not this repo. Local `.claude/`
  carries only the domain profile (ID registry), rules, agent MEMORY.md files, and a settings stub.
- **Codex Gate**: you are the reviewer in this repo's mandatory pre-close gate
  (`.claude/rules/05-lifecycle-gates.md`, LL-001). Expect single-ask prompts with length caps;
  answer with P0/P1/P2 + file:line, no fixes unless asked.
- **Lessons travel**: read the active EPIC's Cumulative Carry-Forward block before touching code;
  durable lessons live in `SoT/SoT.LESSONS_LEARNED.md` (LL-).
- **Traceability**: every major code unit carries `// @implements <ID>`; tests carry `@verifies`
  (`.claude/rules/04-coding-standards.md`).

## Quick Reference

- **Lifecycle Guide**: [`README.md`](README.md)
- **ID System**: [`SoT/SoT.UNIQUE_ID_SYSTEM.md`](SoT/SoT.UNIQUE_ID_SYSTEM.md)
- **SoT Index**: [`SoT/SoT.README.md`](SoT/SoT.README.md)
- **Lessons Learned**: [`SoT/SoT.LESSONS_LEARNED.md`](SoT/SoT.LESSONS_LEARNED.md)
- **EPIC Template**: [`epics/EPIC_TEMPLATE.md`](epics/EPIC_TEMPLATE.md)
- **Active Work**: [`epics/`](epics/)
- **Domain Profile**: [`.claude/domain-profile.yaml`](.claude/domain-profile.yaml)
- **Rules**: [`.claude/rules/`](.claude/rules/)
- **Readiness Protocol**: [`docs/READINESS_PROTOCOL.md`](docs/READINESS_PROTOCOL.md)

**When in doubt, follow the Source of Truth.**
