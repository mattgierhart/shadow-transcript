# Visual Prototype Gate — Transcript Shadow

> ## ⚠️ FULLY SUPERSEDED — 2026-05-16
>
> **The canonical visual SoT now lives at `design/visual-prototype/` (Claude Design handoff, all six screens + filmstrip + token sheet, no build step).** Open `design/visual-prototype/project/index.html` in any browser. See `design/visual-prototype/README.md` for the JSX → SwiftUI implementation map.
>
> This file is kept for historical reference only — it captures the v0.4 Stitch-based first attempt. **Do not regenerate prototypes from it.** The prompts below pre-date BR-501 (Minimal Recording UI) and the DES-105/DES-106 HUD recast; they describe the old "main window with waveform during recording" design that has been replaced.
>
> If you need to refresh the prototype: re-run Claude Design against the current SoT (see `design/visual-prototype/README.md` "How to update the prototype"), then replace `design/visual-prototype/` with the new handoff.

> **Date**: 2026-03-20 (original Stitch prompts); **Superseded**: 2026-05-16
> **Status**: Historical reference only — canonical visual SoT is `design/visual-prototype/`
> **Tool**: Google Stitch (no longer the primary visual workflow)
> **Screens**: 6 (SCR-001 through SCR-006)
> **Money Shot**: SCR-004 (Transcript View)

---

## Prototype Context Brief

Paste this once into Stitch before generating individual screens.

```
PRODUCT CONTEXT
Transcript Shadow is a local macOS app that records meeting audio, transcribes it with
speaker identification, and exports the result as markdown to Obsidian. All processing
happens on the user's machine — no cloud, no accounts, no data leaves the device.

PRIMARY USER
PER-001: Individual contributor (engineer, PM, designer) who attends 3-8 meetings/day.
Uses Obsidian as their knowledge base. High technical comfort. Wants "set and forget"
recording — hit record, do the meeting, review the transcript after.

DESIGN STYLE
Dark mode only. Minimal, living, listening. ElevenLabs UI aesthetic (dark, audio-centric,
high-contrast accents) combined with Obsidian's sidebar+content layout. Native macOS feel
using SF Pro and SF Mono. Teal (#2DD4BF) is the primary accent. Red (#EF4444) is used
ONLY for the record button. Muted pastel speaker colors on dark backgrounds.

The app has two density modes:
- SPACIOUS: During recording and processing — centered, generous whitespace, minimal
  elements. The user is in a meeting; the UI is peripheral, "alive but not demanding."
- DENSE: During transcript review — full-width content, tight spacing, information-rich.
  The call is over; the user is focused on the transcript.

Window layout: Persistent left sidebar (240px, Obsidian-style transcript history list)
with main content area on the right. macOS native toolbar at top.

Color tokens:
- Background: #0A0A0B (content), #141415 (sidebar)
- Accent: #2DD4BF (teal), #EF4444 (record red, record button only)
- Text: #F5F5F5 (primary), #A1A1AA (secondary), #52525B (muted)
- Borders: #1E1E20
- Speaker colors (muted pastels): #8BB8E8 (blue), #E8A87C (coral), #82D9A5 (mint),
  #C4A0E8 (lavender), #E8D482 (gold), #E88B9C (rose)
```

---

## Per-Screen Prompts

### Prompt 1: SCR-001 — Main Window (Idle)

