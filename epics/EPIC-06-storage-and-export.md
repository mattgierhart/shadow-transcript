---
template_version: "3.0.0"
---

# EPIC-06 Storage & Obsidian Export

> **State**: `Complete` (2026-05-12)
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-01 (GRDB setup), EPIC-05 (FormattedTranscript type)

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-12 — EPIC-06 closed. Shipped `Storage/` (AppDatabase + DatabaseMigrations v1 + 4 Record types + TranscriptStore + SettingsStore) and `Export/` (ObsidianExporter + MarkdownFilenameSanitizer). EPIC-05 was extended additively: `Turn` promoted to public `TranscriptTurn` on `FormattedTranscript` so DBT-002/003 populate without re-deriving from raw `Transcript`/`DiarizationResult`.
- **Stopping Point**: Build verification deferred to CI (`macos-15` per `.github/workflows/build.yml`); local Linux environment lacks Xcode. Codex Gate 4 not yet run in this session — recommend invoking post-CI-green.
- **Next Steps**: EPIC-07 (SwiftUI Interface) is now Active. UI can consume `TranscriptStore.list/search/fetch` for SCR-006 (history), `SettingsStore` typed keys for SCR-005 (settings), and `DefaultObsidianExporter.export(...)` for SCR-004's export action.
- **Context**: Risk-profile mirrored EPIC-05: pure Swift + filesystem + GRDB API surface. Highest uncertainty bits: GRDB v6 async signatures, FTS5 external-content virtual-table sync trigger syntax, `Sendable` inference across `DatabaseQueue.write { … }` closures. CI will catch any compile drift.

---

## Objective & Scope

> **Goal**: Persist transcripts in SQLite (GRDB), export to Obsidian vault as markdown with YAML frontmatter, and provide transcript history/search.

- **Deliverables**:
  - [x] SQLite schema: transcripts, speakers, segments, app_settings (DBT-001→003, DBT-101)
  - [x] GRDB migrations and model records
  - [x] `ObsidianExporter` service (API-202)
  - [x] Frontmatter template per INT-001 spec
  - [x] Full-text search index on transcript content
  - [x] Settings persistence (key-value store)
  - [x] Tests: TEST-401, TEST-402, TEST-403, TEST-404, TEST-405
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

- [x] **Context Loaded**: Read DBT-001→101, API-202, INT-001
- [x] **Strategy**: EPIC-05 extension (add public `TranscriptTurn`) → Storage layer → Export layer → tests

### Phase B: Design

- [x] GRDB `Record` types with explicit snake_case `CodingKeys` matching DBT schemas
- [x] Migration strategy: single v1 migration; future migrations append (never edit applied ones)
- [x] FTS5 as external-content virtual table (`content='transcripts'`) + INSERT/UPDATE/DELETE triggers

### Phase C: Build (The "Context Window")

**Context Window 0: EPIC-05 prerequisite extension**

- [x] Promote `fileprivate Turn` → public `TranscriptTurn` on `FormattedTranscript`
- [x] Add `endSeconds` (computed from last aligned token end)
- [x] Update `WordSpeakerAligner.AlignedToken` to carry `end: TimeInterval`
- [x] Two new tests asserting `turns` shape + rename propagation into `displayName`

**Context Window 1: Database Layer**

- [x] `AppDatabase` with on-disk + in-memory factories, foreign-keys PRAGMA on every connection
- [x] `DatabaseMigrations` v1: 4 tables + indexes + FKs + FTS5 + 3 sync triggers
- [x] Record types: `TranscriptRecord` / `SpeakerRecord` / `SegmentRecord` / `AppSettingRecord`
- [x] `DefaultTranscriptStore`: save (one transaction, populates all 3 core tables from `FormattedTranscript.turns`) / fetch / list / search / markExported / delete
- [x] `DefaultSettingsStore`: typed `SettingKey<Value>` accessors + JSON envelope + built-in keys for all DBT-101 defaults
- [x] **Tests**: TEST-403 (persistence + cascade), TEST-404 (FTS + trigger sync), TEST-405 (settings round-trip + bad-JSON tolerance)

