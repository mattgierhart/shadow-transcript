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

### Phase A: Plan — Research-Driven Decisions (2026-05-08)

> Most of the spike unknowns from the original EPIC have answers from
> research now (pyannote.audio docs via Context7, PyInstaller-on-macOS
> precedents via web search). The spike still needs to *empirically*
> confirm RTF and bundle size on the dev machine, but the design
> decisions below are locked.

- [x] **Context Loaded**: API-102, ARC-002, TECH-006, RISK-001/003, EPIC-01 sidecar scaffolding, EPIC-04-index cumulative-carry-forward.

**Decision 1 — pyannote.audio version**: Bump to **`pyannote.audio>=4.0,<5`**. Community-1 was introduced in pyannote 4.0; our current `sidecar/requirements.txt` (pinned `>=3.3.0,<3.4`) is wrong and would not load `speaker-diarization-community-1`. Pinning blocked-pending: confirm 4.x torch compatibility before locking the patch range.

**Decision 2 — Hugging Face token**: Required at **first download only**. Pipeline supports the modern `token=` kwarg (the `use_auth_token=` form is deprecated). Plumb via `--hf-token` CLI flag winning over `HF_TOKEN` env var; exit code `3` if neither and the model isn't already cached. After first download, the binary runs offline with `HF_HUB_OFFLINE=1` and `Pipeline.from_pretrained(..., local_files_only=True)`.

