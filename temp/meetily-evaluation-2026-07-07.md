# Meetily Fork/Replicate Evaluation

> **Date**: 2026-07-07
> **Status**: Analysis complete — decision pending (user)
> **Question**: Should we fork or replicate [Meetily](https://github.com/Zackriya-Solutions/meetily) as a "production ready" base and add our features (notably speaker identification) on top, instead of finishing the current development path?
> **Related**: EPIC-09 (active), `temp/codebase-review-2026-05-30.md`, PRD v0.7

---

## Executive Summary

**Recommendation: Do not fork or replicate Meetily. Stay the course, and harvest specific ideas from it instead.**

The question's premise inverts under scrutiny, on two independent grounds:

1. **The Meetily code you can actually fork does not contain the features we'd fork it for.** Speaker diarization — the headline feature in Meetily's GitHub tagline — lives in their **proprietary Pro edition**, a separate closed codebase. The MIT-licensed Community Edition on GitHub has **no diarization, no Obsidian export, no calendar/auto-join**. Forking it gets us a v0.4 beta in a foreign stack (Rust/Tauri/Next.js) with *none* of our differentiators.

2. **Transcript Shadow is not early-stage — it is ~90% complete.** EPIC-01→08 are done, EPIC-09 is active, and **213 XCTests pass on a real Mac**, including the full pipeline: capture → WhisperKit transcription → **pyannote diarization** → alignment → SQLite/FTS5 → **Obsidian export** → on-device summarization. The one thing Meetily's OSS code lacks (speaker ID) is precisely the thing we have already built and tested (EPIC-04a/04b/05). What remains on our path is a manual Mac validation walkthrough and release packaging — not feature development.

Switching would mean discarding ~9.5k LOC of working Swift (+ ~4.9k LOC of tests) to adopt a beta base, then **rebuilding diarization and Obsidian export from scratch** in Rust/TypeScript. That is strictly slower than finishing the two remaining gates on the current path.

Meetily is still valuable to us — as a harvest source and a benchmark, not a base. See §6.

---

## 1. What Meetily Actually Is

**Sources**: [repo](https://github.com/Zackriya-Solutions/meetily) · [LICENSE](https://raw.githubusercontent.com/Zackriya-Solutions/meetily/main/LICENSE.md) · [v0.4.0 release](https://github.com/Zackriya-Solutions/meetily/releases/tag/v0.4.0) · [architecture.md](https://raw.githubusercontent.com/Zackriya-Solutions/meetily/main/docs/architecture.md) · [meetily.ai](https://meetily.ai/) · [Show HN](https://news.ycombinator.com/item?id=43137186)

A privacy-first, local AI meeting assistant (Otter.ai/Granola alternative) by **Zackriya Solutions**, a small (~8-person) AI consulting agency in India. Two editions:

| | Community Edition (the forkable repo) | Pro (proprietary, $10/user/mo) |
|---|---|---|
| License | **MIT** (verified from LICENSE.md) | Closed — "built on a different codebase" |
| Version | v0.4.0 (2026-06-05) | v1.7.7 (versions independently) |
| Diarization | ❌ **Not included** | ✅ Planned/landing (NVIDIA Sortformer approach) |
| Auto-join / calendar | ❌ | ✅ |
| Advanced export (PDF/DOCX/MD) | ❌ | ✅ |
| Chat-with-meeting, templates | ❌ | ✅ |

**Community Edition feature set**: simultaneous mic + system-audio capture (loopback, no bot), real-time local transcription (whisper.cpp or NVIDIA Parakeet, 99+ languages, GPU-accelerated), audio import/re-transcribe ("Import & Enhance", beta), summarization via pluggable LLM providers (Ollama local, Claude, Groq, OpenRouter, any OpenAI-compatible), local SQLite storage, BlockNote transcript editor.

**Stack**: Tauri (Rust core, ~46%) + Next.js/React/TypeScript (~30%) + whisper.cpp C++ (~10%) + small Python/ONNX helpers. Single unified desktop binary since v0.1.1 (no server). macOS and Windows first-class installers; Linux is build-from-source.

**Maturity**: ~20k stars, ~2k forks, roughly monthly releases over the past year, active issue flow with current traffic (issues filed the week of this analysis). Also: **~177 open issues**, pre-1.0, "Import & Enhance" explicitly beta, current open bugs in VAD (Windows, #578) and Linux GPU offload (#552). Independent reviews note local-LLM summary quality degrades on long/multi-topic meetings.

**Reality check on "production grade"**: it is a well-marketed, genuinely active **beta**. The marketing (including the GitHub tagline "…with speaker diarization…") describes the commercial Pro product; the repo is a deliberately scoped-down community edition. The vendor's engineering velocity is visibly concentrated on the closed Pro track (Pro at v1.7.7 vs OSS at v0.4.0).

---

## 2. Where Transcript Shadow Actually Stands

Current state (see `README.md` dashboard, `epics/EPIC-09-summary-and-release-validation.md`):

- **EPIC-01→08 complete; EPIC-09 (on-device summary + Mac validation) active.** PRD at v0.7 Build Execution, closing the v0.7→v0.8 gate.
- **213 XCTests green on a real Mac** (macOS 26.5 / Xcode 26.4.1), including the live Apple Foundation Models summarization path (~2.9 s).
- ~9,544 LOC app Swift across 87 files, ~4,879 LOC tests across 37 files, ~793 LOC Python sidecar.
- Every P0 feature is implemented: FEA-001 capture, FEA-002 transcription, **FEA-003 diarization**, FEA-004 markdown, **FEA-005 Obsidian export**, FEA-006 history, FEA-007 summary (P1).

**What actually remains on the current path**:

1. **EPIC-09 Phase D (manual, device-bound)**: real-audio E2E, TEST-504 no-network probe (BR-101/104 release blocker), KPI-001/KPI-002 baselines, RISK-008 notch-HUD/fullscreen probe, cancel/force-quit orphan checks. Blocked only on Mac hands-on time, not code.
2. **EPIC-10 (future)**: Developer ID signing + notarization, first real PyInstaller sidecar build (RISK-001 RTF and RISK-003 bundle size are still estimates), first-launch model-download UX.

Honest caveats on our side: diarization **accuracy** (KPI-002 >80%) and pipeline **speed** (KPI-001 <5 min/30-min) have never been empirically measured, and the sidecar bundle has never been built. These are validation risks — but switching to Meetily doesn't retire any of them; it deletes the code they'd validate.

---

## 3. Requirement Fit Matrix

Meetily **Community Edition** (the only forkable code) vs. our locked requirements:

| Requirement | Ours | Meetily CE | Fit |
|---|---|---|---|
| FEA-001 Mic + system audio capture (P0) | ✅ Built (ScreenCaptureKit, TECH-004) | ✅ Has it (cross-platform loopback) | ✅ |
| FEA-002 Local transcription w/ timestamps (P0) | ✅ Built (WhisperKit/CoreML/ANE) | ✅ Has it (whisper.cpp/Parakeet) | ✅ |
| **FEA-003 Speaker diarization (P0)** | ✅ **Built** (pyannote sidecar + `WordSpeakerAligner` + inline rename UJ-002) | ❌ **Pro-only, proprietary** | ❌ **Fatal gap** |
| FEA-004 Speaker-labeled markdown (P0) | ✅ Built | ❌ No speakers to label; advanced export is Pro | ❌ |
| **FEA-005 Obsidian export w/ frontmatter (P0)** | ✅ Built (INT-001 YAML frontmatter) | ❌ Absent | ❌ |
| FEA-006 Transcript history + search (P1) | ✅ Built (GRDB + FTS5) | ✅ Has local SQLite history | ✅ |
| FEA-007 On-device summary (P1) | ✅ Built (Foundation Models + extractive fallback, BR-104: no network) | ⚠️ Has summaries, but default paths include **cloud** providers (Claude/Groq/OpenRouter); Ollama-local possible | ⚠️ |
| BR-101 All processing local, no network in pipeline | ✅ Core guarantee (TEST-504 probe pending) | ⚠️ Local by default, but cloud LLM paths built in — we'd have to strip/gate them | ⚠️ |
| BR-201/401 macOS-native, Apple Silicon | ✅ Swift 6/SwiftUI native | ❌ Cross-platform Tauri (Rust + web frontend) — explicitly *not* our direction (native feel is a stated identity: "not a web app port", PRD v0.4) | ❌ |
| BR-203 Single-user, no accounts | ✅ | ✅ | ✅ |
| BR-501 HUD-only during recording (notch HUD DES-105/106) | ✅ Built | ❌ Conventional window/tray app | ❌ |
| TECH-001→008 stack decisions (v0.5 gate) | Swift/WhisperKit/pyannote/GRDB — all selected deliberately, permissive licenses | Rust/Tauri/whisper.cpp/Next.js — would void TECH-001→007 and the v0.5/v0.6 gates | ❌ |
| License posture (MIT preferred; GPL rejected before — PRD.md:301) | MIT | ✅ MIT (CE only) | ✅ |

**Score**: of our five P0 features, Meetily CE ships two (capture, transcription) — the two we also finished over a year of EPICs ago — and lacks the three that define the product (diarization, speaker-labeled markdown, Obsidian export).

---

## 4. Cost Comparison: Finish vs. Switch

**Path A — Finish current app** (recommended):
- EPIC-09 Phase D: one or two hands-on Mac sessions (record → validate → measure KPIs → probes). No new code expected beyond fixes.
- EPIC-10: packaging/signing/notarization + first sidecar bundle build. Bounded, well-scoped, already sketched in EPIC-09 §Follow-on.
- Risk: KPI-002 accuracy could disappoint → mitigations already specced (RISK-005 manual rename backstop; WeSpeaker alternative noted in PRD).

**Path B — Fork Meetily CE**:
- Learn + own a Rust/Tauri/Next.js/C++ toolchain (cross-platform build, signing, ONNX runtimes) we have zero code in.
- **Rebuild FEA-003 from scratch** in that stack (Sortformer or pyannote via Python interop — the same sidecar problem we already solved, now in Rust). Their own ecosystem reports Parakeet/Sortformer alignment "speaker drift" problems on overlapping speech — the exact problem class our `WordSpeakerAligner` + golden fixtures already handle.
- **Rebuild FEA-005** (Obsidian export + frontmatter), FEA-004, BR-501 HUD UX; strip/gate cloud LLM paths to honor BR-101.
- Track a fast-moving upstream beta whose vendor's incentive is the closed Pro edition (our fork diverges immediately and permanently).
- Throw away: 213 passing tests, the SoT contract system's mapping to real code, and the entire v0.5–v0.7 decision record.

**Path C — Replicate (rebuild Meetily-like app ourselves)**: strictly worse than both — all of Path B's rebuild cost with none of the existing community code maturity.

There is no plausible accounting where Path B or C is "quicker": the parts of Meetily that work (capture, transcription) duplicate what we have; the parts we need (diarization, Obsidian) aren't in it.

---

## 5. What Meetily's Existence Tells Us (Strategic Read)

- **It validates the market thesis** (v0.2): 20k stars and 280k claimed downloads for "privacy-first local meeting notes" confirms demand for exactly our category.
- **It validates our niche positioning**: the open-source field's most popular entrant ships **without** diarization and **without** Obsidian integration in its free tier — our two differentiators remain differentiated. The privacy + speaker-ID + Obsidian intersection is still underserved.
- **It sets a benchmark**: their published performance/behavior (real-time transcription, GPU accel) is a useful reference when we measure KPI-001.
- **Pricing signal** (for whenever monetization guardrails lift): diarization is what Meetily itself gates behind $10/user/mo — i.e., the market leader prices the feature we give away as our core.

---

## 6. Harvest List (Value Without Forking)

Candidates for `temp/future-ideas-backlog.md` / post-MVP roadmap (Deployment 3):

| Idea | Meetily reference | Maps to |
|---|---|---|
| Real-time/streaming transcription during recording | whisper.cpp streaming in Tauri app | Roadmap Deployment 3 ("real-time transcription"); currently an explicit MVP non-goal |
| "Import & Enhance" — import an existing audio file; re-transcribe with a different model/language | Their beta feature | New FEA candidate; low-cost given our pipeline takes a WAV path in |
| Provider-agnostic summarizer abstraction | Their Ollama/Claude/Groq/OpenRouter layer | If BR-104 ever relaxes to allow *local* Ollama as a second on-device engine; architecture pattern only |
| VAD + audio ducking/clip-prevention in the mixer | Their capture layer | API-002 AudioMixer polish |
| Multi-language summaries / 99-language transcription | v0.4.0 release | Post-MVP (BR-202 currently English-only) |
| Opt-in local analytics | v0.4.0 release | KPI-003 measurement (local counter) |

**Adjacent projects surfaced during research** (track, don't adopt):
- **Hyprnote / Anarlog** (fastrepl, YC S25, MIT) — closest OSS competitor, local-first notepad model.
- **OpenWhispr** (MIT) — advertises diarization + calendar in OSS; worth a look at their diarization UX.
- **WhisperX** (BSD) — Whisper + word timestamps + pyannote diarization as a library; a reference implementation for our alignment approach, not a replacement.

---

## 7. Decision Options

| Option | Description | Assessment |
|---|---|---|
| **A. Stay the course** (recommended) | Finish EPIC-09 Phase D on the Mac, then EPIC-10 packaging. Log harvest items to `temp/future-ideas-backlog.md`. | Fastest path to a working daily driver; preserves all differentiators and 213-test asset. |
| B. Hybrid harvest | Stay the course + immediately spec 1–2 Meetily-inspired features (Import & Enhance, real-time) as post-v0.8 EPICs. | Fine, but don't let it delay the v0.8 gate; harvest list already captures this. |
| C. Switch to Meetily fork | Adopt CE, rebuild diarization + Obsidian + HUD UX in Rust/Tauri. | Rejected per §3–4: months of rebuild to end up behind where we are today. |

**Next step if Option A/B**: no PRD change required. Optionally add a Lifecycle Change Log row noting this evaluation (competitive analysis was previously "skipped per project guardrails"; this doc is the first real competitive data point and could seed v0.9 GTM positioning later).

---

*Analysis by Claude agent, 2026-07-07. Web sources checked: Meetily repo/README/LICENSE/releases/issues, meetily.ai, docs/architecture.md, Hacker News (Show HN thread), third-party reviews (thewindowsclub, anarlog.so, openalternative.co). Repo state from README.md, PRD.md, epics/EPIC-09.*