```
SCREEN: SCR-001 — Main Window (Idle State)
Journey position: UJ-001, Step 1 of 10
User goal: Prepare to record a meeting
Situation: User just launched the app. No recording active. They have 3-4 past transcripts
in the sidebar.

Layout: macOS native window with toolbar at top, left sidebar (240px), right content area.

Key UI elements:
  - LEFT SIDEBAR (dark surface #141415):
    - Search bar at top (subtle, placeholder "Search transcripts")
    - Transcript list grouped by date ("Today", "Yesterday", "This Week")
    - Each item: title (primary text), date + "32 min · 3 speakers" (secondary text)
    - 3-4 sample items populated
  - TOP TOOLBAR (native macOS toolbar with traffic lights):
    - Left: mic icon + speaker icon (audio source indicators, both active/teal)
    - Center: large circular record button, red (#EF4444), 64px
    - Right: gear icon (settings), sidebar toggle icon
  - MAIN CONTENT AREA (dark #0A0A0B, SPACIOUS centered layout, 600px max-width):
    - Record button prominent center (if toolbar doesn't dominate enough, repeat here)
    - Subtle text below: "Ready to record"
    - Small text: "Microphone + System Audio"

Constraints: No cloud/upload indicators anywhere. Everything is local.
Emotional beat: Calm readiness. The app is quiet, waiting to listen.
Aesthetic: Dark, minimal, macOS native. Like Obsidian meets ElevenLabs.
```

### Prompt 2: SCR-002 — Recording View

```
SCREEN: SCR-002 — Recording View (Active Recording)
Journey position: UJ-001, Steps 3-4 of 10
User goal: Confirm the app is recording while they attend their meeting
Situation: User clicked record 4 minutes ago. They're in a Zoom call. This app is
a secondary window — they glance at it occasionally.

Layout: Same window — sidebar still visible, toolbar updated, content area shows recording.

Key UI elements:
  - TOP TOOLBAR:
    - Center: recording timer "04:23" in SF Mono, red dot indicator pulsing gently
    - Left: red square stop button (replaces record button), subtle pulse animation
    - "Microphone + System Audio" small label
  - MAIN CONTENT AREA (SPACIOUS, centered, 600px max-width):
    - Audio waveform visualization — horizontal bars, teal (#2DD4BF), full width
    - Bars animate at different heights showing real-time audio levels
    - Very generous whitespace above and below the waveform
    - Waveform is the ONLY element in the content area — nothing else
  - LEFT SIDEBAR: Same as SCR-001, still browsable

Constraints: Must feel "alive" — subtle animation on waveform bars. But NOT attention-
grabbing. Think ambient music visualizer, not EDM light show.
Emotional beat: Listening. Present but unobtrusive. A quiet heartbeat.
Aesthetic: Almost meditative. Dark, teal waveform glowing softly on black.
```

### Prompt 3: SCR-003 — Processing View

```
SCREEN: SCR-003 — Processing View
Journey position: UJ-001, Steps 5-8 of 10
User goal: Wait while the app processes their recording
Situation: User just stopped a 32-minute recording. They're between meetings or
wrapping up. Processing will take ~2 minutes.

Layout: Same window, sidebar visible, content area shows progress.

Key UI elements:
  - MAIN CONTENT AREA (SPACIOUS, centered, 600px max-width):
    - Three-stage pipeline progress, vertical stack, centered:
      - Stage 1: "Transcribing..." — teal progress bar at 67%, SF Symbol waveform icon
      - Stage 2: "Identifying speakers..." — gray, waiting (not started yet)
      - Stage 3: "Formatting transcript..." — gray, waiting
    - Each stage is a row: icon (left) + label (center) + percentage (right)
    - Active stage has teal (#2DD4BF) accent, completed stages show green checkmark
    - Below pipeline: "About 1 minute remaining" in muted text
    - Below that: "Cancel" button, very subtle/secondary style
  - LEFT SIDEBAR: Same, still browsable
  - TOP TOOLBAR: Processing indicator (spinning/pulsing teal dot)

Constraints: Cancel button should be understated — cancelling deletes the audio permanently.
Emotional beat: Patience and confidence. "It's working, almost there."
Aesthetic: Same spacious, centered feel as recording view. Clean transition.
```

### Prompt 4: SCR-004 — Transcript View (MONEY SHOT)

