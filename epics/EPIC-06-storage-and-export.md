---
template_version: "3.0.0"
---

# EPIC-06 Storage & Obsidian Export

> **State**: `Planned`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-01 (GRDB setup), EPIC-05 (FormattedTranscript type)

---

## Session State (The "Brain Dump")

- **Last Action**: EPIC created during v0.7 gate entry
- **Stopping Point**: N/A — not yet started
- **Next Steps**: Implement GRDB schema, then Obsidian exporter
- **Context**: Database can start as soon as EPIC-01 provides GRDB dependency

---

## Objective & Scope

> **Goal**: Persist transcripts in SQLite (GRDB), export to Obsidian vault as markdown with YAML frontmatter, and provide transcript history/search.

- **Deliverables**:
  - [ ] SQLite schema: transcripts, speakers, segments, app_settings (DBT-001→003, DBT-101)
  - [ ] GRDB migrations and model records
  - [ ] `ObsidianExporter` service (API-202)
  - [ ] Frontmatter template per INT-001 spec
  - [ ] Full-text search index on transcript content
  - [ ] Settings persistence (key-value store)
  - [ ] Tests: TEST-401, TEST-402, TEST-403, TEST-404, TEST-405
- **Out of Scope**: Transcript history UI (EPIC-07), auto-export toggle logic

---

## Context & IDs

- **APIs**: API-202
- **Data Model**: DBT-001, DBT-002, DBT-003, DBT-101
- **Integrations**: INT-001
- **Tech**: TECH-005, TECH-007
- **Business Rules**: BR-301, BR-302
- **Features**: FEA-005, FEA-006
- **Tests**: TEST-401, TEST-402, TEST-403, TEST-404, TEST-405

---

## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: Read DBT-001→101, API-202, INT-001
- [ ] **Strategy**: Database first, then exporter, then search

### Phase B: Design

- [ ] GRDB Record types matching DBT-XXX schemas
- [ ] Migration strategy (version 1 creates all tables)

### Phase C: Build (The "Context Window")

**Context Window 1: Database Layer**

- [ ] GRDB database setup in Application Support directory
- [ ] Migration: create transcripts, speakers, segments, app_settings tables
- [ ] Record types: Transcript, Speaker, Segment, AppSetting
- [ ] FTS5 index on `markdown_content`
- [ ] **Test**: TEST-403 (persistence), TEST-404 (FTS), TEST-405 (settings)

**Context Window 2: Obsidian Export**

- [ ] `ObsidianExporter` protocol + implementation
- [ ] YAML frontmatter generation (date, type, duration, speakers, source, tags)
- [ ] File naming: `YYYY-MM-DD Meeting Title.md`
- [ ] Subfolder creation if needed
- [ ] **Test**: TEST-401 (valid markdown), TEST-402 (valid YAML)

### Phase D: Validate

- [ ] All 5 TEST-XXX cases pass
- [ ] Manual test: export to real Obsidian vault, verify renders correctly
- [ ] Verify FTS search finds expected transcripts
- [ ] Code traceability: `// @implements API-202`, `// @implements DBT-001`

### Phase E: Finish (Harvest)

- [ ] Temp cleanup
- [ ] Update API-202, DBT-XXX statuses
- [ ] Session audit

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | | | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