**Decision 3 — Cache location**: Set `HF_HOME=~/Library/Caches/ai.gearheart.TranscriptShadow/huggingface` at the binary's startup. macOS-correct cache location; survives app updates; gets cleaned by user "Manage Storage". Don't hand-roll a relocation under `~/Library/Application Support/` (HF's blob/refs/snapshots layout is a known footgun to re-implement).

**Decision 4 — Bundle strategy**: **`--onedir`, not `--onefile`**. PyInstaller maintainers explicitly recommend onedir for macOS .app bundles; `--onefile` re-extracts ~1.5 GB on every cold launch (5–15 s Gatekeeper rescan on Apple Silicon). Use `--onedir` so the Resources/diarize/ tree is signed once at build time and persists.

**Decision 5 — Bundle-size target**: Aim for **~700 MB compressed** as the honest baseline (not the original 500 MB target). Reference points: CUDA torch onefile = 2.6 GB; CPU-only macOS arm64 is ~40–50% smaller. Aggressive `excludes` (TensorBoard, torchvision, IPython, pytest, tqdm.notebook) reclaims 100–200 MB. Record actual size in EPIC observations; revisit if > 1 GB.

**Spike work that still needs the dev machine** (produces `temp/epic-04a-spike-results.md`):

- [ ] **Spike A**: Install pyannote 4.x + torch on the dev box. Record any hook surprises or wheel issues.
- [ ] **Spike B**: Download community-1 (interactive, accepts CC-BY-4.0 terms once). Confirm community-1 model size empirically (estimated 150–250 MB; not published on model card).
- [ ] **Spike C**: RTF benchmark on a 5-minute 3-speaker recording. Compare against RISK-001's "~31 s per hour" estimate.
- [ ] **Spike D**: PyInstaller `--onedir` build → measure tree + zipped sizes. Verify bottom-up codesign produces a notarizable artifact (pre-EPIC-04b sandbox work).

### Phase B: Design — Lock the JSON Contract

> The JSON schema is the boundary between 04a and 04b. EPIC-04b cannot
> start until this section is committed.

**Pyannote 4.x natively supports `output.serialize()`** which already
produces JSON. The Phase B work is to wrap that with our envelope so
the contract stays stable across pyannote versions and gives 04b a
predictable shape.

- [x] **Speaker IDs**: pyannote returns strings like `"SPEAKER_00"`, `"SPEAKER_01"`. We pass them through unchanged.
- [x] **Segment boundary precision**: float seconds with 3 decimal places (millisecond). Round at serialization to avoid IEEE float drift across runs.
- [x] **Confidence per segment**: pyannote 4.x community-1 does **not** expose per-segment confidence. Omit the field rather than fabricate. (`speaker-diarization-precision-2` does — that's an upgrade path.)
- [x] **Two diarization views**: pyannote outputs both `speaker_diarization` (allowing overlapping speech) and `exclusive_speaker_diarization` (no overlaps, better for transcription alignment). We emit the **exclusive view as primary `segments`** and keep the overlapping view under `overlapping_segments` for downstream alignment in EPIC-05.
- [x] **Per-word speaker attribution**: NOT in 04a scope. Word-level alignment is EPIC-05 (combining transcription word timestamps with our segment boundaries).
- [x] **Error envelope**: stderr carries `ERROR:<code>:<message>` lines on non-zero exit. Stdout is reserved for `PROGRESS:0.42` lines (exactly one per emit, ≥5 emits per pipeline run).
- [x] **Output is written to a file path passed via `--output`**, NOT to stdout. This avoids intermixing JSON with progress lines.

**Frozen schema** (1.0):

```json
{
  "version": "1.0",
  "audio": {
    "path": "/tmp/meeting.wav",
    "duration_seconds": 312.4
  },
  "model": {
    "name": "speaker-diarization-community-1",
    "revision": "<commit-or-version>"
  },
  "speakers": [
    {"id": "SPEAKER_00", "total_seconds": 145.2},
    {"id": "SPEAKER_01", "total_seconds": 98.6}
  ],
  "segments": [
    {"speaker": "SPEAKER_00", "start": 0.000, "end": 4.235},
    {"speaker": "SPEAKER_01", "start": 4.235, "end": 7.180}
  ],
  "overlapping_segments": [
    {"speaker": "SPEAKER_00", "start": 4.000, "end": 4.500},
    {"speaker": "SPEAKER_01", "start": 4.235, "end": 4.500}
  ],
  "elapsed_seconds": 31.2,
  "warnings": []
}
```

The `warnings` array is reserved for non-fatal issues (e.g., "fewer than `min_speakers` detected, returning best-effort"). Optional and may be empty.

### Implementation Notes (apply during Phase C)

- Use `pyannote.audio.pipelines.utils.hook.ProgressHook` for the natural
  pipeline checkpoints; map its callbacks to `PROGRESS:` stdout lines.
- Set `multiprocessing.set_start_method('spawn')` and call
  `multiprocessing.freeze_support()` in `__main__` (PyInstaller
  re-execs for child processes).
- Set `NUMBA_CACHE_DIR=~/Library/Caches/ai.gearheart.TranscriptShadow/numba`
  early in startup; otherwise librosa's first-run JIT compilation is a
  ~30 s blocker.
- Hidden imports for the .spec: `pyannote`, `pytorch_lightning`,
  `lightning_fabric` (sub-dep often missed), `torchaudio`, `sklearn`,
  `librosa`, `numba`, `onnxruntime` (community-1 uses native WeSpeaker
  ONNX; pyannote 4.x dropped speechbrain).
- Datas: `collect_data_files('pyannote')`,
  `collect_data_files('pytorch_lightning')`, `librosa` filter
  coefficients, sklearn data files.
- Excludes (size budget): `tensorboard`, `torchvision`, `IPython`,
  `pytest`, `tqdm.notebook`, `matplotlib` (if not actually used).

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
| 1 | Research surfaced that pyannote 3.x **cannot** load community-1 (pipeline introduced in 4.0). Our `sidecar/requirements.txt` from EPIC-01 has the wrong pin; correcting it is a Phase C task. | Update requirements.txt to `pyannote.audio>=4.0,<5`. | Pending (lands in Phase C) |
| 2 | `pyannote 4.x` natively serializes JSON via `output.serialize()`. Our schema wraps that with envelope fields (version, model, audio, elapsed) so the boundary stays stable if pyannote later changes its native shape. | Use `output.serialize()` for the segments array, hand-roll the envelope. | Resolved (design choice) |
| 3 | `--onefile` adds 5–15 s cold-start on Apple Silicon (Gatekeeper rescan of the extracted ~1.5 GB tree). `--onedir` is the recommended path for `.app` bundles. | Phase C uses `--onedir`. | Resolved (design choice) |
| 4 | community-1 is a **gated** model (CC-BY-4.0). User must accept terms once on the HF model page before the token works. First-launch UX: this is an EPIC-04b/EPIC-07 concern (clear error path, link to HF page). | Document in EPIC-04b's HF token plumbing section. | Carry-forward to EPIC-04b |
| 5 | Numba's JIT cache directory is per-process and uncacheable across launches without explicit `NUMBA_CACHE_DIR`. Without it, every run pays a ~30 s librosa cold start. | Set `NUMBA_CACHE_DIR` to a per-app cache dir at binary startup. | Pending (lands in Phase C) |

---

## Change Log

| Date       | Agent        | Action       |
| ---------- | ------------ | ------------ |
| 2026-05-08 | Claude Agent | EPIC created via split from EPIC-04 to address BROAD scope and isolate the Python-side risk profile from the Swift bridge. |
