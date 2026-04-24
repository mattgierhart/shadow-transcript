---
version: 2.1
purpose: Progressive Product Requirements Document aligned to the PRD Led Context Engineering lifecycle.
last_updated: 2026-04-24
template_version: "3.0.0"
---

# Transcript Shadow · Product Requirements Document (PRD)

**Authority & Workflow**

- `README.md` — repository orientation (always read first).
- `PRD.md` — this file. Owns the strategic narrative from v0.1 → v1.0.
- `CLAUDE.md` — agent behavior. Confirms how to implement what this PRD asks for.
- `epics/EPIC-{XX}-<slug>.md` — execution window. Updates IDs created/modified when advancing v0.7+.
- See `README.md` for gate criteria and rituals.

---

## PRD Metadata

| Field                      | Value                              |
| -------------------------- | ---------------------------------- |
| **Current Lifecycle Gate** | v0.6                               |
| **Last Updated**           | 2026-04-24                         |
| **Last Editor**            | Claude Agent                       |
| **Status**                 | Discovery                          |
| **Next Target Gate**       | v0.7                               |
| **Related EPIC**           | None (pre-v0.7)                    |
| **SoT Snapshot**           | CFD-001→004, CFD-101→103, BR-101→103, BR-201→203, BR-301→302, BR-401→402, BR-501, PER-001→002, UJ-001→003, SCR-001→006, DES-001→003, DES-101→102, DES-201→202, DES-301, TECH-001→007, ARC-001→003, INT-001, INT-101, INT-201→202, API-001→002, API-101→102, API-201→202, API-301, DBT-001→003, DBT-101 |

## Lifecycle Change Log

| Version                | Date       | Editor       | Summary                              | Linked IDs / EPIC   |
| ---------------------- | ---------- | ------------ | ------------------------------------ | ------------------- |
| v0.1 Spark             | 2026-03-11 | Claude Agent | Problem + outcomes framed            | CFD-001→004, CFD-101→103 |
| v0.2 Market Definition | 2026-03-11 | Claude Agent | ICP + segments defined               | BR-201→203          |
| v0.3 Commercial Model  | 2026-03-11 | Claude Agent | Features + outcomes (pricing skipped) | FEA-001→006, KPI-001→003 |
| v0.4 User Journeys     | 2026-03-11 | Claude Agent | Personas, journeys, screens mapped   | PER-001→002, UJ-001→003, SCR-001→006, DES-001→003, DES-101→102 |
| v0.5 Red Team Review   | 2026-03-11 | Claude Agent | Risks + tech stack selected          | RISK-001→006, TECH-001→007 |
| v0.6 Architecture      | 2026-03-11 | Claude Agent | Architecture, APIs, data model       | ARC-001→003, API-001→301, DBT-001→101, INT-001→202 |
| v0.4/0.5 refinement    | 2026-04-24 | Claude Agent | Minimal recording UI; Notch/Menu-bar HUD as SCR-002; UJ-001 & UJ-002 tightened for design | BR-501, SCR-002 (recast), DES-201, DES-202, RISK-007 |

---

## v0.1 Spark — Problem & Outcomes

**Spark Summary**
Transcript Shadow is a local macOS app that records meeting audio, transcribes it with speaker identification, and exports the result as markdown to Obsidian. It replaces cloud-based meeting recording tools (like Notion AI) for privacy-conscious professionals who want their meeting data to stay on their machine.

**Problem Statement**

- **Who is hurting?** Knowledge workers and privacy-conscious professionals who attend multiple meetings daily and need reliable transcripts.
- **What pain exists today?** Cloud-based transcription tools (Notion, Otter.ai, Fireflies) require uploading audio to third-party servers, creating privacy concerns. Local alternatives exist (whisper.cpp) but lack integrated speaker diarization and require technical setup.
- **Why now?** Apple Silicon ML capabilities make high-quality local transcription viable. WhisperKit and pyannote-audio have matured. macOS 15 ScreenCaptureKit enables system audio capture without virtual audio drivers.

**Desired Outcomes**

