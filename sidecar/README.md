# Transcript Shadow — Diarization Sidecar

> **@implements** API-102, TECH-006, ARC-002, ENV-001
> **Status (EPIC-04a)**: Real `pyannote.audio` 4.x pipeline. PyInstaller
> `--onedir` bundle. JSON envelope frozen at schema version 1.0.

A standalone Python CLI that the macOS app spawns as a subprocess to run speaker
diarization. Bundled into a self-contained ARM64 directory via PyInstaller so
users do not need a Python install.

## Dev setup

```bash
# Fresh venv (Python 3.11 required — see ENV-001)
python3.11 -m venv .venv
source .venv/bin/activate

# Dependencies
pip install -r requirements.txt

# Tests (no pyannote install required — pure-Python paths only)
pytest tests/
```

## Run against real audio (development)

```bash
# First-time: HF auth required for the gated community-1 model.
# https://huggingface.co/pyannote/speaker-diarization-community-1
export HF_TOKEN=hf_xxx
python diarize.py --audio /tmp/example.wav --output /tmp/example.json
cat /tmp/example.json
```

The HF token is only needed on first download; subsequent runs read from the
on-disk cache at `~/Library/Caches/ai.gearheart.TranscriptShadow/huggingface/`.

## Build the bundle (release flow)

```bash
pyinstaller diarize.spec
ls -la dist/diarize/             # the --onedir tree, signed bottom-up by EPIC-04b's Run Script
./dist/diarize/diarize --audio /tmp/example.wav --output /tmp/example.json
```

`pyinstaller diarize.spec` pulls torch + pyannote.audio (~multi-GB,
several minutes); release-only, not in CI. Output is a directory tree
(NOT a single file) — see EPIC-04a Phase A Decision 4 for why.

## CLI

```
diarize --audio <PATH> --output <PATH>
        [--model pyannote/speaker-diarization-community-1]
        [--num-speakers <int>]
        [--hf-token <str>]
```

| Flag | Required | Notes |
|------|----------|-------|
| `--audio`         | yes¹ | Input WAV path. |
| `--output`        | yes  | Where the schema-1.0 JSON envelope is written. |
| `--model`         | no   | pyannote model ID; default `pyannote/speaker-diarization-community-1`. |
| `--num-speakers`  | no   | Pin a known speaker count (skips estimation). |
| `--hf-token`      | no   | First-download HF token; falls back to `HF_TOKEN` env. |

¹ The `TRANSCRIPT_SHADOW_AUDIO_BOOKMARK` env var is reserved for a future
security-scoped-bookmark hand-off from EPIC-04b's Swift parent. The current
binary reports a clear deferred-implementation error if it sees the env var
without `--audio`. EPIC-04b's recovery path is to resolve the bookmark in the
parent and pass `--audio` with the resolved path.

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success — JSON written to `--output`. |
| `1` | Audio file unreadable / missing. |
| `2` | Model load failed (non-auth). |
| `3` | HF auth required (gated model, no token, not cached). |
| `4` | Out of memory. |

## Output protocol

- **stdout** carries `PROGRESS:0.42` lines (≥ 5 per pipeline run, in [0.0, 1.0]).
- **stderr** carries `ERROR:<code>:<message>` lines on non-zero exit.
- **`--output` file** is the schema-1.0 JSON envelope. The fixture under
  `test_fixtures/golden-3spk.json` is the cross-language contract test —
  EPIC-04b's Swift `DiarizationResult` Codable type must decode it.

## Out of scope

- Bookmark resolution in pure Python (deferred — EPIC-04b parent resolves).
- App-bundle embedding under `Contents/Resources/diarize/` (EPIC-04b).
- Notarization (release-prep EPIC).
