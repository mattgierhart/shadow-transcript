---
template_version: "3.0.0"
---

# EPIC-04a Diarization Sidecar — Python CLI & Packaging

> **State**: `Planned` (active EPIC after the split)
> **Lifecycle**: v0.7 Build Execution
> **Epic Lead**: TBD
> **Depends On**: EPIC-01 (sidecar scaffold), EPIC-03 (artifact handoff shape)
> **Blocks**: EPIC-04b (Swift bridge cannot start until the JSON contract is frozen here)

---

## Why this is its own EPIC

EPIC-04 (the original "Speaker Diarization Sidecar") bundled three different
risk profiles into one workstream — a Python pipeline whose accuracy +
performance is unproven on Apple Silicon, a PyInstaller bundle that may or
may not ship clean with `pyannote + torch + torchaudio`, and a sandboxed
Swift `Process` consumer that needs entitlement work. Per Codex's
2026-05-07 path-forward review and the BROAD-scope hook firing on the
combined EPIC, the split is:

- **04a (this EPIC)** — Python CLI + PyInstaller bundle. Owns the
  diarization pipeline, the JSON output contract, the binary build, and a
  golden-fixture validation. **No Swift in scope.**
- **04b** — Swift `DiarizationService` that spawns the 04a binary as a
  subprocess. Consumes the frozen JSON. Picks up the sandbox + entitlement
  work. Cannot start until 04a's JSON schema is locked.

Each EPIC has a smaller SoT footprint and a categorically different risk
profile. The two milestones can complete on different days without churn
on the boundary.

---

## Session State (The "Brain Dump")

- **Last Action**: 2026-05-08 — split from EPIC-04. Planning round in
  progress (research notes land in Phase A/B below before any code).
- **Stopping Point**: N/A — not yet started.
- **Next Steps**: Run the Phase A risk spike: prove pyannote installs +
  loads + produces sensible output on a known recording, measure RTF on
  Apple Silicon, decide HF token strategy, confirm PyInstaller can bundle
  the dependency graph.
- **Context**: Highest-risk EPIC by far. Bundle size + CPU performance
  (RISK-001, RISK-003) are the unknowns that dictate whether we ship a
  monolithic ~500 MB binary or pivot to a runtime-download pattern.

---

## Cumulative Carry-Forward

> Read once, then `<!-- HANDOFF -->` past it.

The full carry-forward block lives in `epics/EPIC-04-speaker-diarization.md`
(now an index). Highlights that bite the Python side specifically:

- **Don't trust SDK initializer parameter names** (EPIC-03 P1: WhisperKit
  `modelFolder` vs `downloadBase` cost a Codex round). For pyannote, the
  equivalent traps are `cache_dir` vs `model_dir` and the
  `Pipeline.from_pretrained(...)` `use_auth_token` parameter.
- **Freeze the JSON contract before a consumer reads it.** Once 04b parses
  the schema, a breaking change costs a coordinated EPIC update.
- **Test discipline:** unit tests use golden-JSON fixtures, not a live
  pyannote run. Real-pipeline accuracy validation lives in a single
  benchmark script invoked manually, not on every test run.

<!-- HANDOFF -->

---

## Objective & Scope

> **Goal**: Produce a standalone PyInstaller binary that takes
> `--audio <wav> --output <json>` and emits a frozen, documented JSON
> schema describing speaker segments and (optionally) per-word speaker
> attribution. The binary must run on Apple Silicon with no Python on the
> user's machine.

- **Deliverables**:
  - [ ] `sidecar/diarize.py` — real pyannote.audio pipeline implementation (replaces the EPIC-01 stub)
  - [ ] CLI: `--audio <path>`, `--output <path>`, `--num-speakers <int?>`, `--hf-token <str?>` (env fallback `HF_TOKEN`)
  - [ ] **Frozen JSON output schema** documented in this EPIC (Phase B) and re-stated in `SoT/SoT.API_CONTRACTS.md` API-102
  - [ ] Progress reporting via stdout `PROGRESS:0.42` line format
  - [ ] Error handling with mapped exit codes (1 = audio unreadable, 2 = model load failed, 3 = HF auth required, 4 = OOM)
  - [ ] Updated `sidecar/requirements.txt` with version pins that produce a clean PyInstaller bundle on macOS arm64
  - [ ] Updated `sidecar/diarize.spec` with all required hidden imports + datas
  - [ ] PyInstaller binary builds + runs against a fixture WAV → produces JSON matching the schema
  - [ ] Golden-JSON fixture under `sidecar/test_fixtures/` for 04b to assert against without invoking the binary
  - [ ] Tests: TEST-201 (valid JSON), TEST-202 (single speaker), TEST-203 (progress), TEST-204 (error exit codes)
- **Out of Scope**: Swift bridge, app-sandbox entitlements, end-to-end
  pipeline integration, multi-speaker accuracy benchmarks beyond the
  spike's 5-minute fixture.

---

## Context & IDs

- **APIs**: API-102 (Diarization Sidecar CLI half — the binary contract)
- **Architecture**: ARC-002 (Python sidecar pattern)
- **Tech**: TECH-006 (pyannote.audio)
- **Business Rules**: BR-101 (local-only)
- **Features**: FEA-003 (speaker diarization)
- **Tests**: TEST-201, TEST-202, TEST-203, TEST-204
- **Risks**: RISK-001 (pyannote CPU performance), RISK-003 (PyInstaller bundle size)

8 SoT references — well within the BROAD-scope threshold.

---

## Execution Plan (The 5 Phases)

### Phase A: Plan (Risk Spike First)