```
SCREEN: SCR-004 — Transcript View
Journey position: UJ-001 Step 9, UJ-002 Steps 1-5
User goal: Review speaker-labeled transcript, rename speakers, export to Obsidian
Situation: Processing just finished. User sees their meeting transcript for the first
time. The call is over — they're focused on this now.

THIS IS THE MONEY SHOT — the screen that communicates core product value.

Layout: Same window, sidebar visible (this transcript selected/highlighted in teal).
Content area switches to DENSE mode — fills available width, tight spacing.

Key UI elements:
  - TOP ACTION BAR (within content area, sticky top):
    - Left: metadata — "Mar 20, 2026 · 32 min · 3 speakers"
    - Right: action buttons —
      - "Export to Obsidian" (primary button, teal background #2DD4BF, white text)
      - "Copy" (secondary, ghost button with icon)
      - "Save As" (secondary, ghost button with icon)
  - SPEAKER SUMMARY ROW (below action bar):
    - Horizontal row of speaker pills:
      - "Alice" (soft blue #8BB8E8 pill, 18 min)
      - "Speaker 2" (soft coral #E8A87C pill, 11 min) — not yet renamed
      - "Speaker 3" (soft mint #82D9A5 pill, 3 min) — not yet renamed
    - Each pill is clickable (rename affordance on hover)
  - TRANSCRIPT BODY (scrollable, DENSE layout, full width):
    - Multiple transcript blocks (DES-003), each block is one speaker turn:
      - Speaker pill (colored, e.g., blue "Alice") + timestamp "[00:01:23]" in SF Mono muted
      - Text content below: "Thanks everyone for joining. Let's go through the sprint
        review. First up, the authentication work..."
    - Blocks separated by 8px gap, thin border-bottom (#1E1E20)
    - Show 4-5 visible blocks with different speakers alternating
    - Text is readable, clean, 16px SF Pro
  - LEFT SIDEBAR: This transcript highlighted in teal in the list

Constraints: Must render speaker labels in muted pastel colors. Transcript text respects
system text size settings. Export button is the most prominent CTA on the page.
Emotional beat: Satisfaction and clarity. "This is exactly what was said, organized and
ready to go."
Aesthetic: DENSE but clean. Like reading a well-formatted chat log. Dark, professional.
```

### Prompt 5: SCR-005 — Settings Sheet

```
SCREEN: SCR-005 — Settings Sheet (Overlay)
Journey position: UJ-003, Steps 3-6
User goal: Configure audio sources, Obsidian vault path, and transcription model
Situation: User opened settings via Cmd+, or the gear icon. This is a macOS sheet
overlay on top of the main window (dimmed behind).

Layout: macOS native sheet, centered over window. Max-width 560px. Rounded corners.
Background slightly lighter than main (#141415). Main window dimmed behind.

Key UI elements:
  - SHEET HEADER: "Settings" title, close button (X) top-right
  - SECTION: Audio
    - "Microphone" — dropdown showing system audio devices
    - "System Audio" — toggle switch (on/teal), with status "Permission granted ✓"
  - SECTION: Transcription
    - "Whisper Model" — segmented control or dropdown:
      - "base.en" (148 MB, fastest) — selected, checkmark
      - "small.en" (488 MB, better accuracy)
      - "medium.en" (1.5 GB, best accuracy) — "Download" button
  - SECTION: Export
    - "Obsidian Vault" — folder path display + "Choose..." button
      - Shows: "/Users/matt/Documents/Obsidian Vault"
    - "Subfolder" — text field, value "Meetings"
    - "Auto-export after processing" — toggle switch (off)
  - SECTION: Privacy (subtle, informational)
    - Shield icon + "All processing happens locally on your Mac"
    - "Audio files are automatically deleted after processing"
    - Muted text, not toggles — these are guarantees, not settings

Constraints: Audio deletion is not optional (BR-102). Show as informational, not toggle.
Emotional beat: Control and transparency. "I know exactly what this app does with my data."
Aesthetic: Standard macOS settings sheet. Clean, familiar, unambiguous. Not flashy.
```

