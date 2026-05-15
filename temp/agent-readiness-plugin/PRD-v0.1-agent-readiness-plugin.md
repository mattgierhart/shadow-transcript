# Agent Readiness Plugin for Obsidian — PRD v0.1 (Spark)

> **Status**: Draft v0.1
> **Created**: 2026-03-30
> **Author**: Pinch + Claude
> **Location**: `temp/agent-readiness-plugin/` (incubation — not part of Transcript Shadow)
> **Next milestone**: v0.2 — User/Agent Journey Mapping + Readiness Model formalization

---

## 1. Problem Statement

AI agents today receive tasks and either attempt them or fail silently. There is no structured mechanism for an agent to:

- **Assess its own readiness** before committing to work
- **Push back** on tasks it cannot complete well
- **Negotiate scope** by decomposing or deferring parts of a task
- **Signal confidence** so orchestrators and humans can route work intelligently

This creates a "just try it" culture in agent systems, leading to wasted tokens, hallucinated outputs, silent failures, and eroded trust. Agents need a **decision framework** — not just a task queue — and that framework needs to live where the knowledge already is.

Obsidian vaults are increasingly used as the coordination surface for AI-assisted workflows (PRD-driven context engineering, Zettelkasten agent memory, project knowledge bases). An Obsidian plugin can meet agents where their context already lives.

---

## 2. Target Users

| User | Role | Primary Need |
|------|------|--------------|
| **OpenClaw agents** | AI agents operating in Obsidian-backed workflows | Structured readiness assessment before task execution |
| **Other AI agents** (Claude Code, Cursor, custom) | Any agent that can read/write Obsidian vault files | Interoperable readiness signaling |
| **Human operators** | People who assign tasks to agents or review agent output | Visibility into why an agent acted, deferred, or declined |
| **Plugin developers** | Obsidian community builders | Extensible API for agent-aware plugins |

**Primary user is the agent, not the human.** The human is a stakeholder who benefits from transparency.

---

## 3. Jobs to Be Done

### Agent JTBD
1. **When** I receive a task, **I want to** assess my readiness across multiple dimensions, **so that** I commit only to work I can do well.
2. **When** I lack context or capability, **I want to** articulate what's missing, **so that** I can request it or decline gracefully.
3. **When** a task has unresolved dependencies, **I want to** signal "wait" with a clear trigger condition, **so that** I'm re-engaged at the right time.
4. **When** I'm confident in part of a task but not all of it, **I want to** decompose it and commit to the ready parts, **so that** progress isn't blocked.

### Human Operator JTBD
5. **When** I assign work to an agent, **I want to** see a readiness assessment before execution begins, **so that** I can intervene early if the agent is under-equipped.
6. **When** an agent declines or defers, **I want to** understand the specific blockers, **so that** I can resolve them or reassign.

---

## 4. Readiness Model (Draft)

The core of the plugin: a structured assessment an agent performs before committing to a task.

### 4.1 Readiness Dimensions

| Dimension | Question the Agent Asks Itself | Signal |
|-----------|-------------------------------|--------|
| **Knowledge/Context** | Do I have the information needed? Are relevant vault notes, SoT files, or external docs accessible? | `has_context` / `missing: [list]` |
| **Capability** | Can I perform the required actions? (e.g., code generation, file editing, web search, API calls) | `capable` / `limited: [list]` |
| **Tools** | Are the tools I need available and functional? | `tools_ready` / `missing_tools: [list]` |
| **Permissions/Authority** | Am I authorized to take the required actions? (file writes, git pushes, external calls) | `authorized` / `needs_approval: [list]` |
| **Dependencies** | Are upstream tasks/artifacts complete? | `deps_met` / `blocked_by: [list]` |
| **Confidence** | Given all the above, how confident am I in a good outcome? | `high` / `medium` / `low` + rationale |

### 4.2 Readiness Score

A composite score (not a single number — a structured object) that maps to a **decision**:

| Readiness State | Meaning | Agent Action |
|----------------|---------|--------------|
| `READY` | All dimensions green, confidence high | Execute now |
| `READY_WITH_CAVEATS` | Mostly ready, minor gaps identified | Execute with stated assumptions; flag caveats |
| `CLARIFY` | Key ambiguity in task definition or context | Ask clarifying questions before proceeding |
| `DECOMPOSE` | Task too large or partially blocked | Break into subtasks; execute ready parts |
| `WAIT` | Hard dependency unmet | Park task with trigger condition |
| `DECLINE` | Fundamental capability or authority gap | Push back with explanation |
| `ESCALATE` | Risk too high for autonomous action | Hand to human with full context |

### 4.3 Readiness Record Format (Draft)

Stored as a YAML frontmatter block or a structured note in the vault:

```yaml
---
type: readiness-assessment
task_id: TASK-042
agent: openclaw-v1
timestamp: 2026-03-30T14:22:00Z
decision: DECOMPOSE
confidence: medium
dimensions:
  knowledge:
    status: partial
    missing:
      - "API rate limit policy for target service"
      - "Error handling conventions in this codebase"
  capability:
    status: capable
  tools:
    status: ready
  permissions:
    status: authorized
  dependencies:
    status: partial
    blocked_by:
      - task_id: TASK-041
        description: "Database schema migration must complete first"
        trigger: "TASK-041 status changes to DONE"
subtasks_created:
  - TASK-042a: "Implement API client (READY)"
  - TASK-042b: "Add error handling (CLARIFY — need conventions)"
  - TASK-042c: "Run integration tests (WAIT — blocked by TASK-041)"
rationale: >
  Can proceed with API client implementation now. Error handling
  needs clarification on project conventions. Integration tests
  blocked until DB migration lands.
---
```

