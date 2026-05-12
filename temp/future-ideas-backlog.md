# Future Ideas Backlog

> **Status**: Scratchpad — not promoted to PRD/EPIC yet.
> **Purpose**: Ideas surfaced during build that aren't first-release scope
> but are worth revisiting at v0.8/v0.9 or post-MVP. Promote to a real
> FEA/EPIC entry when prioritized; harvest or delete when stale.

---

## 1. Local-LLM Transcript Polish Pass

**Surfaced**: 2026-05-12 (during competitor read of Vox at vox.rizenhq.com)
**Status**: Deferred — not first-release scope
**Where it would live**: A new stage after EPIC-05 alignment, before EPIC-06 storage. Probably a new `TranscriptPolisher` protocol parallel to `TranscriptFormatter`, optional and feature-flagged.

**Idea**: Run a second pass over the formatted transcript using an
on-device LLM (Foundation Models framework on macOS 26+, or a small
quantized Gemma/Llama via MLX) to clean up filler words, false starts,
broken sentences, and run-on transcription artifacts. Output stays
human-readable markdown, speaker boundaries preserved.

**Why it might be worth doing**: Meeting transcripts have the same
readability issues Vox solves for dictation. A "Clean Read" toggle in
SCR-004 (transcript review) gives users a tidier export to Obsidian
without losing the verbatim source.

**Why it's not first-release**:

- First-release goal is personal daily-driver use; the raw aligned
  transcript is already useful enough for that.
- Multi-speaker meetings have a real hallucination risk that
  single-speaker dictation doesn't. An LLM polish that paraphrases
  beyond filler removal could mis-attribute speech or invent words.
  Needs careful prompt scoping, eval fixtures, and a side-by-side
  "before/after" diff in the UI — non-trivial scope.
- macOS 26 Foundation Models framework eligibility is the cleanest path
  (free, on-device, fits BR-101), but locks the feature to a newer
  macOS version than the current BR-201 floor (macOS 15).

**Concrete preconditions before promoting**:

- Define a `BR` rule about what the polish stage is *allowed* to change
  (filler removal yes; paraphrase no; restructuring no).
- Pick a runtime: Foundation Models (macOS 26+ only) vs. MLX-served
  local model (works on macOS 15+ but adds bundle weight).
- Build an eval set of 5–10 real meeting transcripts with ground-truth
  "good polish" comparisons.
- Add an `--polish` toggle to API-201 / a new API-203 contract.

**Linked refs**:

- Session decision: see /root/.claude/plans/i-agree-having-a-snappy-pelican.md
- Competitor product: Vox by Rizen HQ (local Mac dictation app using
  Gemma 4 / Apple Intelligence for the same polish-pass concept)

---

## How to use this file

When promoting an idea to real work:

1. Pick the next available FEA-XXX / CFD-XXX id from
   [`SoT.UNIQUE_ID_SYSTEM.md`](../SoT/SoT.UNIQUE_ID_SYSTEM.md).
2. Add the formal entry to the appropriate SoT/PRD location.
3. Remove the entry from this file (or strike it through and leave a
   pointer to where it landed).