### Prompt 6: SCR-006 — Sidebar (Transcript History)

```
NOTE: SCR-006 is the sidebar component (DES-004), already visible in all other screens.
Generate this as a DETAIL VIEW of the sidebar in isolation, showing its states.

SCREEN: SCR-006 — Sidebar Transcript History (Detail)
Purpose: Show the sidebar component in detail with multiple states

Layout: Single sidebar panel, 240px wide, full window height. Dark surface (#141415).

Key UI elements:
  - SEARCH BAR (top): Subtle input with magnifying glass icon, placeholder "Search transcripts"
  - TRANSCRIPT LIST (grouped by date):
    - Group header: "Today" (muted text, small caps)
      - Item 1: "Sprint Review" — "10:30 AM · 32 min · 3 speakers" (SELECTED — teal tint)
      - Item 2: "1:1 with Sarah" — "2:15 PM · 18 min · 2 speakers"
    - Group header: "Yesterday"
      - Item 3: "Product Roadmap" — "11:00 AM · 45 min · 4 speakers"
      - Item 4: "Design Review" — "3:30 PM · 22 min · 2 speakers"
    - Group header: "This Week"
      - Item 5: "Team Standup" — "Mon · 12 min · 5 speakers"
  - CONTEXT MENU (right-click on item, show as overlay):
    - "Export to Obsidian"
    - "Delete Transcript" (red text)
  - RESIZE HANDLE: Right edge, subtle drag indicator

Show three states side by side if possible:
  1. Normal (items listed, one selected)
  2. Search active (filtered results, search text "sprint")
  3. Empty ("No transcripts yet. Record your first meeting." with subtle illustration)

Aesthetic: Obsidian file explorer vibe. Dark, clean, functional grouping.
```

---

## Money Shot

**SCR-004 (Transcript View)** is the Money Shot.

This is the frame to screenshot for:
- Landing page hero image
- Product Hunt listing
- README.md demo
- Any stakeholder pitch

It communicates the core value proposition in one glance: a clean, speaker-labeled transcript with one-click Obsidian export. The muted pastel speaker pills, the timestamps in monospace, the teal "Export to Obsidian" button — this is what the product delivers.

---

## Feedback Capture Template

After prototype screens are generated, use this table to capture review feedback. Route each item back to a specific SoT ID.

| # | Screen | Feedback | Severity | Routes To | Disposition |
|---|--------|----------|----------|-----------|-------------|
| 1 | SCR-001 | | | SCR-001 / DES-XXX | Pending |
| 2 | SCR-002 | | | SCR-002 / DES-XXX | Pending |
| 3 | SCR-003 | | | SCR-003 / DES-XXX | Pending |
| 4 | SCR-004 | | | SCR-004 / DES-XXX | Pending |
| 5 | SCR-005 | | | SCR-005 / DES-XXX | Pending |
| 6 | SCR-006 | | | SCR-006 / DES-XXX | Pending |
| 7 | General | | | DES-301→305 | Pending |

**Disposition options**: Accept (update SoT), Defer (backlog), Reject (no change)

---

## Stitch Workflow

1. Paste the **Prototype Context Brief** into Stitch as the opening context
2. Generate screens in this order (follows UJ-001 journey flow):
   - SCR-001 (idle) → SCR-002 (recording) → SCR-003 (processing) → SCR-004 (transcript)
   - Then SCR-005 (settings) and SCR-006 (sidebar detail)
3. Refine each screen individually before moving to the next
4. Export Money Shot (SCR-004) at highest resolution
5. Complete Feedback Capture Template after stakeholder review

---

## Quality Gate Checklist (v0.4 → v0.5)

- [ ] All 6 SCR- entries have a corresponding visual prototype screen
- [ ] At least one stakeholder has reviewed the prototype
- [ ] Feedback Capture Template completed with disposition for each item
- [ ] Money Shot (SCR-004) captured and saved
- [ ] No blocking feedback items remain open
