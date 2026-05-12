---
version: 1.0
purpose: Source of Truth for local database schema and data model specifications.
id_prefix: DBT-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by PRD.md, SoT.API_CONTRACTS.md, SoT.USER_JOURNEYS.md, EPICs
---

# Data Model (SoT File)

> **Purpose**: Local SQLite database tables for Transcript Shadow.
> **ID Prefix**: DBT-XXX
> **Status**: Active SoT file
> **Note**: This is a local-only SQLite database stored in the app's Application Support directory. No cloud sync.

## Navigation by Category

**Core Tables** (DBT-001 to DBT-099):

- [DBT-001](#dbt-001-transcripts) - Transcripts
- [DBT-002](#dbt-002-speakers) - Speakers
- [DBT-003](#dbt-003-segments) - Transcript Segments

**Settings Tables** (DBT-101 to DBT-199):

- [DBT-101](#dbt-101-app-settings) - App Settings

---

## DBT-001: Transcripts

**ID**: DBT-001
**Category**: Core
**Status**: Implemented (EPIC-06, 2026-05-12)
**Created**: 2026-03-11
**Last Updated**: 2026-05-12

### Purpose

Store transcript metadata and the full markdown content. One row per completed transcription.

### Columns

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | TEXT (UUID) | Yes | Primary key |
| `title` | TEXT | Yes | Meeting title (auto-generated, user-editable) |
| `date` | TEXT (ISO8601) | Yes | Meeting date |
| `duration_seconds` | INTEGER | Yes | Recording duration in seconds |
| `speaker_count` | INTEGER | Yes | Number of identified speakers |
| `markdown_content` | TEXT | Yes | Full formatted transcript (markdown) |
| `model_used` | TEXT | Yes | Whisper model name used |
| `exported_path` | TEXT | No | File path if exported to Obsidian |
| `created_at` | TEXT (ISO8601) | Yes | Record creation timestamp |
| `updated_at` | TEXT (ISO8601) | Yes | Last update timestamp |

### Key Indexes

- Primary key on `id`
- Index on `date` for chronological listing
- Full-text search index on `markdown_content` for search

### Related IDs

- [API-201](SoT.API_CONTRACTS.md#api-201-transcript-formatter) - Produces content
- [API-202](SoT.API_CONTRACTS.md#api-202-obsidian-exporter) - Reads for export
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Review journey
- [SCR-006](SoT.USER_JOURNEYS.md#scr-006-transcript-history) - History view
- [DBT-002](#dbt-002-speakers) - Related speakers
- [DBT-003](#dbt-003-segments) - Related segments

---

## DBT-002: Speakers

**ID**: DBT-002
**Category**: Core
**Status**: Implemented (EPIC-06, 2026-05-12)
**Created**: 2026-03-11
**Last Updated**: 2026-05-12

### Purpose

Store speaker identities for each transcript. Maps auto-generated speaker IDs to user-assigned names.

### Columns

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | TEXT (UUID) | Yes | Primary key |
| `transcript_id` | TEXT (UUID) | Yes | FK to transcripts |
| `speaker_key` | TEXT | Yes | Auto-assigned key (e.g., "SPEAKER_00") |
| `display_name` | TEXT | Yes | User-assigned name (default: "Speaker 1") |
| `color_index` | INTEGER | Yes | Index into speaker color palette |
| `speaking_time_seconds` | REAL | No | Total speaking duration |

### Key Indexes

- Primary key on `id`
- Index on `transcript_id` for lookup
- Unique constraint on (`transcript_id`, `speaker_key`)

### Foreign Keys

- **References**: DBT-001 (transcript_id → id) ON DELETE CASCADE

### Related IDs

- [DBT-001](#dbt-001-transcripts) - Parent transcript
- [DES-101](SoT.DESIGN_COMPONENTS.md#des-101-speaker-label) - Speaker label component
- [UJ-002](SoT.USER_JOURNEYS.md#uj-002-review-and-export-transcript) - Speaker rename

---

## DBT-003: Segments

**ID**: DBT-003
**Category**: Core
**Status**: Implemented (EPIC-06, 2026-05-12)
**Created**: 2026-03-11
**Last Updated**: 2026-05-12

### Purpose

Store individual transcript segments (speaker turns) with timestamps. Enables structured display and editing.

### Columns

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | TEXT (UUID) | Yes | Primary key |
| `transcript_id` | TEXT (UUID) | Yes | FK to transcripts |
| `speaker_id` | TEXT (UUID) | Yes | FK to speakers |
| `start_time` | REAL | Yes | Segment start (seconds) |
| `end_time` | REAL | Yes | Segment end (seconds) |
| `text` | TEXT | Yes | Spoken text content |
| `sequence` | INTEGER | Yes | Display order |

### Key Indexes

- Primary key on `id`
- Index on `transcript_id` for lookup
- Index on (`transcript_id`, `sequence`) for ordered display

### Foreign Keys

- **References**: DBT-001 (transcript_id → id) ON DELETE CASCADE
- **References**: DBT-002 (speaker_id → id) ON DELETE CASCADE

### Related IDs

- [DBT-001](#dbt-001-transcripts) - Parent transcript
- [DBT-002](#dbt-002-speakers) - Speaker identity
- [DES-003](SoT.DESIGN_COMPONENTS.md#des-003-transcript-block) - Display component
- [API-201](SoT.API_CONTRACTS.md#api-201-transcript-formatter) - Produces segments

---

## DBT-101: App Settings

**ID**: DBT-101
**Category**: Settings
**Status**: Implemented (EPIC-06, 2026-05-12)
**Created**: 2026-03-11
**Last Updated**: 2026-05-12

### Purpose

Store user preferences. Key-value store for app configuration.

### Columns

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `key` | TEXT | Yes | Setting key (primary key) |
| `value` | TEXT | Yes | Setting value (JSON-encoded) |
| `updated_at` | TEXT (ISO8601) | Yes | Last update |

### Default Settings

| Key | Default Value | Description |
|-----|---------------|-------------|
| `audio_input_device` | system default | Selected microphone |
| `capture_system_audio` | `true` | Enable system audio capture |
| `obsidian_vault_path` | `null` | Path to Obsidian vault |
| `obsidian_subfolder` | `"Meetings"` | Subfolder within vault |
| `whisper_model` | `"base.en"` | Selected Whisper model |
| `auto_export` | `false` | Auto-export after processing |

### Related IDs

- [SCR-005](SoT.USER_JOURNEYS.md#scr-005-settings-view) - Settings UI
- [UJ-003](SoT.USER_JOURNEYS.md#uj-003-configure-app-settings) - Settings journey

---

## Deprecated Tables

_No deprecated tables._

---

## Cross-Reference Index

**Tables by API**:

- API-201 writes: DBT-001, DBT-002, DBT-003
- API-202 reads: DBT-001

**Tables by Journey**:

- UJ-001 writes: DBT-001, DBT-002, DBT-003
- UJ-002 reads: DBT-001, DBT-002, DBT-003
- UJ-003 writes: DBT-101

---

## Update Protocol

### When to Add New DBT-XXX IDs

1. **New Table**: Core data entity for the product
2. **New View**: Denormalized read model
3. **Schema Change**: New columns or constraints

### Bidirectional Reference Checklist

When adding a new DBT-XXX:

- [ ] Update SoT.API_CONTRACTS.md "Related IDs" section
- [ ] Update SoT.USER_JOURNEYS.md if journey uses this data
- [ ] Update SoT.BUSINESS_RULES.md if constraint enforces rule
- [ ] Update SoT.TESTING.md with schema tests
- [ ] Update EPIC Section 2 "Context & IDs" list

---

*End of SoT.DATA_MODEL.md - Authoritative source for all DBT-XXX IDs*