---

## 5. Blocker Taxonomy (Draft)

When an agent cannot proceed, the reason should be classifiable:

| Blocker Type | Examples | Resolution Path |
|-------------|----------|-----------------|
| **Missing Context** | File not in vault, no documentation for API, ambiguous requirement | Agent asks clarifying question; human provides doc/link |
| **Missing Capability** | Task requires image generation but agent is text-only | Reassign to capable agent or provide tool |
| **Missing Tool** | Needs git access but no CLI available | Operator enables tool or changes approach |
| **Missing Permission** | Task requires deploying to prod but agent has staging-only auth | Human grants permission or executes manually |
| **Unmet Dependency** | Upstream task incomplete, external service unavailable | Wait with trigger condition |
| **Ambiguous Scope** | "Make it better" — no measurable acceptance criteria | Push back; request specific criteria |
| **Excessive Risk** | Destructive action, irreversible state change, security-sensitive | Escalate with risk assessment |
| **Confidence Too Low** | Agent has everything but still can't produce a good result | Escalate with honest self-assessment |

---

## 6. MVP Scope

### In Scope (v1.0 Plugin)

- **Readiness Assessment API**: A structured format agents can write to and read from within an Obsidian vault
- **Decision Protocol**: The 7-state readiness model (READY through ESCALATE)
- **Blocker Records**: Structured notes that capture what's missing and what would unblock
- **Vault Integration**: Notes stored as standard Obsidian markdown with YAML frontmatter (no proprietary format)
- **Human Dashboard View**: A simple rendered view of active readiness assessments (Obsidian reading view or Dataview-compatible)
- **Agent-Neutral Schema**: The format should work for any agent that can read/write files, not just OpenClaw

### Out of Scope (MVP)

- Agent orchestration / task routing (the plugin assesses readiness; it doesn't assign work)
- Real-time agent communication (async file-based, not WebSocket/streaming)
- Plugin marketplace monetization
- Mobile Obsidian support
- Obsidian Sync conflict resolution
- Custom UI beyond basic rendering of structured notes
- Agent implementation / runtime (this is a data format + rendering plugin, not an agent framework)

---

## 7. Explicit Non-Goals

1. **Not an agent framework**: This plugin does not run agents. It provides a structured surface for agents to record and read readiness assessments.
2. **Not a task manager**: Tasks come from elsewhere (EPICs, issue trackers, human input). This plugin assesses readiness for existing tasks.
3. **Not a monetized product**: Free community plugin. No pricing tiers, no SaaS backend.
4. **Not OpenClaw-exclusive**: While OpenClaw is the first consumer, the schema and plugin should be agent-agnostic.
5. **Not a replacement for human judgment**: Escalation to humans is a first-class outcome, not a failure mode.

---

## 8. Open Questions

| # | Question | Impact | Suggested Owner |
|---|----------|--------|-----------------|
| OQ-1 | Should readiness assessments live as standalone notes or as frontmatter on task notes? | Schema design, vault organization | Design (v0.2) |
| OQ-2 | How does an agent "trigger" a reassessment when a dependency resolves? (File watcher? Polling? Human nudge?) | Architecture | Architecture (v0.4) |
| OQ-3 | Should the plugin expose a local API (localhost HTTP) for agents that can't directly write files? | Scope, complexity | Architecture (v0.4) |
| OQ-4 | What's the minimum Obsidian API surface needed? (Plugin API vs. just file conventions?) | Build complexity | Architecture (v0.4) |
| OQ-5 | How do we handle multi-agent scenarios where two agents assess the same task? | Concurrency, conflict | Design (v0.2) |
| OQ-6 | Should confidence be a numeric score (0-1) or categorical (high/medium/low)? | Interoperability, simplicity | Design (v0.2) |
| OQ-7 | Is there value in a "readiness history" per task (showing how readiness changed over time)? | Scope | v0.3 |
| OQ-8 | What is OpenClaw's current task intake format? How much adaptation is needed? | Integration | Research (v0.2) |

---

## 9. Recommended Next Steps (v0.2)

v0.2 should focus on **formalizing the readiness model and mapping agent journeys**:

1. **Agent Journey Mapping**: Walk through 3-5 concrete scenarios (OpenClaw receives a coding task, a research task, a multi-step task with dependencies) and trace the readiness assessment flow end-to-end.
2. **Schema Formalization**: Lock down the YAML schema for readiness records. Decide OQ-1 (standalone vs. frontmatter) and OQ-6 (confidence format).
3. **Blocker Taxonomy Validation**: Test the blocker types against real agent failure modes from OpenClaw usage.
4. **Obsidian Plugin Feasibility Check**: Confirm what the Obsidian plugin API supports for programmatic note creation/reading. Determine if a local API bridge (OQ-3) is needed.
5. **Name Selection**: Pick the canonical product name from the candidates list.

---

## Appendix: Design Principles

1. **Readiness is not binary** — It's a multi-dimensional assessment with nuanced outcomes.
2. **Pushback is a feature** — An agent that declines a task it can't do well is more valuable than one that tries and fails.
3. **Files are the API** — If an agent can read and write markdown files, it can use this system. No SDK required.
4. **Human-readable by default** — Every structured record should make sense to a human reading it in Obsidian.
5. **Composable, not monolithic** — The readiness model should work standalone or integrate into larger orchestration systems.
