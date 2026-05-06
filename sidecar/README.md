# Transcript Shadow — Diarization Sidecar

> **@implements** TECH-006, ARC-002, ENV-001
> **Status (EPIC-01)**: Scaffolding only. Real `pyannote.audio` pipeline lands in EPIC-04.

A standalone Python CLI that the macOS app spawns as a subprocess to run speaker
diarization. Bundled into a single ARM64 binary via PyInstaller so users do not
need a Python install.

## Dev setup

```bash
# Fresh venv (Python 3.11 required — see ENV-001)
python3.11 -m venv .venv
source .venv/bin/activate

# Dependencies
pip install -r requirements.txt
```

## Run the stub

```bash
python diarize.py --audio /tmp/example.wav --output /tmp/example.json
cat /tmp/example.json   # → {"version": "0.1.0-scaffold", "speakers": [], "stub": true, ...}
```

## Build the binary (release flow)

```bash
pyinstaller diarize.spec
./dist/diarize --audio /tmp/example.wav --output /tmp/example.json
```

The full PyInstaller bundle pulls torch + pyannote (~multi-GB) and takes
several minutes; that's expected and only runs at release time, not in CI.

## CLI

```
diarize --audio <PATH> --output <PATH> [--model speaker-diarization-community-1]
```

| Flag | Required | Notes |
|------|----------|-------|
| `--audio`  | yes | Path to input audio (WAV, post-EPIC-02). |
| `--output` | yes | Path to write speaker-segment JSON. |
| `--model`  | no  | Pyannote model identifier; default `speaker-diarization-community-1`. |

## Open items (out of scope for EPIC-01)

- Hugging Face token + model download flow (handled by EPIC-04).
- Real pyannote pipeline replacing the stub JSON output (EPIC-04).
- App-bundle embedding under `Contents/Resources/` (sandbox + entitlement
  adjustments tracked in EPIC-04 / EPIC-08).
