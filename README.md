---
template_version: "3.0.0"
---

# Transcript Shadow — Product README

> **Status**: Active
> **Current PRD Version**: v0.7 (See `PRD.md`)
> **Active EPIC**: EPIC-06 — Storage & Obsidian Export (EPIC-05 closed 2026-05-12 with `TranscriptFormatter` + `DefaultTranscriptFormatter` + `WordSpeakerAligner` + 4 in-code fixtures and ~17 new XCTests covering TEST-301/302/303 + straddle/silence/empty-words/zero-segments/invalid-segment edge cases; build verification deferred to CI) (See `epics/`)

---

<!-- SECTION: quick-navigation -->
## 1. Quick Navigation

| File                         | Purpose                                                                    |
| ---------------------------- | -------------------------------------------------------------------------- |
| **[`PRD.md`](PRD.md)**       | **Product Definition**. The product definition (Progressive PRD).          |
| **[`CLAUDE.md`](CLAUDE.md)** | **Agent Instructions**. The agent's operating instructions.                |
| **[`epics/`](epics/)**       | **Execution**. Where work happens. Check here for the current sprint/task. |
<!-- /SECTION: quick-navigation -->

---

<!-- SECTION: core-principles -->
## 2. Core Principles (The 3+1 System)

1. **Navigation Files**: `README` + `PRD` + `CLAUDE` = The map.
2. **Active Work**: Happens in **EPICs**.
3. **Specs**: All specs (rules, flows, APIs) live in `SoT/` with unique IDs.
   - `BR-XXX`: Business Rules
   - `UJ-XXX`: User Journeys
   - `API-XXX`: Contracts
   - `CFD-XXX`: Customer Feedback
4. **Gates**: We do not advance the PRD version without meeting the **Definition of Done** (see [`README.md`](README.md)).
<!-- /SECTION: core-principles -->

---

<!-- CUSTOMIZABLE: product-dashboard -->
## 3. Product Status Dashboard

**Lifecycle Stage**: `v0.7 Build Execution` (Active — 8 EPICs planned)

| Gate                          | Status         | Owner        | Blocker? |
| ----------------------------- | -------------- | ------------ | -------- |
| **v0.1 Spark**                | ✅ Complete    | Strategy     | -        |
| **v0.2 Market Definition**    | ✅ Complete    | Strategy     | -        |
| **v0.3 Commercial Model**     | ✅ Complete    | Strategy     | -        |
| **v0.4 User Journeys**        | ✅ Complete    | Design       | -        |
| **v0.5 Red Team Review**      | ✅ Complete    | Strategy     | -        |
| **v0.6 Architecture**         | ✅ Complete    | Architecture | -        |
| **v0.7 Build Execution**      | 🔵 Active     | Build        | -        |
| **v0.8 Release & Deployment** | ⚪ Pending     | -            | -        |
| **v0.9 Launch**               | ⚪ Pending     | -            | -        |
| **v1.0 Growth**               | ⚪ Pending     | -            | -        |

### EPIC Backlog

| EPIC | Name | State | Depends On |
|------|------|-------|------------|
| EPIC-01 | Project Scaffolding & Dev Environment | ✅ Complete | — |
| EPIC-02 | Audio Capture Engine | ✅ Complete | EPIC-01 |
| EPIC-02b | Audio Artifact Contract Hardening (Codex synthesis review fixes) | ✅ Complete | EPIC-02 |
| EPIC-03 | Transcription Pipeline | ✅ Complete | EPIC-01, EPIC-02b |
| EPIC-04 | Speaker Diarization Sidecar | Split → EPIC-04a + EPIC-04b | EPIC-01 |
| EPIC-04a | Diarization CLI & Packaging (Python) | ✅ Complete | EPIC-01 |
| EPIC-04b | Swift `DiarizationService` Bridge | ✅ Complete | EPIC-04a |
| EPIC-05 | Transcript Formatting & Alignment | ✅ Complete | EPIC-03, EPIC-04b |
| EPIC-06 | Storage & Obsidian Export | Active | EPIC-01, EPIC-05 |
| EPIC-07 | SwiftUI Interface | Planned | EPIC-02, EPIC-05, EPIC-06 |
| EPIC-08 | Pipeline Integration & Audio Lifecycle | Planned | EPIC-02→07 |

### KPI Metrics

| ID | Metric | Target | Current | Status |
|----|--------|--------|---------|--------|
| KPI-001 | Processing Speed (30-min meeting) | < 5 min | TBD | ⚪ Not measured |
| KPI-002 | Diarization Accuracy | > 80% | TBD | ⚪ Not measured |
| KPI-003 | Daily Active Use | 1+ meeting/day | TBD | ⚪ Not measured |