> **Goal of this phase**: produce `temp/epic-04a-spike-results.md` with
> answers to the five spike questions below before writing the real
> `diarize.py`. The spike's findings dictate the version pins, the bundle
> strategy, and the JSON schema's level of detail.

- [ ] **Context Loaded**: Read API-102, ARC-002, TECH-006, RISK-001/003, EPIC-01 sidecar scaffolding, EPIC-04 (now-index) cumulative-carry-forward block
- [ ] **Spike question 1**: Does `pyannote.audio` 3.3.x install cleanly on Python 3.11 on macOS arm64 with our pinned `torch` + `torchaudio`? Record any hidden-import or build-from-source surprises.
- [ ] **Spike question 2**: Does `speaker-diarization-community-1` require a Hugging Face token at first download? If yes, where does the user provide it (env var, CLI flag, both)?
- [ ] **Spike question 3**: What is the real-time factor on a known 5-minute, 3-speaker recording on the active dev machine (M3 MBP / M2 Max Studio)? RISK-001 said "~31s per hour" — ground-truth that.
- [ ] **Spike question 4**: PyInstaller bundle size with everything packed (`pyannote.audio + torch + torchaudio + sklearn + numpy`)? Decide whether < 500 MB is achievable or we accept larger.
- [ ] **Spike question 5**: What does pyannote's actual output object look like? Speaker IDs (str vs int), boundary precision, confidence per segment? — drives the JSON schema.

### Phase B: Design — Lock the JSON Contract

> The JSON schema is the boundary between 04a and 04b. EPIC-04b cannot
> start until this section is filled in and committed. Schema decisions:

- [ ] **Speaker IDs**: string (`"SPEAKER_00"`) vs int (`0`). Default: string for forward-compat with named labels.
- [ ] **Segment boundary precision**: float seconds with 3 decimal places (millisecond) — enough for 04b alignment work in EPIC-05.
- [ ] **Optional confidence per segment**: include if pyannote exposes it; otherwise omit (don't fabricate).
- [ ] **Per-word speaker attribution**: NOT in 04a scope. The community-1 pipeline doesn't produce word-level output natively; that's an EPIC-05 alignment task.
- [ ] **Error envelope**: when the binary exits non-zero, stderr carries `ERROR:<code>:<message>`. Exit code mapping documented above.
- [ ] **Progress format**: stdout-only, exactly one `PROGRESS:0.42` line per emit, no other stdout output during success path.
- [ ] **Schema example** (target shape — actuals locked after the spike):

```json
{
  "version": "1.0",
  "audio": {
    "path": "/tmp/meeting.wav",
    "duration_seconds": 312.4
  },
  "model": {
    "name": "speaker-diarization-community-1",
    "revision": "..."
  },
  "speakers": [
    {"id": "SPEAKER_00", "total_seconds": 145.2},
    {"id": "SPEAKER_01", "total_seconds": 98.6}
  ],
  "segments": [
    {"speaker": "SPEAKER_00", "start": 0.000, "end": 4.235, "confidence": 0.91},
    {"speaker": "SPEAKER_01", "start": 4.235, "end": 7.180, "confidence": 0.87}
  ],
  "elapsed_seconds": 31.2
}
```

### Phase C: Build

**Context Window 1: Real diarize.py**

- [ ] Replace EPIC-01 argparse-only stub with a real pyannote.audio pipeline
- [ ] HF token plumbing: `--hf-token` flag wins, falls back to `HF_TOKEN` env, errors with exit code 3 if neither and the model requires it
- [ ] Pipeline initialization → process audio → assemble the frozen JSON shape from Phase B
- [ ] Progress emission at the natural pyannote checkpoints (initialization, embedding, clustering, output)
- [ ] Error mapping → typed exit codes
- [ ] **Tests**: TEST-201 (golden-JSON shape via `jsonschema`), TEST-202 (single-speaker fixture → 1 speaker reported)

**Context Window 2: PyInstaller Spec**

- [ ] Update `sidecar/diarize.spec` with all hidden imports the spike surfaced
- [ ] `target_arch='arm64'`, `console=True`, `--onefile` (or `--onedir` if onefile breaks pyannote model lookup at runtime — TBD from the spike)
- [ ] Test the binary runs against the fixture WAV on a fresh path with no Python in PATH
- [ ] Record final binary size in this EPIC's observations
- [ ] **Tests**: TEST-203 (progress format regex test), TEST-204 (each error exit code reachable from a fixture)

### Phase D: Validate

- [ ] All 4 TEST-XXX cases pass
- [ ] Golden JSON fixture committed under `sidecar/test_fixtures/` for 04b's consumption tests
- [ ] Manual benchmark on a 5-minute recording recorded in this EPIC
- [ ] **Codex review pass** before EPIC close (single-ask: "Find bugs in `diarize.py` + the spec that EPIC-03's lessons should have prevented")
- [ ] Code traceability: `# @implements API-102, ARC-002` in `diarize.py`

### Phase E: Finish (Harvest)

- [ ] `temp/epic-04a-spike-results.md` archived or harvested into agent-observations table below
- [ ] API-102 status updated in `SoT/SoT.API_CONTRACTS.md` — note that the entry covers both 04a (CLI) and 04b (Swift) and only the Python half is implemented
- [ ] TEST-201..204 marked Implemented in `SoT/SoT.TESTING.md`
- [ ] Record benchmark + bundle size in RISK-001 / RISK-003 mitigation notes

#### Agent Observations

| # | Observation | Proposed Action | Triage |
|---|-------------|-----------------|--------|
| 1 | | | Pending |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-05-08 | Claude Agent | EPIC created via split from EPIC-04 to address BROAD scope and isolate the Python-side risk profile from the Swift bridge. |