- Users can record, transcribe, and export meetings without audio leaving their machine (CFD-101)
- Speaker-labeled transcripts reduce post-meeting processing time by eliminating manual attribution (CFD-102)
- Transcripts appear directly in Obsidian vault as searchable, linked markdown (CFD-103)

**Initial Success Signals**

- Metric: End-to-end pipeline works for a 30-minute meeting (Target: < 5 min processing)
- Metric: Speaker diarization correctly identifies 2-4 speakers (Target: > 80% accuracy)
- Insight IDs: CFD-001, CFD-002, CFD-003, CFD-004

**Constraints & Non-goals**

- Constraint: All processing must be local (BR-101)
- Constraint: No persistent audio storage (BR-102)
- Constraint: macOS only, Apple Silicon only (BR-201, BR-401)
- Non-goal: Real-time transcription during recording (deferred to post-MVP)
- Non-goal: Multi-language support (BR-202, English only for MVP)
- Non-goal: Revenue, pricing, or monetization (per project guardrails)

**Open Questions** (answered in subsequent stages)

- ~~Which transcription engine: WhisperKit vs whisper.cpp?~~ → WhisperKit (TECH-002)
- ~~How to handle speaker diarization locally?~~ → pyannote-audio sidecar (TECH-006, ARC-002)
- ~~System audio capture approach?~~ → ScreenCaptureKit (TECH-004)

---

## v0.2 Market Definition — ICP & Segments

> **Note**: Competitor research skipped per project guardrails (v0.1-v0.6).

**Market Thesis**
Privacy-conscious macOS users who use Obsidian as their knowledge base need a local meeting transcription tool. The intersection of "wants transcription" + "won't use cloud tools" + "uses Obsidian" defines a specific, underserved niche.

**Primary Segments (max 3)**

| Segment | Description | Urgency | Source (ID) |
|---------|-------------|---------|-------------|
| Solo Knowledge Workers | Engineers, PMs, designers using Obsidian for notes. 3-8 meetings/day. Value local-first tools. | High | CFD-002, CFD-003 |
| Privacy-Conscious Professionals | Legal, medical, executive, HR. Confidentiality requirements prohibit cloud processing. | High | CFD-001 |
| Notion-to-Obsidian Migrants | Users leaving Notion who want meeting recording without ecosystem lock-in. | Medium | CFD-004 |

**Not For**

- Teams needing collaborative real-time transcription (this is a single-user tool per BR-203)
- Windows/Linux users (macOS only per BR-201)
- Users without Apple Silicon (M1+ required per BR-401)
- Non-English speakers (English only per BR-202)

**Enabling Business Rules (BR-XXX)**

- BR-201 — macOS 14+ only (Sonoma minimum)
- BR-202 — English-only transcription
- BR-203 — Single-user local app, no accounts
- BR-401 — Apple Silicon (M1+) required

**Outstanding Work → v0.3**

- ~~Define feature set and success metrics~~ → Done in v0.3

---

## v0.3 Commercial Model — Features & Outcomes

> **Note**: Pricing, monetization, and competitor analysis skipped per project guardrails.

**Feature Definitions (FEA-XXX)**

| ID | Feature | Priority | Description | Traced To |
|----|---------|----------|-------------|-----------|
| FEA-001 | Audio Capture | P0 (Must) | Capture microphone + system audio simultaneously on macOS | CFD-001, BR-101, TECH-003, TECH-004 |
| FEA-002 | Local Transcription | P0 (Must) | Transcribe audio to text with timestamps using WhisperKit | CFD-002, BR-101, TECH-002 |
| FEA-003 | Speaker Diarization | P0 (Must) | Identify and label different speakers in the transcript | CFD-002, CFD-102, TECH-006 |
| FEA-004 | Markdown Output | P0 (Must) | Format transcript as standard markdown with speaker labels and timestamps | CFD-004, BR-301 |
| FEA-005 | Obsidian Export | P0 (Must) | Export transcript directly to Obsidian vault with frontmatter | CFD-003, BR-302, INT-001 |
| FEA-006 | Transcript History | P1 (Should) | Browse and search past transcripts locally | UJ-002, SCR-006, DBT-001 |