### Risk Scorecard

| ID | Risk | Eff. Score | Status |
|----|------|-----------|--------|
| RISK-001 | pyannote CPU-only on macOS (slow) | 4.5 | mitigating |
| RISK-002 | macOS 15+ requirement for mic capture | 6.0 | accepted |
| RISK-003 | Large app bundle from PyInstaller sidecar | 3.0 | mitigating |
| RISK-004 | Screen Recording permission friction | 3.0 | mitigating |
| RISK-005 | Speaker-transcript alignment accuracy | 2.0 | mitigating |
| RISK-006 | Crash during recording loses audio | 1.5 | mitigating |

---

## 4. Product Roadmap

> **Focus**: Local macOS meeting transcription with speaker diarization and Obsidian export.

### Deployment 1: Beta (Concept Validation)

- **Associated Epics**: EPIC-01 → EPIC-08
- **Key Specs**: UJ-001, UJ-002, BR-101, BR-102, FEA-001→005

- [ ] **Core Functionality**: Record → Transcribe → Diarize → Export pipeline working end-to-end.
- [ ] **Context**: Uses local test recordings. Manual testing of accuracy.
- [ ] **Objective**: Validate local pipeline performance and diarization accuracy.

### Deployment 2: MVP (Pilot Readiness)

- **Associated Epics**: TBD
- **Key Specs**: FEA-006, SCR-001→006, BR-301, BR-302

- [ ] **Production Quality**: Stable, polished UI, reliable audio cleanup.
- [ ] **Marketing**: Direct distribution (GitHub release, personal use).
- [ ] **Objective**: Daily-driver tool for personal meeting workflow.

### Deployment 3: Releases (Feature Expansion)

- [ ] **Feature Expansion**: Multi-language, real-time transcription, AI summarization.
- [ ] **Objective**: Expand capability beyond MVP.

### Deployment 4: V1.0 (Market Fit)

- [ ] **Signal**: Reliable daily use across diverse meeting types.
- [ ] **Objective**: Optimization and polish.
<!-- /CUSTOMIZABLE: product-dashboard -->

---

## 5. Quick Commands

```bash
# One-time: install build tools
brew install xcodegen python@3.11

# Generate the Xcode project (regenerates TranscriptShadow.xcodeproj from project.yml)
xcodegen generate

# Build (Xcode)
xcodebuild build -scheme TranscriptShadow -destination 'platform=macOS,arch=arm64'

# Run tests
xcodebuild test -scheme TranscriptShadow -destination 'platform=macOS,arch=arm64'

# Set up + build diarization sidecar
cd sidecar
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pyinstaller diarize.spec   # release-only; multi-GB / multi-minute
```

---

## 6. Repository Guide

- **`epics/`**: The living state of work (Issues/Tickets).
- **`SoT/`**: The Source of Truth (Requirements).
- **`temp/`**: Scratchpad work tied to active epics.
- **`.claude/`**: Agents, tools, skills, and hooks.

### SoT File Index

| File | IDs | Content |
|------|-----|---------|
| `SoT.customer_feedback.md` | CFD-001→004, CFD-101→103 | Pain points and value hypotheses |
| `SoT.BUSINESS_RULES.md` | BR-101→103, BR-201→203, BR-301→302, BR-401→402 | Privacy, platform, output rules |
| `SoT.USER_JOURNEYS.md` | PER-001→002, UJ-001→003, SCR-001→006 | Personas, journeys, screens |
| `SoT.DESIGN_COMPONENTS.md` | DES-001→005, DES-101→104, DES-201→203, DES-301→305 | UI components, layout principles, design tokens |
| `SoT.TECHNICAL_DECISIONS.md` | TECH-001→007, ARC-001→003, ENV-001 | Stack, architecture, environment |
| `SoT.API_CONTRACTS.md` | API-001→002, API-101→102, API-201→202, API-301 | Internal service contracts |
| `SoT.DATA_MODEL.md` | DBT-001→003, DBT-101 | SQLite schema |
| `SoT.INTEGRATIONS.md` | INT-001, INT-101, INT-201→202 | Obsidian, WhisperKit, macOS APIs |
| `SoT.TESTING.md` | TEST-001→005, TEST-101→104, TEST-201→204, TEST-301→303, TEST-401→405, TEST-501→504 | Test cases for all API contracts |

---

> **Note**: This repository follows [PRD Led Context Engineering](https://github.com/mattgierhart/PRD-driven-context-engineering).
