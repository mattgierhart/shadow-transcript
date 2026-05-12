---
template_version: "3.0.0"
---

# EPIC-07 SwiftUI Interface

> **State**: `Active (next up — Mac required)`
> **Lifecycle**: v0.7 Build Execution (See `README.md`)
> **Epic Lead**: TBD
> **Depends On**: EPIC-02 (audio capture services), EPIC-05 (`FormattedTranscript`), EPIC-06 (`TranscriptStore` + `SettingsStore` + `ObsidianExporter`)
> **Environment Requirement**: macOS 15+ with Xcode 16+. The previous EPICs were built in a Linux-sandboxed Claude Code session; **EPIC-07 cannot be — SwiftUI previews, AppKit interop, audio permission prompts, and ScreenCaptureKit picker UI all require a Mac.** This EPIC is the natural pause point for "verify EPIC-01..06 on the real Mac before stacking the UI."

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-12 — EPIC-06 merged (PR #7). EPIC-07 is now Active. No SwiftUI code yet.
- **Stopping Point**: N/A — not yet started.
- **Next Steps**:
  1. **First** — on the Mac Studio, run `xcodegen generate && xcodebuild test -scheme TranscriptShadow -destination 'platform=macOS,arch=arm64'`. Verify all EPIC-01..06 XCTests are green. If anything is red, fix it before touching EPIC-07 — building UI on top of broken services compounds errors.
  2. Run the EPIC-05 Codex Gate 3 review (single-ask prompt in the EPIC-05 Phase D notes) and EPIC-06 Codex Gate 4 review (sketched at the bottom of this file).
  3. Read SCR-001..006 + DES-XXX + the v0.4 visual identity in PRD.md. Open the ElevenLabs UI reference at <https://ui.elevenlabs.io/docs/>.
  4. Phase A planning (see Execution Plan below).
- **Context**: Largest Linux-blind risk of any remaining EPIC. SwiftUI previews and the actual permission prompts (mic + Screen Recording) cannot be simulated. Plan to ship the UI shell with mock data first, then wire to real services. Dependency injection is critical so the shell can be previewed without a real `AudioCaptureService` or model download.

---

## Cumulative Carry-Forward from EPIC-01 → EPIC-06

> Read once, then `<!-- HANDOFF -->` past.

**Concurrency / Swift 6 strict mode**:

- Non-Sendable Apple/3rd-party types (`AVAudioPCMBuffer`, `WhisperKit`, `Process`, `GRDB.DatabaseQueue` internals) don't cross actor boundaries cleanly. Use `@unchecked Sendable` envelope structs OR `final class` + `NSLock.withLock { … }` instead of `actor`. Document the choice inline.
- **SwiftUI specifically**: `@MainActor` view models that own non-Sendable services need an `@MainActor` boundary. Services exposed through their protocols (`TranscriptionService`, `AudioCaptureService`, `TranscriptStore`, `SettingsStore`, `ObsidianExporter`) are all `Sendable` — safe to `await` from a `@MainActor` view model.
- For long-running progress streams (capture levels, transcription progress), use `AsyncStream<Float>` and `for await`. Bridge to `@Published`/`@State` on the MainActor.

**Service patterns the UI consumes**:

- `AudioCaptureService` (API-001) — `startCapture(configuration:) async throws` → `stopCapture() async throws -> URL`; emits `audioLevels()` + `milestones()` streams.
- `TranscriptionService` (API-101) — `transcribe(audioURL:model:progress:)` with progress callback. UI binds progress to DES-102 (Progress Pipeline).
- `DiarizationService` (API-102) — same shape; UI runs after transcription per ARC-001.
- `TranscriptFormatter` (API-201) — synchronous; one call, returns `FormattedTranscript`.
- `TranscriptStore` (API-006) — `save` / `list` / `search` / `markExported` / `delete`. SCR-006 (history sidebar) consumes `list` and `search`.
- `SettingsStore` (API-006) — typed `SettingKey` accessors. SCR-005 reads/writes every persisted setting.
- `ObsidianExporter` (API-202) — synchronous; SCR-004 export button drives it after a `markExported` call.

**Dependency injection for previews**:

- Every service is a protocol. Build `Mock<Service>` doubles for SwiftUI previews so screens preview without WhisperKit downloads, pyannote subprocess launches, or filesystem writes.
- Place mocks in a `TranscriptShadow/Previews/` directory (gated by `#if DEBUG`).

**Permissions UX (RISK-002, RISK-004)**:

- Microphone (`NSMicrophoneUsageDescription` in Info.plist) — triggered by `AudioCaptureService.startCapture` first call.
- Screen Recording (for ScreenCaptureKit system-audio capture) — Apple does not provide a programmatic request API; users must go to System Settings. SCR-005 needs an explicit "Open System Settings" deep link + a status indicator. Reference DES-103.
- First-launch onboarding for these is a P0 deliverable (RISK-004 mitigation).

**ElevenLabs UI reference**:

- Dark mode only (per v0.4 Visual Identity in PRD.md). Minimal, audio-centric, spacious during capture / dense during review.
- Reference: <https://ui.elevenlabs.io/docs/>. Adapt motifs (round record button glow, spectrum-style level meter), don't copy verbatim.

**Codex review cadence (mandatory)**:

- Six EPICs since EPIC-02 have shipped with a Codex pass surfacing real bugs. EPIC-07 must too. Single-ask scope suggestion at the bottom of this file.

<!-- HANDOFF -->

---

## Objective & Scope

> **Goal**: Implement all six screens (SCR-001..006) in SwiftUI, wired to EPIC-02/03/04/05/06 services through their protocols. Completes user journeys UJ-001 (record → transcribe → view), UJ-002 (rename + export), UJ-003 (configure settings).

### Deliverables

- [ ] **SCR-001 Main Window (idle)** — record button (DES-001), sidebar with transcript history (DES-004), toolbar (DES-005). Default view on launch.
- [ ] **SCR-002 Recording View** — active state: audio level meter (DES-002), elapsed timer, stop button. Replaces SCR-001 main content during capture.
- [ ] **SCR-003 Processing View** — pipeline progress (DES-102) across transcribe + diarize + format + save + (optional) export stages. Cancellation supported.
- [ ] **SCR-004 Transcript View** — speaker-labeled markdown rendering (DES-003 + DES-101), inline speaker rename, "Export to Obsidian" button, copy-to-clipboard, delete.
- [ ] **SCR-005 Settings Sheet** — audio input device picker, system-audio toggle, vault path picker, vault subfolder, Whisper model selector, auto-export toggle, permission status indicators (DES-103 for prompts).
- [ ] **SCR-006 Transcript History Sidebar** — list view sorted by date desc, search bar (FTS), context menu (rename / export / reveal in Finder / delete), empty state (DES-104).
- [ ] **DES tokens** — color palette (DES-301), typography (DES-302), spacing (DES-303), borders/elevation (DES-304), status colors (DES-305) implemented as Swift constants under `TranscriptShadow/Design/`.
- [ ] **DES components** — DES-001..104 implemented as reusable SwiftUI views.
- [ ] **First-launch onboarding** — guided flow covering Microphone + Screen Recording + vault path. Mitigates RISK-004.
- [ ] **Preview support** — mock service implementations enable SwiftUI previews for every screen.
- [ ] **Tests** — view-model logic tests (no UI testing yet — that's EPIC-08 if at all). Manual smoke walkthrough of UJ-001 / UJ-002 / UJ-003 documented in Phase D.

### Out of Scope

- Pipeline orchestrator and temp-audio lifecycle — EPIC-08
- Real-audio end-to-end pipeline test — EPIC-08
- UI automation / snapshot tests — explicit non-goal (deferred)
- Menu bar app mode — explicit non-goal (per EPIC-07's original Out of Scope)
- Keyboard shortcut customization — explicit non-goal

---

## Context & IDs

- **Screens**: SCR-001, SCR-002, SCR-003, SCR-004, SCR-005, SCR-006
- **Design Components**: DES-001 (Record Button), DES-002 (Audio Level), DES-003 (Transcript Block), DES-004 (Sidebar List), DES-005 (Toolbar), DES-101 (Speaker Label), DES-102 (Progress Pipeline), DES-103 (Permission Prompt), DES-104 (Empty State)
- **Design Tokens**: DES-201..203 (layout), DES-301..305 (color, typography, spacing, borders, status)
- **User Journeys**: UJ-001, UJ-002, UJ-003
- **Personas**: PER-001, PER-002
- **Services consumed** (all protocols): `AudioCaptureService`, `TranscriptionService`, `DiarizationService`, `TranscriptFormatter`, `TranscriptStore`, `SettingsStore`, `ObsidianExporter`
- **Risks**: RISK-002 (macOS 15 audio capture floor — UI surfaces requirement), RISK-004 (Screen Recording permission friction — onboarding mitigation)

---

## Execution Plan (The 5 Phases)

### Phase A: Plan (~1 sitting on Mac)

- [ ] Run full XCTest suite first; confirm 137+ tests green
- [ ] Run Codex Gate 3 (EPIC-05) and Codex Gate 4 (EPIC-06); resolve P0/P1 findings
- [ ] Read SCR-001..006 + DES-XXX + v0.4 Visual Identity (PRD.md)
- [ ] Sketch the navigation shape (probably `NavigationSplitView` with sidebar + detail) and the state machine for SCR-001 → 002 → 003 → 004 transitions
- [ ] Decide where the pipeline orchestrator lives. **Tentative**: EPIC-07 has a thin `PipelineCoordinator` for UI state; EPIC-08 owns the production orchestrator with audio lifecycle. Defer the call to Phase B if unclear.

### Phase B: Design

- [ ] Define design tokens (`DES-301..305`) as Swift constants
- [ ] Define `AppEnvironment` (the dependency container) with protocol-typed services + mock factory
- [ ] Define view-model interfaces per screen (probably one `*ViewModel` `@MainActor` `final class` each, all conforming to `ObservableObject`)
- [ ] Decide preview strategy — `#if DEBUG` mocks + `PreviewProvider` per screen

### Phase C: Build

**Context Window 1: Design system + tokens + previews scaffolding**

- [ ] `TranscriptShadow/Design/Colors.swift`, `Typography.swift`, `Spacing.swift` (DES-301..303)
- [ ] `TranscriptShadow/Design/Components/` — DES-001 (RecordButton), DES-002 (AudioLevelMeter), DES-003 (TranscriptBlock), DES-101 (SpeakerLabel), DES-102 (ProgressPipeline), DES-103 (PermissionPromptView), DES-104 (EmptyStateView), DES-004 (TranscriptSidebarRow), DES-005 (Toolbar)
- [ ] `TranscriptShadow/Previews/` mocks for every service protocol

**Context Window 2: Recording + Processing + Transcript flow (UJ-001)**

- [ ] `MainWindow.swift` (SCR-001) with state machine
- [ ] `RecordingView.swift` (SCR-002) — level meter, timer, stop button
- [ ] `ProcessingView.swift` (SCR-003) — progress pipeline with cancel
- [ ] `TranscriptView.swift` (SCR-004) — markdown rendering, speaker rename, export button
- [ ] `RecordingViewModel`, `ProcessingViewModel`, `TranscriptViewModel` — wired to real services via `AppEnvironment`

**Context Window 3: Settings + History (UJ-002, UJ-003)**

- [ ] `SettingsView.swift` (SCR-005) — bound to `SettingsStore` typed keys
- [ ] `TranscriptHistoryView.swift` (SCR-006) — `list` + `search` via `TranscriptStore`; context menu
- [ ] First-launch onboarding (permissions + vault path)
- [ ] Empty states + error states

### Phase D: Validate

- [ ] All ViewModel unit tests pass
- [ ] Manual walkthrough of UJ-001 (record → see transcript), UJ-002 (rename → export to a real local Obsidian vault → confirm file in vault), UJ-003 (settings round-trip + permission status display)
- [ ] Dark mode renders correctly; no light-mode leakage
- [ ] Verify processed transcript renders correctly in Obsidian's reading view
- [ ] **Codex review (mandatory, single-ask)**:
  > "Find bugs in the EPIC-07 SwiftUI layer that EPIC-01..06 lessons should have prevented — Sendable boundary violations between view models and services, missing cancellation propagation from SCR-003's cancel button to the AsyncTaskQueue, race between SCR-006's list refresh and a save in progress, settings round-trip via `SettingsStore` not surviving app relaunch, permission status reading stale value, speaker-rename UI mutating `FormattedTranscript` without re-saving via `TranscriptStore`. P0/P1/P2, file:line, no fixes."
  Pre-flight via `/codex-budget-check check codex-review`.
- [ ] Code traceability: `// @implements SCR-XXX` / `// @implements DES-XXX` on each view

### Phase E: Finish (Harvest)

- [ ] Update SCR-001..006 + DES-XXX statuses in SoT files (→ Implemented)
- [ ] Append Lifecycle Change Log row in `PRD.md`
- [ ] Update README backlog: EPIC-07 ✅ Complete, Active EPIC → EPIC-08
- [ ] Commit, push, draft PR

---

## Risk callouts specific to this EPIC

| Risk | Mitigation |
|---|---|
| First-launch permission denial leaves app unusable | RISK-004 mitigation: clear onboarding + deep link to System Settings + mic-only fallback. Test the denied-then-granted path. |
| Speaker rename UI desyncs from stored data | Rename must call `TranscriptStore.update` (new method? see Phase A) atomically. Don't keep an in-memory copy that diverges. |
| Long transcripts (1hr+ meetings) lag the markdown renderer | Use `TextEditor` or paginated `LazyVStack`. Test with the longest fixture. |
| Settings panel writes before EPIC-08 wires vault-path to `ObsidianExporter` | Settings UI must validate that vault path exists + is writable. Surface error state inline. |

---

## Codex Gate 5 single-ask (sketch)

> "Find bugs in the EPIC-07 SwiftUI layer that EPIC-01..06 lessons should have prevented — Sendable boundary violations between view models and services, missing cancellation propagation from SCR-003's cancel button to the AsyncTaskQueue, race between SCR-006's list refresh and a save in progress, settings round-trip via `SettingsStore` not surviving app relaunch, permission status reading stale value, speaker-rename UI mutating `FormattedTranscript` without re-saving via `TranscriptStore`, dark-mode color leakage, preview crashes from missing mock services. P0/P1/P2, file:line, no fixes."

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-03-20 | Claude Agent | Created EPIC |
| 2026-05-12 | Claude Agent | Mac-handoff prep: filled session state, cumulative carry-forward block, deliverables list per SCR, 5-phase execution plan, EPIC-specific risk callouts, Codex Gate 5 single-ask sketch. EPIC-07 is now ready for a Mac session to pick up. |