**Outcome Definitions (KPI-XXX)**

| ID | Metric | Target | Measurement | Source |
|----|--------|--------|-------------|--------|
| KPI-001 | Processing Speed | < 5 min for 30-min meeting | Pipeline end-to-end time | App telemetry (local) |
| KPI-002 | Diarization Accuracy | > 80% speaker segment accuracy | Manual spot-check on test recordings | User validation |
| KPI-003 | Daily Active Use | User records 1+ meeting/day | Local usage counter | App telemetry (local) |

**MVP Boundary Statement**

**IN scope (MVP)**:
- Record mic + system audio on macOS 15+ / Apple Silicon
- Transcribe using WhisperKit (base.en model, user-selectable)
- Diarize speakers using pyannote-audio (post-recording batch process)
- Output as markdown with speaker labels and timestamps
- Export to Obsidian vault directory
- Browse/search transcript history
- Settings: audio source, vault path, model selection

**OUT of scope (MVP)**:
- Real-time/streaming transcription during recording
- Multi-language support
- Cloud sync, accounts, collaboration
- Audio retention or playback
- AI summarization of transcripts
- Custom Obsidian plugin
- Windows/Linux/iOS support
- Revenue or pricing features

**Outstanding Work → v0.4**

- ~~Map user journeys from pain to value~~ → Done in v0.4

---

## v0.4 User Journeys — From Pain to Value

**Journey Overview**

| ID | Persona | Trigger | Key Steps | Pain Points | Moments of Value |
|----|---------|---------|-----------|-------------|------------------|
| UJ-001 | PER-001, PER-002 | Meeting starting | Open → Select source → Record (main window hides, HUD appears) → meeting continues with only HUD visible → Stop (from HUD) → Process → View | Waiting during processing; permission prompts; HUD realization depends on hardware (notch vs menu bar) | App is invisible during the meeting; Stop is one click away; seeing speaker-labeled transcript appear |
| UJ-002 | PER-001 | Transcript ready | View → Click speaker chip → inline rename (propagates across all segments) → Export to Obsidian | Auto-labels like "Speaker 1" need to be named; turn-boundary words may be misattributed (RISK-005) | Transcript in Obsidian vault with real names, searchable |
| UJ-003 | PER-001 | First launch / change needed | Open settings → Configure audio + vault + model | Initial setup friction | "Set and forget" configuration |

**Journey Narratives**

- **UJ-001 – Record and Transcribe Meeting**
  - Step Flow: SCR-001 → (main window hides) → SCR-002 Recording HUD → (Stop; main window restores) → SCR-003 → SCR-004
  - Dependencies: BR-101, BR-102, BR-103, BR-402, BR-501, TECH-002, TECH-003, TECH-004, TECH-006, DES-201, DES-202
  - Opportunity Notes: During the meeting the app must be invisible except for the HUD (BR-501). HUD realization is hardware-chosen (DES-201 notch vs DES-202 menu bar extra) — design both surfaces as peers, not the menu bar as a degraded version. Processing view (SCR-003) is critical for user confidence — must show clear progress.

- **UJ-002 – Review and Export Transcript**
  - Step Flow: SCR-004 → (click speaker chip → inline rename; propagates across every segment) → Export → Obsidian
  - Dependencies: BR-301, BR-302, INT-001, DES-101, DES-003, DES-301, DBT-002, API-201, API-202
  - Opportunity Notes: This is the product's most important interaction per user priority. Speaker rename propagates through entire transcript in a single update via `API-201`'s `speakerNames` override map and `DBT-002.display_name`. Chip states (Display / Hover / Editing) are fully specified in DES-101. Export uses current display names; auto-keys never leak into the markdown. Obsidian export should show confirmation with file path + "Reveal" / "Open in Obsidian" actions.