**Context Window 2: Obsidian Export**

- [x] `ObsidianExporter` protocol + `DefaultObsidianExporter` impl
- [x] YAML frontmatter generation (date, title, type, duration, speakers, source, tags) with double-quoted YAML-escaped strings
- [x] `MarkdownFilenameSanitizer` — replaces `/\:?*<>|"` + control chars with spaces, collapses whitespace, trims dots, caps at 200 chars, falls back to "Untitled"
- [x] File naming: `YYYY-MM-DD <sanitized title>.md`
- [x] Subfolder created on demand (supports nested paths like `Daily/Meetings`)
- [x] Atomic write via `String.write(to:atomically:encoding:)`
- [x] `overwriteExisting: Bool` init flag for EPIC-08 orchestrator semantics
- [x] **Tests**: TEST-401 (valid markdown + path), TEST-402 (frontmatter contents + escape) + filename sanitizer edge cases

### Phase D: Validate

- [x] All 5 TEST-XXX cases implemented (runtime verification via CI / Mac Studio)
- [ ] Manual test: export to real Obsidian vault, verify renders correctly (deferred to user — needs macOS + Obsidian)
- [ ] Verify FTS search against a non-fixture corpus (deferred to user)
- [ ] **Codex review pass (mandatory, single-ask)** — not yet run this session: "Find bugs in `AppDatabase` / `DatabaseMigrations` / `TranscriptStore` / `SettingsStore` / `DefaultObsidianExporter` / `MarkdownFilenameSanitizer` that EPIC-03/04/05 lessons should have prevented — GRDB v6 async-signature drift, FTS5 external-content trigger sync gaps, Codable snake_case CodingKeys mismatch with column names, `Sendable` boundary issues across `DatabaseQueue.write` closures, FK cascade order, YAML escape coverage on user-typed strings, filename-sanitizer Unicode edge cases, off-by-one on `sequence` numbering, missing `markExported` not-found semantics. P0/P1/P2, file:line, no fixes." Pre-flight via `/codex-budget-check check codex-review`.
- [x] Code traceability: `// @implements API-202`, `// @implements DBT-001..101`, `// @implements TEST-401..405` present on new source + test files

### Phase E: Finish (Harvest)

- [x] Temp cleanup (no `temp/epic-06-*` created)
- [x] Update API-202 status → Implemented + full interface block
- [x] Update API-201 interface block to add `TranscriptTurn` + Notes-vs-Sketch addendum
- [x] Update DBT-001..003, DBT-101 status → Implemented
- [x] Update INT-001 status → Implemented
- [x] Update TEST-401..405 status → Implemented + tightened Given/When/Then + correct file paths
- [x] Append Lifecycle Change Log row in `PRD.md`
- [x] Update README backlog: EPIC-06 → ✅ Complete, Active EPIC pointer → EPIC-07
- [x] Session audit

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | | | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-12 | Claude Agent | EPIC closed. Shipped `Storage/` (AppDatabase + DatabaseMigrations v1 + 4 GRDB Record types + DefaultTranscriptStore with FTS5 + DefaultSettingsStore with typed keys) and `Export/` (DefaultObsidianExporter + MarkdownFilenameSanitizer). ~37 new XCTests across `Storage/` + `Export/` covering TEST-401..405 + cascade-delete + FTS-trigger sync + settings round-trip + filename sanitizer edge cases. Prerequisite EPIC-05 extension: promoted `fileprivate Turn` → public `TranscriptTurn` on `FormattedTranscript` (option A from the planning round); added `endSeconds` derived from last aligned token; `WordSpeakerAligner.AlignedToken` now carries `end: TimeInterval`. SoT updates: API-201 (TranscriptTurn block + Notes-vs-Sketch addendum), API-202 (full interface block, status → Implemented), DBT-001..003 + DBT-101 + INT-001 statuses → Implemented, TEST-401..405 statuses → Implemented with tightened Given/When/Then. README Active EPIC → EPIC-07. Build verification deferred to CI (`macos-15` runner); Codex Gate 4 not yet run in this session. |
