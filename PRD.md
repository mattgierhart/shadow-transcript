---
version: 2.0
purpose: Progressive Product Requirements Document aligned to the PRD Led Context Engineering lifecycle.
last_updated: 2026-05-08
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
| **Current Lifecycle Gate** | v0.7                               |
| **Last Updated**           | 2026-05-08                         |
| **Last Editor**            | Claude Agent                       |
| **Status**                 | Build Execution                    |
| **Next Target Gate**       | v0.8                               |
| **Related EPIC**           | EPIC-01 through EPIC-08            |
| **SoT Snapshot**           | CFD-001→004, CFD-101→103, BR-101→103, BR-201→203, BR-301→302, BR-401→402, PER-001→002, UJ-001→003, SCR-001→006, DES-001→005, DES-101→104, DES-201→203, DES-301→305, TECH-001→007, ARC-001→003, INT-001, INT-101, INT-201→202, API-001→002, API-101→102, API-201→202, API-301, DBT-001→003, DBT-101, TEST-001→005, TEST-101→104, TEST-201→204, TEST-301→303, TEST-401→405, TEST-501→504 |

## Lifecycle Change Log

| Version                | Date       | Editor       | Summary                              | Linked IDs / EPIC   |
| ---------------------- | ---------- | ------------ | ------------------------------------ | ------------------- |
| v0.1 Spark             | 2026-03-11 | Claude Agent | Problem + outcomes framed            | CFD-001→004, CFD-101→103 |
| v0.2 Market Definition | 2026-03-11 | Claude Agent | ICP + segments defined               | BR-201→203          |
| v0.3 Commercial Model  | 2026-03-11 | Claude Agent | Features + outcomes (pricing skipped) | FEA-001→006, KPI-001→003 |
| v0.4 User Journeys     | 2026-03-11 | Claude Agent | Personas, journeys, screens mapped   | PER-001→002, UJ-001→003, SCR-001→006, DES-001→003, DES-101→102 |
| v0.4 Design Interview  | 2026-03-20 | Claude Agent | Visual identity, design tokens, layout principles | DES-004→005, DES-103→104, DES-201→203, DES-301→305 |
| v0.4 Screen Flow Enrich | 2026-03-20 | Claude Agent | SCR/UJ enriched: navigation, features, actions, density, constraints | SCR-001→006 (v2), UJ-001→003 (v2), PER-001→002 (v2) |
| v0.4 Visual Prototype  | 2026-03-20 | Claude Agent | Stitch prompts for all 6 screens, money shot identified | temp/visual-prototype-gate.md |
| v0.5 Red Team Review   | 2026-03-11 | Claude Agent | Risks + tech stack selected          | RISK-001→006, TECH-001→007 |
| v0.6 Architecture      | 2026-03-11 | Claude Agent | Architecture, APIs, data model       | ARC-001→003, API-001→301, DBT-001→101, INT-001→202 |
| v0.7 Build Execution   | 2026-03-20 | Claude Agent | EPIC backlog, test cases, deployment target resolved | EPIC-01→08, TEST-001→504 |
| v0.7 EPIC-01 Complete  | 2026-05-06 | Claude Agent | Project scaffold via XcodeGen + WhisperKit + GRDB SPM deps + Python sidecar skeleton + macos-15 CI workflow | EPIC-01, TECH-001/002/006/007, ENV-001 |
| v0.7 EPIC-02 Complete  | 2026-05-06 | Claude Agent | Audio capture (mic + system + mixer) implemented + Codex review caught 4 follow-on bugs (dual-source mix, actor reentrancy, level stream termination, mic tap leak) all fixed in same session | EPIC-02, API-001, API-002, TEST-001→005 |
| v0.7 EPIC-02b Complete | 2026-05-07 | Claude Agent | Audio artifact contract hardening: recordingFinalized milestone, atomic writer, unique filenames, broadcast buses, channelCount removal, docstring tightening — all 6 issues from Codex synthesis review fixed before EPIC-03 started | EPIC-02b, API-001, API-002 |
| v0.7 EPIC-03 Complete  | 2026-05-08 | Claude Agent | Transcription pipeline (TranscriptionService + WhisperKit engine) implemented + Codex review caught 3 follow-on bugs (downloadBase init, AsyncTaskQueue serialization, CancellationError surfacing) all fixed in same session | EPIC-03, API-101, INT-101, TEST-101→104 |
| v0.7 EPIC-04 Split     | 2026-05-08 | Claude Agent | Original EPIC-04 split into EPIC-04a (Python CLI + PyInstaller) and EPIC-04b (Swift Process bridge). Reason: BROAD-scope hook firing (12 SoT items) + Codex's recommendation that the two risk profiles are categorically different. EPIC-04 file converted to an index pointing at the children. | EPIC-04, EPIC-04a, EPIC-04b |
| v0.7 EPIC-04a Complete | 2026-05-09 | Claude Agent | Real pyannote.audio 4.x pipeline + frozen JSON envelope (schema 1.0) + PyInstaller `--onedir` spec + 30 pytest cases (TEST-201..204) + golden-3spk.json cross-language fixture. Codex Gate 1 caught 3 bugs (P0 incompatible torch pin, P1 ProgressHook stdout pollution, P1 vacuous progress test) — all resolved before commit. Empirical RTF / bundle-size measurements deferred to Phase A spike on dev machine. | EPIC-04a, API-102, INT-102, TEST-201→204, RISK-001/003 |
| v0.7 EPIC-04b Complete | 2026-05-09 | Claude Agent | Swift `DiarizationService` bridge (Foundation `Process`, AsyncTaskQueue serialization, withTaskCancellationHandler-based SIGTERM, JSON envelope decode) + production entitlements (+5 EPIC-04b additions) + child diarize.entitlements (`inherit` only) + Run Script Build Phase that copies the EPIC-04a bundle into `Resources/diarize/` and bottom-up codesigns. Deviated from planning's swift-subprocess pick (still pre-1.0); used Foundation Process with FileHandle.bytes.lines instead. Codex Gate 2 caught 10 bugs (2 P0, 6 P1, 2 P2 — including an `AsyncTaskQueue` race that pre-existed since EPIC-03), all resolved before commit. 74 XCTests + 30 pytest = 104 total green. | EPIC-04b, API-102, INT-102, DEP-002, RISK-007, BR-101 |
| v0.7 EPIC-05 Complete  | 2026-05-12 | Claude Agent | Transcript formatting & alignment (`TranscriptFormatter` + `DefaultTranscriptFormatter` + internal `WordSpeakerAligner`) + `FormattedTranscript`/`TranscriptMetadata` Codable types shaped to DBT-001 columns + 4 in-code fixtures (`make3SpeakerFixture`, `make1SpeakerFixture`, `makeZeroSegmentFixture`, `makeStraddlingWordFixture`) + ~17 new XCTests covering TEST-301/302/303 plus boundary-straddle, silence-gap, empty-words, zero-segments, and invalid-segment edge cases. SoT signature reconciliation: API-201 updated from `transcription: TranscriptionResult` to `transcription: Transcript` (matches EPIC-03's WhisperKit-disambiguation rename) + `speakerNames` optionality dropped (`[String: String] = [:]`). Build verification deferred to CI (`macos-15` runner per `.github/workflows/build.yml`). Codex Gate 3 not yet run in this session — to be invoked post-CI-green. | EPIC-05, API-201, BR-301, FEA-003, FEA-004, RISK-005, TEST-301→303 |

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
| UJ-001 | PER-001, PER-002 | Meeting starting | Open → Select source → Record → Stop → Process → View | Waiting during processing; permission prompts | Seeing speaker-labeled transcript appear |
| UJ-002 | PER-001 | Transcript ready | View → Rename speakers → Export to Obsidian | Speaker names are auto-generated | Transcript in Obsidian vault, searchable |
| UJ-003 | PER-001 | First launch / change needed | Open settings → Configure audio + vault + model | Initial setup friction | "Set and forget" configuration |

**Journey Narratives**

- **UJ-001 – Record and Transcribe Meeting**
  - Step Flow: SCR-001 → SCR-002 → SCR-003 → SCR-004
  - Dependencies: BR-101, BR-102, BR-103, BR-402, TECH-002, TECH-003, TECH-004, TECH-006
  - Opportunity Notes: Processing view (SCR-003) is critical for user confidence — must show clear progress

- **UJ-002 – Review and Export Transcript**
  - Step Flow: SCR-004 → (rename speakers) → Export → Obsidian
  - Dependencies: BR-301, BR-302, INT-001
  - Opportunity Notes: Speaker rename must propagate through entire transcript. Obsidian export should show confirmation with file path.

- **UJ-003 – Configure App Settings**
  - Step Flow: SCR-005 (settings panel)
  - Dependencies: INT-001, INT-201, INT-202
  - Opportunity Notes: First-launch onboarding should guide through critical settings (vault path, permissions)

**Screen Flow Summary**

| ID | Screen | Purpose | Key Components |
|----|--------|---------|----------------|
| SCR-001 | Main Window | Entry point, recording controls | DES-001 (Record Button) |
| SCR-002 | Recording View | Active recording state | DES-001, DES-002 (Audio Level) |
| SCR-003 | Processing View | Transcription/diarization progress | DES-102 (Progress Pipeline) |
| SCR-004 | Transcript View | Review and export transcript | DES-003 (Transcript Block), DES-101 (Speaker Label) |
| SCR-005 | Settings View | App configuration | Standard form controls |
| SCR-006 | Transcript History | Browse past transcripts | List view with search |

**UX / Research Assets**

- Design Reference: [ElevenLabs UI](https://ui.elevenlabs.io/docs/) — dark, minimal, audio-centric aesthetic
- SoT: `SoT/SoT.USER_JOURNEYS.md`, `SoT/SoT.DESIGN_COMPONENTS.md`

### Visual Identity Direction

**Aesthetic**: Minimal, living, listening
**Inspiration**: ElevenLabs UI (dark, audio-centric controls), Obsidian (sidebar+content layout, markdown-native)
**Mode**: Dark only
**Personality**: A quiet, attentive tool that feels alive when listening but never demands attention. Spacious and ambient during recording (peripheral-friendly), dense and focused during transcript review. Native macOS feel — not a web app port.

**Outstanding Work → v0.5**

- ~~Identify risks and select tech stack~~ → Done in v0.5

---

## v0.5 Red Team Review — Risks & Mitigations

**Risk Register**

| ID | Scoring | Risk | Impact | Likelihood | Raw | Status | Eff. Score | Mitigation | Linked IDs |
|----|---------|------|--------|------------|-----|--------|------------|------------|------------|
| RISK-001 | Technical | pyannote diarization runs on CPU only on macOS (MPS unreliable), causing slow processing for long meetings | H (3) | H (3) | 9 | mitigating | 4.5 | EPIC-04a delivered the pyannote 4.x sidecar with progress reporting + AsyncTaskQueue serialization in EPIC-04b. RTF measurement is open until the dev-machine Spike C runs against a 5-min 3-speaker fixture; estimate "~31 s / hour" remains the planning anchor. WeSpeaker ONNX is now the embedding backend in pyannote 4 community-1, so this evolution is already absorbed. | TECH-006, ARC-002, INT-102 |
| RISK-002 | Technical | ScreenCaptureKit microphone capture requires macOS 15+, limiting user base | M (2) | H (3) | 6 | accepted | 6.0 | Accept macOS 15+ requirement; fallback to AVAudioEngine for mic on macOS 14 if needed. | TECH-004, BR-201 |
| RISK-007 | Technical | App-sandbox + hardened-runtime + PyInstaller bundle requires careful entitlement matrix and bottom-up codesign sequence; mistakes crash the child via `_libsecinit_appsandbox` or fail notarization | H (3) | M (2) | 6 | mitigated | 1.5 | EPIC-04b ships +5 parent entitlements + `inherit`-only child entitlements + a project.yml Run Script Build Phase that bottom-up codesigns the embedded tree. Verified by Codex Gate 2 review (10 findings, all resolved). Notarization dry-run deferred to release-prep EPIC. | DEP-002, INT-102, ARC-002 |
| RISK-003 | Technical | PyInstaller-bundled diarization sidecar produces large app size (~700 MB compressed baseline; revisit if > 1 GB) | M (2) | H (3) | 6 | mitigating | 3.0 | EPIC-04a: `--onedir` form (NOT `--onefile`), aggressive `excludes` list (tensorboard/torchvision/IPython/pytest/matplotlib reclaim ~100–200 MB), model downloaded on first launch (not bundled). Empirical bundle size is open until Spike D runs `pyinstaller diarize.spec` on the dev machine. | ARC-002, TECH-006, INT-102 |
| RISK-004 | User | Users may not grant Screen Recording permission (required for system audio capture) | H (3) | M (2) | 6 | mitigating | 3.0 | Clear onboarding explaining why permission is needed. Allow mic-only mode as fallback. | INT-202, UJ-003 |
| RISK-005 | Technical | Transcript-diarization alignment may produce misattributed speaker segments | M (2) | M (2) | 4 | mitigating | 2.0 | EPIC-05 ships midpoint-greedy alignment (`WordSpeakerAligner`) against `DiarizationResult.segments` (exclusive view): for each word, midpoint = `(start + end) / 2`; find the segment where `start <= mid < end`. Boundary straddles attribute by midpoint and emit a `straddled boundaries` warning. Silence-gap words attribute to `SPEAKER_UNKNOWN` and surface a warning. Empty `words` arrays fall back to segment-level midpoint; zero diarization segments synthesize a single-speaker turn with a warning. 1-indexed display names follow first-appearance order. Empirical boundary-attribution accuracy is asserted by `WordSpeakerAlignerTests` against the golden 3-speaker + straddle fixtures (cross-language paired with `sidecar/test_fixtures/golden-3spk.json`). SCR-004 manual correction (FEA-004's rename loop) remains the final backstop; ships in EPIC-07. | API-201, FEA-003 |
| RISK-006 | User | App crashes during recording could lose audio before processing | H (3) | L (1) | 3 | mitigating | 1.5 | Write audio to temp file continuously during recording (not buffered). Implement crash recovery that detects orphaned temp audio on next launch. | ARC-003, BR-103 |

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

**Deployment Target Decision**: macOS 15+ (Sequoia). Rationale: Unified ScreenCaptureKit path for both mic and system audio capture simplifies the code significantly. AVAudioEngine mic-only fallback on macOS 14 added marginal complexity for a shrinking user base. RISK-002 status remains "accepted" — macOS 15+ is the floor.

**Test Strategy**: 24 test cases defined in `SoT/SoT.TESTING.md` covering all 7 API contracts, critical business rules, and privacy guarantees. 13 are P0 (critical), 11 are P1. See TEST-001→504.

**EPIC Backlog (8 EPICs at v0.7 entry; EPIC-04 split into 04a + 04b on 2026-05-08 → 9 EPIC files)**

| EPIC | Name | State | Depends On | Key IDs | Priority |
|------|------|-------|------------|---------|----------|
| EPIC-01 | Project Scaffolding & Dev Environment | ✅ Complete (2026-05-06) | — | ENV-001, TECH-001, TECH-002, TECH-006, TECH-007 | P0 (foundation) |
| EPIC-02 | Audio Capture Engine | ✅ Complete (2026-05-06) | EPIC-01 | API-001, API-002, FEA-001, INT-201, INT-202 | P0 |
| EPIC-02b | Audio Artifact Contract Hardening | ✅ Complete (2026-05-07) | EPIC-02 | API-001, API-002 | P0 (Codex synthesis review fixes) |
| EPIC-03 | Transcription Pipeline | ✅ Complete (2026-05-08) | EPIC-01, EPIC-02b | API-101, FEA-002, INT-101, TECH-002 | P0 |
| EPIC-04 | Speaker Diarization Sidecar | Split → 04a + 04b (2026-05-08) | EPIC-01 | API-102, FEA-003, ARC-002, TECH-006 | P0 (highest risk) |
| EPIC-04a | Diarization CLI & Packaging (Python) | ✅ Complete (2026-05-09) | EPIC-01 | API-102 (CLI half), INT-102, ARC-002, TECH-006, BR-101, FEA-003, TEST-201..204, RISK-001/003 | P0 |
| EPIC-04b | Swift `DiarizationService` Bridge | ✅ Complete (2026-05-09) | EPIC-04a | API-102 (Swift half), INT-102, DEP-002, RISK-007 | P0 |
| EPIC-05 | Transcript Formatting & Alignment | Active (next up) | EPIC-03, EPIC-04b | API-201, FEA-004, BR-301, RISK-005 | P0 |
| EPIC-06 | Storage & Obsidian Export | Planned | EPIC-01, EPIC-05 | API-202, DBT-001→101, FEA-005, FEA-006, INT-001 | P0 |
| EPIC-07 | SwiftUI Interface | Planned | EPIC-02, EPIC-05, EPIC-06 | SCR-001→006, DES-XXX, UJ-001→003 | P1 |
| EPIC-08 | Pipeline Integration & Audio Lifecycle | Planned | EPIC-02→07 | API-301, ARC-001, ARC-003, BR-101→103 | P0 (E2E validation) |

**Execution Order (Parallelism)**

```
EPIC-01 (scaffolding) ✅
   ├→ EPIC-02 (audio) ✅ → EPIC-02b (hardening) ✅ ──┐
   ├→ EPIC-03 (transcribe) ✅ ───────────────────────┼→ EPIC-05 (format) → EPIC-06 (storage/export) ─┐
   └→ EPIC-04a (diarize CLI) → EPIC-04b (Swift bridge) ─┘                                            ├→ EPIC-08 (integration)
                                                                                       EPIC-07 (UI) ──┘
```

EPICs 02, 03, and the 04a/04b chain can run in parallel after EPIC-01. EPIC-04a's frozen JSON contract gates EPIC-04b. EPIC-05 merges transcription + diarization outputs (depends on EPIC-04b for the Swift `DiarizationResult` type). EPIC-07 can start with mock data early. EPIC-08 is the integration and validation capstone.

**Outstanding Work → v0.8**

- Package app as `.dmg` for distribution
- Define deployment config (DEP-XXX), monitoring (MON-XXX), runbooks (RUN-XXX)
- Code signing and notarization
- First-launch model download UX

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