- **UJ-003 – Configure App Settings**
  - Step Flow: SCR-005 (settings panel)
  - Dependencies: INT-001, INT-201, INT-202
  - Opportunity Notes: First-launch onboarding should guide through critical settings (vault path, permissions)

**Screen Flow Summary**

| ID | Screen | Purpose | Key Components |
|----|--------|---------|----------------|
| SCR-001 | Main Window | Entry point (pre-record) + post-record review host. Hidden during recording (BR-501). | DES-001 (Record Button) |
| SCR-002 | Recording HUD | Single permitted recording surface. Notch HUD on notch-equipped MBPs, Menu Bar Extra elsewhere. Only action: Stop. | DES-201 (Notch HUD), DES-202 (Menu Bar Extra) |
| SCR-003 | Processing View | Transcription/diarization progress, rendered in the restored main window after Stop. | DES-102 (Progress Pipeline) |
| SCR-004 | Transcript View | Review, rename speakers (inline on DES-101 chip — propagates across every segment), export transcript. | DES-003 (Transcript Block), DES-101 (Speaker Label), DES-301 (speaker palette) |
| SCR-005 | Settings View | App configuration | Standard form controls |
| SCR-006 | Transcript History | Browse past transcripts | List view with search |

**UX / Research Assets**

- Design Reference: [ElevenLabs UI](https://ui.elevenlabs.io/docs/) — dark, minimal, audio-centric aesthetic
- SoT: `SoT/SoT.USER_JOURNEYS.md`, `SoT/SoT.DESIGN_COMPONENTS.md`

**Outstanding Work → v0.5**

- ~~Identify risks and select tech stack~~ → Done in v0.5

---

## v0.5 Red Team Review — Risks & Mitigations

**Risk Register**

| ID | Scoring | Risk | Impact | Likelihood | Raw | Status | Eff. Score | Mitigation | Linked IDs |
|----|---------|------|--------|------------|-----|--------|------------|------------|------------|
| RISK-001 | Technical | pyannote diarization runs on CPU only on macOS (MPS unreliable), causing slow processing for long meetings | H (3) | H (3) | 9 | mitigating | 4.5 | Bundle pyannote via PyInstaller; process in background; show progress. Evaluate WeSpeaker ONNX as faster alternative. | TECH-006, ARC-002 |
| RISK-002 | Technical | ScreenCaptureKit microphone capture requires macOS 15+, limiting user base | M (2) | H (3) | 6 | accepted | 6.0 | Accept macOS 15+ requirement; fallback to AVAudioEngine for mic on macOS 14 if needed. | TECH-004, BR-201 |
| RISK-003 | Technical | PyInstaller-bundled diarization sidecar produces large app size (~400-600MB) | M (2) | H (3) | 6 | mitigating | 3.0 | Download diarization model on first launch. Compress sidecar binary. | ARC-002, TECH-006 |
| RISK-004 | User | Users may not grant Screen Recording permission (required for system audio capture) | H (3) | M (2) | 6 | mitigating | 3.0 | Clear onboarding explaining why permission is needed. Allow mic-only mode as fallback. | INT-202, UJ-003 |
| RISK-005 | Technical | Transcript-diarization alignment may produce misattributed speaker segments | M (2) | M (2) | 4 | open | 4.0 | Implement word-level timestamp alignment between WhisperKit output and pyannote segments. Allow manual correction in SCR-004. | API-201, FEA-003 |
| RISK-006 | User | App crashes during recording could lose audio before processing | H (3) | L (1) | 3 | mitigating | 1.5 | Write audio to temp file continuously during recording (not buffered). Implement crash recovery that detects orphaned temp audio on next launch. | ARC-003, BR-103 |
| RISK-007 | UX/Technical | Minimal recording UI depends on notch hardware (DES-201); non-notch Macs get menu-bar fallback (DES-202). Risk: parity drift between surfaces, or the notch HUD failing on fullscreen meeting apps (e.g., Zoom fullscreen covering the notch area). | M (2) | M (2) | 4 | mitigating | 2.0 | Design both surfaces as peers, not as primary/degraded. Verify NSPanel `.statusBar + 1` window level survives common fullscreen meeting apps during implementation spike. If notch HUD can't stay above fullscreen windows, promote menu-bar extra to primary. | BR-501, SCR-002, DES-201, DES-202 |

<!-- Risk Scoring Quick Reference:
  Impact: High=3, Medium=2, Low=1 | Likelihood: High=3, Medium=2, Low=1
  Raw = Impact x Likelihood
  Status Weights: open=1.0, accepted=1.0, mitigating=0.5, mitigated=0.25, resolved=0.0
  Effective Score = Raw x Status Weight
-->

**Development Challenges (Flag for EPIC Planning)**

- Python sidecar packaging and distribution (PyInstaller cross-compilation for ARM64) → TECH-006, ARC-002
- ScreenCaptureKit audio mixing (mic + system → single WAV) → API-002
- WhisperKit + pyannote output alignment (word timestamps ↔ speaker segments) → API-201, RISK-005

**Security / Compliance Notes**

- No network calls in core pipeline (BR-101) — can be verified by firewall testing
- Temp audio in sandboxed app container — inaccessible to other apps
- Secure deletion via APFS TRIM on Apple SSDs (ARC-003)

**Technology Stack Decisions**

| Decision | Choice | License | Rationale | ID |
|----------|--------|---------|-----------|-----|
| App Framework | Swift + SwiftUI | N/A | Native macOS APIs, small footprint | TECH-001 |
| Transcription | WhisperKit | MIT | Native Swift SPM, CoreML/ANE | TECH-002 |
| Microphone Capture | AVAudioEngine | N/A | First-party, all macOS versions | TECH-003 |
| System Audio | ScreenCaptureKit | N/A | No driver needed, macOS 15+ | TECH-004 |
| Obsidian Export | File system write | N/A | Zero dependency, file-based | TECH-005 |
| Speaker Diarization | pyannote-audio + community-1 | MIT + CC-BY-4.0 | Best accuracy, open models | TECH-006 |
| Local Storage | SQLite (GRDB.swift) | MIT | Serverless, single-user | TECH-007 |

**Open-Source Repos Evaluated**

| Repo | URL | License | Verdict |
|------|-----|---------|---------|
| WhisperKit | github.com/argmaxinc/WhisperKit | MIT | **Selected** — native Swift, CoreML |
| whisper.cpp | github.com/ggml-org/whisper.cpp | MIT | Fallback — requires C bridging |
| pyannote-audio | github.com/pyannote/pyannote-audio | MIT | **Selected** — best diarization |
| community-1 model | huggingface.co/pyannote/speaker-diarization-community-1 | CC-BY-4.0 | **Selected** — free, open |
| WeSpeaker | github.com/wenet-e2e/wespeaker | Apache-2.0 | Alternative — evaluate if pyannote too slow |
| Azayaka | github.com/Mnpn/Azayaka | Open | Reference — ScreenCaptureKit patterns |
| BlackHole | github.com/ExistentialAudio/BlackHole | GPL-3.0 | Rejected — user setup friction, GPL |

**Outstanding Work → v0.6**

- ~~Define architecture, API contracts, data model~~ → Done in v0.6

---

## v0.6 Architecture — Technical Blueprint

**System Overview**

Transcript Shadow is a native macOS app (SwiftUI) with a Python sidecar for speaker diarization. The architecture follows a local-first sequential pipeline (ARC-001).

```
┌─────────────────────────────────────────────────────┐
│                  Transcript Shadow                   │
│                  (SwiftUI macOS App)                 │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Audio    │  │ Whisper  │  │ Transcript       │  │
│  │ Capture  │→ │ Kit      │→ │ Formatter        │  │
│  │ Service  │  │ (CoreML) │  │ + Speaker Merge  │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│       ↓              ↓              ↓               │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Temp WAV │  │ Word     │  │ Markdown Output  │  │
│  │ File     │  │ Stamps   │  │ + Obsidian Export │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│       ↓                                             │
│  ┌──────────────────────┐                           │
│  │ pyannote Sidecar     │  (PyInstaller binary)     │
│  │ → Speaker Segments   │                           │
│  └──────────────────────┘                           │
│                                                     │
│  ┌──────────┐  ┌──────────┐                         │
│  │ SQLite   │  │ Settings │                         │
│  │ (GRDB)   │  │ Store    │                         │
│  └──────────┘  └──────────┘                         │
└─────────────────────────────────────────────────────┘
```

Architecture decisions: ARC-001 (local pipeline), ARC-002 (Python sidecar), ARC-003 (temp audio lifecycle).

**API Contracts (API-XXX)**

| ID | Service | Type | Purpose |
|----|---------|------|---------|
| API-001 | AudioCaptureService | Swift protocol | Manage mic + system audio capture |
| API-002 | AudioMixer | Swift utility | Mix mic + system into single WAV |
| API-101 | TranscriptionService | Swift protocol | WhisperKit transcription with timestamps |
| API-102 | Diarization Sidecar | CLI executable | pyannote speaker diarization (subprocess) |
| API-201 | TranscriptFormatter | Swift protocol | Merge transcription + diarization → markdown |
| API-202 | ObsidianExporter | Swift protocol | Write markdown to Obsidian vault |
| API-301 | TempAudioCleanup | Swift background | Delete temp audio files reliably |

Full contracts with interface signatures: `SoT/SoT.API_CONTRACTS.md`

**Data Model (DBT-XXX)**

| ID | Table | Purpose |
|----|-------|---------|
| DBT-001 | transcripts | Transcript metadata + full markdown content |
| DBT-002 | speakers | Speaker identity mapping per transcript |
| DBT-003 | segments | Individual speaker turns with timestamps |
| DBT-101 | app_settings | User preferences (key-value) |

Full schema: `SoT/SoT.DATA_MODEL.md`

**Integration Notes**

| ID | Integration | Approach |
|----|-------------|----------|
| INT-001 | Obsidian Vault | Direct file write to vault directory, YAML frontmatter |
| INT-101 | WhisperKit Models | Download on first launch, cache in app support |
| INT-201 | macOS Microphone | AVAudioEngine, requires mic permission |
| INT-202 | ScreenCaptureKit | System audio, requires Screen Recording permission |

Full details: `SoT/SoT.INTEGRATIONS.md`

**Outstanding Work → v0.7**

- Create EPIC backlog for implementation
- Define test cases (TEST-XXX) for each API contract
- Set up Xcode project with SwiftUI + WhisperKit SPM dependency
- Build and test pyannote PyInstaller sidecar packaging
- Determine macOS 14 vs 15 minimum deployment target (RISK-002)

---

## v0.7 Build Execution — Plan for Delivery

_Not yet started. Pending v0.7 gate entry._

---

## v0.8 Release & Deployment — Operational Readiness

_Not yet started._

---

## v0.9 Go-to-Market — Launch & Feedback

_Not yet started._

---

## v1.0 Market Adoption — Optimize & Expand

_Not yet started._

---

## Appendices & References

- **Glossary**:
  - **Diarization**: The process of identifying who spoke when in an audio recording
  - **Sidecar**: A separate process bundled with the app for specific functionality
  - **CoreML/ANE**: Apple's ML framework running on the Apple Neural Engine
  - **GGML**: A tensor library format used by whisper.cpp models
- **ID Index**: Link to `SoT/SoT.UNIQUE_ID_SYSTEM.md`
- **Open-Source References**:
  - [WhisperKit](https://github.com/argmaxinc/WhisperKit) — MIT, Swift transcription
  - [pyannote-audio](https://github.com/pyannote/pyannote-audio) — MIT, speaker diarization
  - [whisper.cpp](https://github.com/ggml-org/whisper.cpp) — MIT, C/C++ transcription
  - [Azayaka](https://github.com/Mnpn/Azayaka) — ScreenCaptureKit reference
  - [ElevenLabs UI](https://ui.elevenlabs.io/docs/) — Design reference

> Maintain appendices as lightweight navigation helpers. All authoritative data lives in SoT files referenced above.
