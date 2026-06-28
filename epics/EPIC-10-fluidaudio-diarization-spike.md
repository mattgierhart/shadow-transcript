---
template_version: "3.0.0"
---

# EPIC-10 FluidAudio Native Diarization Spike

> **State**: `Planned` (Spike — investigative, time-boxed) > **Lifecycle**: v0.7 Build Execution (research input; does **not** advance a gate on its own)
> **Epic Lead**: Build (spike)
> **Depends On**: EPIC-04a/04b (the `DiarizationService` seam this spike plugs into)
> **Blocks**: a future `TECH-009` decision + a possible EPIC to productionize the winner
> **Environment Requirement**: macOS 15+ with Xcode 16+. No Python toolchain needed for the spike path (that's the point).

---

<!-- SECTION: session-state -->
## Session State (The "Brain Dump")

> **Crucial**: Update this section before ending every session.

- **Last Action**: EPIC drafted (2026-06-28). Origin: a review of [purr](https://github.com/iamarunbrahma/purr), a local-only macOS meeting tool that does speaker diarization natively in Swift on the Apple Neural Engine via [FluidAudio](https://github.com/FluidInference/FluidAudio) — no Python sidecar. Our diarization is a PyInstaller-bundled pyannote sidecar (`PyannoteSidecarDiarizationService`, TECH-006 / ARC-002), which is the source of our two highest-scored risks (`RISK-001` pyannote CPU-only/slow = 4.5; `RISK-003` large bundle = 3.0).
- **Stopping Point**: No code written. Spike not yet started.
- **Next Steps**: Begin **Phase C / Context Window 1** — add the FluidAudio SPM dependency on this spike branch only and stand up `FluidAudioDiarizationService` behind the existing `DiarizationService` protocol. Do NOT touch `project.yml`'s sidecar build phase or remove the pyannote path — both implementations must coexist for the A/B.
- **Context**: This is a **spike, not a migration.** Deliverable is a go/no-go decision backed by numbers (KPI-001 wall-clock, KPI-002 accuracy/DER, RISK-003 bundle-size delta) and a verified no-network run (BR-101 / TEST-504). Keep EPIC-09 the single **Active** EPIC; this stays `Planned`/`Queued` until EPIC-09 closes or the user explicitly greenlights starting in parallel. Prior art: `temp/granite-vs-whisperkit-evaluation.md` rejected Granite ASR precisely because it needed a *second* Python sidecar with no ANE path — FluidAudio is the inverse (native Swift + CoreML + ANE), which is why diarization is the right first target.
<!-- /SECTION: session-state -->

---

<!-- CUSTOMIZABLE: objective-scope -->
## Objective & Scope

> **Goal**: Determine, with measured evidence, whether FluidAudio native (Swift/CoreML/ANE) diarization should replace the pyannote Python sidecar — by building it behind the existing `DiarizationService` seam and A/B-ing it against the current production path on the same audio.

### The hypothesis (what we expect to prove or kill)

| # | Hypothesis | How it's tested | Tied to |
|---|------------|-----------------|---------|
| H1 | Native diarization is **as accurate** as pyannote (DER within ~5 pts on our reference clip, ≥ 80% accuracy). | DER vs a hand-labeled reference + A/B vs current pyannote output on the same clip. | KPI-002 |
| H2 | Native diarization is **faster** end-to-end (ANE vs CPU-only pyannote). | Wall-clock on a 30-min meeting clip, both engines, same machine. | KPI-001, RISK-001 |
| H3 | It **shrinks the bundle** (drop PyInstaller/Python; add CoreML models). | Measure `.app` size with sidecar vs with FluidAudio. | RISK-003 |
| H4 | It stays **fully local** after first-run model download (no network during diarize). | TEST-504 no-network probe against the FluidAudio path. | BR-101 |
| H5 | It **simplifies the build** (no embed-and-bottom-up-codesign sidecar dance in `project.yml`). | Qualitative: enumerate what the sidecar build phase + entitlements would shed. | ARC-002, RISK-003 |

### Deliverables

- [ ] **`FluidAudioDiarizationService`** — a new `DiarizationService` conformer that runs FluidAudio in-process and adapts its output to the existing `DiarizationResult` schema (version `1.0`), so it is a drop-in for `PyannoteSidecarDiarizationService` with zero downstream changes (EPIC-05 formatter, EPIC-06 store, EPIC-07 UI all consume the same struct).
- [ ] **Benchmark harness + results table** — wall-clock, DER/accuracy, and bundle-size for both engines on the same reference clip, captured in `temp/`.
- [ ] **No-network verification** — TEST-504-style probe confirming diarize runs offline once models are cached.
- [ ] **Decision write-up** — a filled-in decision matrix and a recommendation: (a) adopt → draft `TECH-009` + ARC-002 update + RISK-001/003 re-score and open a productionization EPIC, (b) reject → record why in `temp/` and leave the sidecar in place, or (c) defer.

### Out of Scope (explicitly NOT this spike)

- **Removing** the pyannote sidecar / editing the `project.yml` embed+sign phase. The spike only *adds* a parallel path; teardown is a separate productionization EPIC gated on a "go".
- **Parakeet transcription** (FluidAudio also ships ASR). If diarization lands, Parakeet-as-a-`TranscriptionEngine` becomes a cheap follow-on because the dependency is already integrated — but it is a *separate* spike. Note it; don't build it.
- **Echo cancellation** (the second purr borrow — our `AudioMixer` sums mic+system with no AEC). Independent track; its own EPIC.
- **Multilingual** (BR-202 keeps us English-only for MVP).
- Any change to the public `DiarizationService` protocol or the `DiarizationResult` schema. The whole value of this spike is that the seam already exists — we conform to it, we don't change it.
<!-- /CUSTOMIZABLE: objective-scope -->

---

<!-- CUSTOMIZABLE: context-ids -->
## Context & IDs

> **Rule**: List all referenced IDs from `SoT/`.

- **Business Rules**: `BR-101` (local-only — must hold), `BR-104` (on-device — unaffected), `BR-202` (English-only — keeps scope down), `BR-401` (Apple Silicon — FluidAudio is ANE-first).
- **User Journeys**: `UJ-001` (record → transcribe → diarize → export — the path whose diarize stage we're swapping under the hood).
- **APIs / Contracts**: `API-102` (`DiarizationService` + `DiarizationResult` — the seam; the new service conforms unchanged), `API-201` (formatter — downstream consumer, must see no difference).
- **Tech / Arch**: `TECH-006` (pyannote — the incumbent under evaluation), `ARC-002` (Python sidecar — the architecture this spike challenges), `ARC-001` (local-first — invariant).
- **Risks**: `RISK-001` (pyannote CPU-only/slow — primary target), `RISK-003` (large bundle — secondary target).
- **KPIs**: `KPI-001` (< 5 min for a 30-min meeting), `KPI-002` (> 80% diarization accuracy).
- **Tests**: `TEST-504` (no-network probe — re-run against the new path).
- **New IDs this spike may propose (NOT created yet — gated on a "go")**: `TECH-009` (FluidAudio native diarization), an `INT-` entry for the FluidAudio SPM package, a re-scored `RISK-001`/`RISK-003`.
<!-- /CUSTOMIZABLE: context-ids -->

---

<!-- SECTION: execution-plan -->
## Execution Plan (The 5 Phases)

### Phase A: Plan

- [ ] **Context Loaded**: Read `PRD.md`, `README.md`, `SoT/SoT.TECHNICAL_DECISIONS.md` (TECH-006/ARC-002), `SoT/SoT.API_CONTRACTS.md` (API-102), and `temp/granite-vs-whisperkit-evaluation.md` (prior sidecar-cost reasoning).
- [ ] **Timebox**: Hard cap of ~2–3 focused sessions. If H1/H2 aren't trending positive by the end of CW2, write the "reject/defer" note and stop — do not gold-plate a spike.
- [ ] **Strategy**: Conform-then-compare. Build the new service behind the protocol first (CW1), then benchmark both engines on identical audio (CW2), then decide (CW3). No production teardown inside this EPIC.
- [ ] **Pick the reference clip**: one representative meeting recording, 3+ speakers, ideally the source of an existing golden fixture (`sidecar/test_fixtures/golden-3spk.json`) so we have a comparison point. Produce a hand-labeled ground-truth segmentation for DER.

### Phase B: Design

- [ ] **Adapter contract**: Document how FluidAudio's segment/speaker output maps onto `DiarizationResult` — `speakers[]` (id + `total_seconds`), exclusive `segments[]`, `overlapping_segments[]`, `elapsed_seconds`, `warnings[]`, `version: "1.0"`. Normalize FluidAudio speaker labels to the `SPEAKER_00`-style ids the rest of the app expects (EPIC-05 alignment, EPIC-07 naming).
- [ ] **Concurrency**: In-process CoreML holds the model in memory; decide whether to keep the `AsyncTaskQueue` serialization (as the sidecar does) or rely on actor isolation. Default: keep serialization to bound memory.
- [ ] **Progress mapping**: the protocol guarantees a `0.0` start and `1.0` completion with fractional updates. Map FluidAudio's progress callbacks (or synthesize coarse milestones) onto that closure.
- [ ] **Cancellation**: the protocol contract says a cancelled call throws `DiarizationError.cancelled`, never a failure. Verify FluidAudio's API supports cancellation; if not, wrap with `withTaskCancellationHandler` and a cooperative check.
- [ ] **Dependency hygiene**: add FluidAudio via SPM **on the spike branch only**. Record its license and model-download behavior (first-run fetch location + size) for the BR-101/RISK-003 analysis.

### Phase C: Build (The "Context Window")

**Context Window 1: `FluidAudioDiarizationService` behind the seam**

- [ ] **Step 1**: Add FluidAudio SPM dependency to `project.yml` packages (spike branch); `xcodegen generate`.
- [ ] **Step 2**: Implement `FluidAudioDiarizationService: DiarizationService` (`@implements API-102, BR-101`) — load model, diarize a WAV URL, emit progress, return `DiarizationResult`.
- [ ] **Step 3**: Write the FluidAudio→`DiarizationResult` adapter (label normalization, exclusive vs overlapping views, `elapsed_seconds`).
- [ ] **Test**: Diarize the golden clip; assert the result **decodes/round-trips** and satisfies the schema invariants the Codable already enforces (`start < end`, `version == "1.0"`, `totalSpeechSeconds` sane vs `audio.duration_seconds`). Reuse the existing `DiarizationResult` conformance fixtures.

**Context Window 2: Benchmark & accuracy A/B**

- [ ] **Step 1**: Run **both** engines on the same 30-min clip on the same Apple Silicon Mac. Record wall-clock for each → KPI-001.
- [ ] **Step 2**: Compute **DER / accuracy** for FluidAudio vs the hand-labeled reference; A/B FluidAudio vs pyannote output on the same clip → KPI-002 (H1).
- [ ] **Step 3**: Measure **bundle size**: a `.app` built with the pyannote sidecar embedded vs a build using FluidAudio (model cached out-of-bundle). Note model-cache footprint separately → RISK-003 (H3).
- [ ] **Step 4**: Enumerate what the FluidAudio path **removes** from the build — the `postBuildScripts` embed+bottom-up-codesign phase, the `diarize.entitlements` child, the +5 EPIC-04b sandbox entitlements, the HF-token plumbing (H5).
- [ ] **Test**: **No-network probe** (TEST-504 style) — with models cached, pull the network and confirm a full diarize completes with zero outbound connections → BR-101 (H4). Capture the result.

**Context Window 3: Decision & write-up**

- [ ] **Step 1**: Fill the decision matrix below from CW1/CW2 measurements.
- [ ] **Step 2**: Write `temp/fluidaudio-diarization-spike-results.md` — raw numbers, the no-network result, screenshots/logs.
- [ ] **Step 3**: Make the call. On **go**: draft `TECH-009`, an ARC-002 update (sidecar → native), re-scored `RISK-001`/`RISK-003`, an `INT-` entry for FluidAudio, and open a productionization EPIC (which owns the sidecar teardown + `project.yml` cleanup + full test-suite migration). On **reject/defer**: record the blocking reason (accuracy regression? cancellation gap? license?) so the next agent doesn't re-litigate.

#### Decision Matrix (fill during CW3)

| Criterion | Threshold | pyannote (incumbent) | FluidAudio (spike) | Verdict |
|-----------|-----------|----------------------|--------------------|---------|
| Accuracy (DER / KPI-002) | ≥ 80%, within ~5 pts of pyannote | _baseline_ | _TBD_ | _TBD_ |
| Speed (KPI-001) | < 5 min for 30-min clip | _TBD_ | _TBD_ | _TBD_ |
| Bundle size (RISK-003) | smaller is better | _TBD_ | _TBD_ | _TBD_ |
| No-network (BR-101 / TEST-504) | **must pass** | pass | _TBD_ | _TBD_ |
| Cancellation + progress contract (API-102) | **must hold** | holds | _TBD_ | _TBD_ |
| License compatibility | must allow our distribution | MIT lib / CC-BY-4.0 model | _TBD_ | _TBD_ |
| Build complexity (H5) | simpler is better | sidecar embed+sign | _TBD_ | _TBD_ |

**Go decision = all "must" rows pass AND accuracy/speed/bundle are net-positive.**

### Phase D: Validate

- [ ] **Automated Tests**: `FluidAudioDiarizationService` round-trip + schema-invariant tests green. Existing diarization suite still green (the pyannote path is untouched).
- [ ] **Manual Check**: Run UJ-001 end-to-end with the app wired to the FluidAudio service via a build flag/feature toggle; confirm the transcript renders identically downstream (formatter/UI see no schema difference).
- [ ] **Code Traceability**: `// @implements API-102, BR-101` on the new service; spike-only code clearly marked so the productionization EPIC knows what to keep.

### Phase E: Finish (Harvest)

- [ ] **Temp Cleanup**: Harvest `temp/fluidaudio-diarization-spike-results.md` into the decision — on "go", the numbers seed `TECH-009`/ARC-002; on "reject", they extend the `temp/granite-vs-whisperkit-evaluation.md` body of "engines we evaluated".
- [ ] **Spec Finalization**: No SoT mutations unless the verdict is "go" (then drafts only, ratified by the productionization EPIC). The spike must not silently flip TECH-006.
- [ ] **Session Audit**: Session State clean; verdict recorded; follow-on EPIC opened or explicitly declined.
- [ ] **Agent Observations**: Review and triage observations below.

#### Agent Observations

> Agents log proposed SoT entries, pattern discoveries, and improvement suggestions here during execution. During Phase E harvest, the EPIC lead triages each observation into: (a) create SoT entry, (b) update existing entry, or (c) discard.

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | FluidAudio also ships Parakeet ASR; if diarization adopts, ASR-as-`TranscriptionEngine` is a cheap follow-on (dep already integrated). | Create a follow-on spike EPIC (out of scope here). | Pending |
| 2 | Echo cancellation gap: `AudioMixer` sums mic+system with no AEC (purr uses SpeexDSP / Apple AUVoiceProcessing). | Independent EPIC; note in PRD roadmap. | Pending |

<!-- /SECTION: execution-plan -->

---

<!-- SECTION: change-log -->
## Change Log

| Date       | Agent  | Action       |
| ---------- | ------ | ------------ |
| 2026-06-28 | Build  | Created EPIC (FluidAudio native diarization spike; origin: purr review) |
<!-- /SECTION: change-log -->
