---
version: 1.0
purpose: Source of Truth for customer feedback, user research insights, and validated learnings.
id_prefix: CFD-XXX
last_updated: 2026-03-11
authority: This is a SoT file - IDs here are referenced by PRD.md, SoT.USER_JOURNEYS.md, EPICs
---

# Customer Feedback (SoT File)

> **Purpose**: Capture durable insights from customer feedback, user research, and validated learnings.
> **ID Prefix**: CFD-XXX
> **Status**: Active SoT file
> **Cross-References**: Referenced by PRD.md, SoT.USER_JOURNEYS.md, SoT.BUSINESS_RULES.md

## Navigation by Category

**User Research** (CFD-001 to CFD-099):

- [CFD-001](#cfd-001-cloud-meeting-tools-force-privacy-tradeoffs) - Cloud meeting tools force privacy tradeoffs
- [CFD-002](#cfd-002-no-local-first-transcription-with-diarization) - No local-first transcription with diarization
- [CFD-003](#cfd-003-obsidian-users-want-native-meeting-notes) - Obsidian users want native meeting notes
- [CFD-004](#cfd-004-notion-recording-lock-in-frustration) - Notion recording lock-in frustration

**Value Hypotheses** (CFD-101 to CFD-199):

- [CFD-101](#cfd-101-local-processing-eliminates-privacy-anxiety) - Local processing eliminates privacy anxiety
- [CFD-102](#cfd-102-automated-speaker-labeled-transcripts-save-time) - Automated speaker-labeled transcripts save time
- [CFD-103](#cfd-103-obsidian-native-export-preserves-workflow) - Obsidian-native export preserves workflow

---

## CFD-001: Cloud Meeting Tools Force Privacy Tradeoffs

**ID**: CFD-001
**Category**: User Research
**Status**: Analyzed
**Priority**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11
**Reported By**: Knowledge workers using Notion/Otter/Fireflies

### Feedback Summary

**What Users Said**: "I want meeting transcripts but I don't want my confidential conversations uploaded to third-party servers. Every tool requires cloud processing."

**User Context**:

- User segment: Privacy-conscious professionals
- First reported: 2026-03-11
- Evidence tier: Operator experience + community sentiment

### Problem Statement

**Current Behavior**: Meeting transcription tools (Notion AI, Otter.ai, Fireflies) upload audio to cloud servers for processing.
**Expected Behavior**: Transcription should happen locally without data leaving the machine.
**Impact**: Users either skip transcription entirely or accept privacy risks for convenience.

**Pain Level**: High

### Related IDs

- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - Local-only processing rule
- [FEA-001 in PRD](../PRD.md) - Audio capture feature

### Product Decision

**Decision**: Implement
**Decision Date**: 2026-03-11
**Rationale**: Core product differentiator — local-only processing is the foundation.

---

## CFD-002: No Local-First Transcription with Diarization

**ID**: CFD-002
**Category**: User Research
**Status**: Analyzed
**Priority**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11
**Reported By**: Technical users exploring whisper.cpp and related tools

### Feedback Summary

**What Users Said**: "I can run Whisper locally for transcription, but there's no simple way to also get speaker labels. I have to cobble together multiple tools and scripts."

**User Context**:

- User segment: Technical knowledge workers
- Evidence tier: Operator experience

### Problem Statement

**Current Behavior**: Local transcription (whisper.cpp) exists but lacks integrated speaker diarization. Users must manually combine tools.
**Expected Behavior**: A single app that transcribes and identifies speakers locally.
**Impact**: Only highly technical users can achieve local transcription+diarization, and it requires significant setup.

**Pain Level**: High

### Related IDs

- [FEA-002 in PRD](../PRD.md) - Transcription feature
- [FEA-003 in PRD](../PRD.md) - Speaker diarization feature

### Product Decision

**Decision**: Implement
**Decision Date**: 2026-03-11
**Rationale**: Integrating transcription + diarization into one app is the core value proposition.

---

## CFD-003: Obsidian Users Want Native Meeting Notes

**ID**: CFD-003
**Category**: User Research
**Status**: Analyzed
**Priority**: Medium
**Created**: 2026-03-11
**Last Updated**: 2026-03-11
**Reported By**: Obsidian community users

### Feedback Summary

**What Users Said**: "I use Obsidian for all my notes. Meeting transcripts from other tools end up in a different silo. I want them directly in my vault as markdown."

**User Context**:

- User segment: Obsidian power users
- Evidence tier: Community sentiment

### Problem Statement

**Current Behavior**: Meeting transcripts live in separate apps (Notion, Otter dashboard). Manual copy-paste to Obsidian.
**Expected Behavior**: Transcripts export directly into Obsidian vault as properly formatted markdown.
**Impact**: Broken workflow; meeting notes disconnected from the rest of the knowledge base.

**Pain Level**: Medium

### Related IDs

- [FEA-005 in PRD](../PRD.md) - Obsidian export feature
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - Obsidian integration

### Product Decision

**Decision**: Implement
**Decision Date**: 2026-03-11
**Rationale**: Obsidian export is the primary output channel. File-based integration is simple and reliable.

---

## CFD-004: Notion Recording Lock-in Frustration

**ID**: CFD-004
**Category**: User Research
**Status**: Analyzed
**Priority**: Medium
**Created**: 2026-03-11
**Last Updated**: 2026-03-11
**Reported By**: Notion users migrating to Obsidian

### Feedback Summary

**What Users Said**: "Notion's meeting recording is convenient but locks me into their ecosystem. I can't easily extract or reuse the transcripts in my preferred tools."

**User Context**:

- User segment: Users transitioning from Notion to Obsidian
- Evidence tier: Operator experience

### Problem Statement

**Current Behavior**: Notion meeting recordings are tied to Notion's ecosystem with limited export options.
**Expected Behavior**: Meeting transcripts should be portable, standard markdown files.
**Impact**: Vendor lock-in prevents workflow flexibility.

**Pain Level**: Medium

### Related IDs

- [CFD-001](#cfd-001-cloud-meeting-tools-force-privacy-tradeoffs) - Related privacy concern
- [FEA-004 in PRD](../PRD.md) - Markdown output feature

### Product Decision

**Decision**: Implement
**Decision Date**: 2026-03-11
**Rationale**: Markdown-first output ensures portability and no vendor lock-in.

---

## CFD-101: Local Processing Eliminates Privacy Anxiety

**ID**: CFD-101
**Category**: Value Hypothesis
**Status**: Analyzed
**Priority**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Feedback Summary

**What Users Said**: Value hypothesis — users will choose a local-only tool over cloud alternatives specifically because their meeting audio never leaves their machine.

**User Context**:

- User segment: Privacy-conscious professionals, legal, medical, executive
- Evidence tier: Hypothesis (to be validated)

### Related IDs

- [CFD-001](#cfd-001-cloud-meeting-tools-force-privacy-tradeoffs) - driven-by
- [BR-101](SoT.BUSINESS_RULES.md#br-101-local-only-processing) - implements
- [BR-102](SoT.BUSINESS_RULES.md#br-102-no-persistent-audio-storage) - implements

### Product Decision

**Decision**: Implement
**Decision Date**: 2026-03-11
**Rationale**: Privacy-first is a non-negotiable product principle.

---

## CFD-102: Automated Speaker-Labeled Transcripts Save Time

**ID**: CFD-102
**Category**: Value Hypothesis
**Status**: Analyzed
**Priority**: High
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Feedback Summary

**What Users Said**: Value hypothesis — speaker-labeled transcripts reduce post-meeting processing time by eliminating manual attribution of who said what.

**User Context**:

- User segment: Anyone who takes meeting notes
- Evidence tier: Hypothesis (to be validated)

### Related IDs

- [CFD-002](#cfd-002-no-local-first-transcription-with-diarization) - driven-by
- [FEA-003 in PRD](../PRD.md) - implements

### Product Decision

**Decision**: Implement
**Decision Date**: 2026-03-11
**Rationale**: Diarization is what differentiates this from a simple Whisper wrapper.

---

## CFD-103: Obsidian-Native Export Preserves Workflow

**ID**: CFD-103
**Category**: Value Hypothesis
**Status**: Analyzed
**Priority**: Medium
**Created**: 2026-03-11
**Last Updated**: 2026-03-11

### Feedback Summary

**What Users Said**: Value hypothesis — direct export to Obsidian vault eliminates the friction of manual copy-paste and keeps meeting notes connected to the user's knowledge graph.

**User Context**:

- User segment: Obsidian users
- Evidence tier: Hypothesis (to be validated)

### Related IDs

- [CFD-003](#cfd-003-obsidian-users-want-native-meeting-notes) - driven-by
- [FEA-005 in PRD](../PRD.md) - implements
- [INT-001](SoT.INTEGRATIONS.md#int-001-obsidian-vault-export) - implements

### Product Decision

**Decision**: Implement
**Decision Date**: 2026-03-11
**Rationale**: Obsidian export is the primary output target for MVP.

---

## Deprecated Entries

_No deprecated entries._

---

## Cross-Reference Index

**Feedback by Journey**:

- UJ-001 feedback: CFD-001, CFD-002, CFD-004
- UJ-002 feedback: CFD-003

**Feedback by Status**:

- Actioned: CFD-001, CFD-002, CFD-003, CFD-004
- Value Hypotheses: CFD-101, CFD-102, CFD-103

---

## Update Protocol

### When to Add New CFD-XXX IDs

1. **User Research**: Validated insight from research sessions
2. **Feature Request**: Request from multiple users or key accounts
3. **Bug Report**: User-reported issue with product impact
4. **General Feedback**: Pattern observed across multiple interactions

### Bidirectional Reference Checklist

When adding a new CFD-XXX:

- [ ] Link to affected UJ-XXX in SoT.USER_JOURNEYS.md
- [ ] Update PRD.md if creating new feature to address
- [ ] Update SoT.BUSINESS_RULES.md if rule change needed
- [ ] Update EPIC if feedback relates to active work

---

*End of SoT.customer_feedback.md - Authoritative source for all CFD-XXX IDs*
