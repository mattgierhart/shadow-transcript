#!/usr/bin/env python3
# @implements API-102, ARC-002, TECH-006
"""Speaker-diarization sidecar for Transcript Shadow.

Wraps pyannote.audio 4.x's `Pipeline.from_pretrained(...)` for the
`speaker-diarization-community-1` model and emits a frozen JSON envelope
documented in EPIC-04a Phase B (schema version 1.0).

Stdout is reserved for `PROGRESS:0.42` lines; the JSON output goes to a
file path passed via `--output` (so progress lines never intermix with
the JSON payload). Stderr carries `ERROR:<code>:<message>` lines on
non-zero exits.

Exit codes (EPIC-04a Phase A Decision 2):
  0  success
  1  audio unreadable / missing
  2  model load failed (non-auth)
  3  HF auth required (gated model, no token, not cached)
  4  out of memory
"""

import os
from pathlib import Path

# ---------------------------------------------------------------------------
# Cache locations MUST be set before any pyannote / numba / HF / torch import.
# numba's JIT cache and HF's hub cache are import-order sensitive; without
# NUMBA_CACHE_DIR, librosa pays a ~30 s cold-start tax on every run, and
# without HF_HOME the model lands in ~/.cache/huggingface/ which the user's
# "Manage Storage" UI can't see (EPIC-04a Phase A Decision 3).
# ---------------------------------------------------------------------------
_DEFAULT_HF_CACHE = (
    Path.home() / "Library" / "Caches" / "ai.gearheart.TranscriptShadow" / "huggingface"
)
_DEFAULT_NUMBA_CACHE = (
    Path.home() / "Library" / "Caches" / "ai.gearheart.TranscriptShadow" / "numba"
)
os.environ.setdefault("HF_HOME", str(_DEFAULT_HF_CACHE))
os.environ.setdefault("NUMBA_CACHE_DIR", str(_DEFAULT_NUMBA_CACHE))
_DEFAULT_HF_CACHE.mkdir(parents=True, exist_ok=True)
_DEFAULT_NUMBA_CACHE.mkdir(parents=True, exist_ok=True)

import argparse
import json
import multiprocessing
import sys
import time
from typing import Any, Iterable, Optional

# Module-level constants — testable without pyannote ----------------------

SCHEMA_VERSION = "1.0"
DEFAULT_MODEL = "pyannote/speaker-diarization-community-1"
PROGRESS_PREFIX = "PROGRESS:"
ERROR_PREFIX = "ERROR:"

EXIT_OK = 0
EXIT_AUDIO_UNREADABLE = 1
EXIT_MODEL_LOAD_FAILED = 2
EXIT_HF_AUTH_REQUIRED = 3
EXIT_OOM = 4


# Output emitters ---------------------------------------------------------

def emit_progress(fraction: float, *, file=None) -> None:
    """Emit a `PROGRESS:0.42` line (clamped to 2 decimal places).

    Format matches the regex `^PROGRESS:(\\d+(?:\\.\\d+)?)$` that EPIC-04b
    parses on the Swift side.
    """
    if file is None:
        file = sys.stdout
    clamped = max(0.0, min(1.0, float(fraction)))
    file.write(f"{PROGRESS_PREFIX}{clamped:.2f}\n")
    file.flush()


def emit_error(code: int, message: str, *, file=None) -> None:
    """Emit `ERROR:<code>:<message>` to stderr.

    Newlines and carriage returns are stripped so the line-based regex
    `^ERROR:(\\d+):(.+)$` always matches a single line.
    """
    if file is None:
        file = sys.stderr
    safe = str(message).replace("\n", " ").replace("\r", " ").strip()
    file.write(f"{ERROR_PREFIX}{code}:{safe}\n")
    file.flush()


# Envelope construction ---------------------------------------------------

def build_envelope(
    *,
    audio_path: str,
    duration_seconds: float,
    model_name: str,
    model_revision: str,
    segments: Iterable[dict],
    overlapping_segments: Iterable[dict],
    elapsed_seconds: float,
    warnings: Optional[list[str]] = None,
) -> dict[str, Any]:
    """Construct the EPIC-04a Phase B schema-1.0 envelope.

    Each segment dict requires `speaker` (str), `start` and `end` (float
    seconds). Floats are rounded to 3 decimal places so cross-run output
    stays byte-identical for fixture comparisons. Speakers are sorted by ID
    so envelope output is deterministic.

    `overlapping_segments` is the speaker_diarization view (allowing
    overlapping speech). `segments` is the exclusive_speaker_diarization
    view (non-overlapping; preferred for transcription alignment in
    EPIC-05).
    """
    speakers_total: dict[str, float] = {}
    rounded_segments: list[dict] = []
    for s in segments:
        speaker = s["speaker"]
        start = round(float(s["start"]), 3)
        end = round(float(s["end"]), 3)
        rounded_segments.append({"speaker": speaker, "start": start, "end": end})
        speakers_total[speaker] = speakers_total.get(speaker, 0.0) + (end - start)

    rounded_overlapping = [
        {
            "speaker": s["speaker"],
            "start": round(float(s["start"]), 3),
            "end": round(float(s["end"]), 3),
        }
        for s in overlapping_segments
    ]

    speakers = [
        {"id": speaker, "total_seconds": round(total, 3)}
        for speaker, total in sorted(speakers_total.items())
    ]

    return {
        "version": SCHEMA_VERSION,
        "audio": {
            "path": str(audio_path),
            "duration_seconds": round(float(duration_seconds), 3),
        },
        "model": {
            "name": model_name,
            "revision": model_revision,
        },
        "speakers": speakers,
        "segments": rounded_segments,
        "overlapping_segments": rounded_overlapping,
        "elapsed_seconds": round(float(elapsed_seconds), 3),
        "warnings": list(warnings or []),
    }


# Audio path resolution ---------------------------------------------------

def resolve_audio_path(args: argparse.Namespace) -> Path:
    """Resolve `--audio` to an existing absolute path.

    The `TRANSCRIPT_SHADOW_AUDIO_BOOKMARK` env var is the EPIC-04b Phase A
    Decision 3 "security-scoped bookmark" hand-off. Apple-native bookmark
    resolution requires Foundation APIs not available to this Python child,
    so the contract here is: if the env var is set without `--audio`, exit
    with a clear deferred-implementation message. EPIC-04b's recovery
    path (per the plan) is to resolve the bookmark in the Swift parent
    and pass `--audio` with the resolved path (using sandbox inheritance
    or a copy into the parent's container).
    """
    if args.audio:
        path = Path(args.audio).expanduser()
        try:
            path = path.resolve(strict=True)
        except (OSError, FileNotFoundError):
            emit_error(EXIT_AUDIO_UNREADABLE, f"audio file not found: {path}")
            sys.exit(EXIT_AUDIO_UNREADABLE)
        return path

    if os.environ.get("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK"):
        emit_error(
            EXIT_AUDIO_UNREADABLE,
            "TRANSCRIPT_SHADOW_AUDIO_BOOKMARK env present but bookmark "
            "resolution is not implemented in this binary. Resolve the "
            "bookmark in the Swift parent and pass --audio with the "
            "resolved path. See EPIC-04a Phase A Decision 3 fallback path.",
        )
        sys.exit(EXIT_AUDIO_UNREADABLE)

    emit_error(
        EXIT_AUDIO_UNREADABLE,
        "no --audio path provided and no TRANSCRIPT_SHADOW_AUDIO_BOOKMARK env set",
    )
    sys.exit(EXIT_AUDIO_UNREADABLE)


# Pyannote bridge ---------------------------------------------------------

def _annotation_to_dicts(annotation) -> list[dict]:
    """Convert a `pyannote.core.Annotation` to our list-of-dicts shape."""
    out: list[dict] = []
    for segment, _track, label in annotation.itertracks(yield_label=True):
        out.append(
            {
                "speaker": str(label),
                "start": float(segment.start),
                "end": float(segment.end),
            }
        )
    return out


def _extract_segments(output: Any) -> tuple[list[dict], list[dict]]:
    """Extract (exclusive, overlapping) segment lists from a pyannote output.

    pyannote 4.x's community-1 result exposes both views. Fall back to
    treating `output` as a plain Annotation if the wrapper attributes
    aren't present (defensive — pyannote 4 minor releases have shifted
    this surface before).
    """
    primary = []
    overlapping = []
    if hasattr(output, "exclusive_speaker_diarization"):
        primary = _annotation_to_dicts(output.exclusive_speaker_diarization)
        if hasattr(output, "speaker_diarization"):
            overlapping = _annotation_to_dicts(output.speaker_diarization)
    elif hasattr(output, "speaker_diarization"):
        primary = _annotation_to_dicts(output.speaker_diarization)
    elif hasattr(output, "itertracks"):
        primary = _annotation_to_dicts(output)
    return primary, overlapping


def run_pipeline(args: argparse.Namespace, audio_path: Path) -> dict[str, Any]:
    """Run the pyannote diarization pipeline and return a Phase B envelope.

    pyannote is imported lazily so tests that exercise envelope/progress
    helpers run without the heavy torch + pyannote install present.
    """
    try:
        from pyannote.audio import Pipeline  # type: ignore
    except ImportError as exc:
        emit_error(EXIT_MODEL_LOAD_FAILED, f"pyannote.audio not installed: {exc}")
        sys.exit(EXIT_MODEL_LOAD_FAILED)

    token = args.hf_token or os.environ.get("HF_TOKEN")

    try:
        pipeline = Pipeline.from_pretrained(args.model, token=token)
    except Exception as exc:  # noqa: BLE001 — surface every failure with a typed exit code
        msg = str(exc).lower()
        if any(k in msg for k in ("401", "unauthorized", "auth", "gated", "access")):
            emit_error(EXIT_HF_AUTH_REQUIRED, f"HF auth required for {args.model}: {exc}")
            sys.exit(EXIT_HF_AUTH_REQUIRED)
        emit_error(EXIT_MODEL_LOAD_FAILED, f"{type(exc).__name__}: {exc}")
        sys.exit(EXIT_MODEL_LOAD_FAILED)

    pipeline_kwargs: dict[str, Any] = {}
    if args.num_speakers:
        pipeline_kwargs["num_speakers"] = int(args.num_speakers)

    start_time = time.time()

    # We do NOT use pyannote's bundled ProgressHook: its rich console writes
    # to stdout, which collides with our `PROGRESS:` line contract that
    # EPIC-04b's Swift bridge parses (Codex Gate 1 finding P1, 2026-05-09).
    # Our adapter emits typed PROGRESS lines directly without forwarding.
    def progress_adapter(
        step_name, step_artifact=None, file=None, total=None, completed=None
    ):
        if total and completed is not None and total > 0:
            emit_progress(float(completed) / float(total))

    try:
        output = pipeline(str(audio_path), hook=progress_adapter, **pipeline_kwargs)
    except MemoryError as exc:
        emit_error(EXIT_OOM, f"out of memory while diarizing: {exc}")
        sys.exit(EXIT_OOM)
    except Exception as exc:  # noqa: BLE001
        emit_error(EXIT_MODEL_LOAD_FAILED, f"pipeline run failed: {type(exc).__name__}: {exc}")
        sys.exit(EXIT_MODEL_LOAD_FAILED)

    elapsed = time.time() - start_time

    duration_seconds = 0.0
    try:
        import soundfile as sf  # type: ignore

        info = sf.info(str(audio_path))
        duration_seconds = float(info.frames) / float(info.samplerate)
    except Exception:  # noqa: BLE001 — duration is informational, not load-bearing
        duration_seconds = 0.0

    primary, overlapping = _extract_segments(output)

    revision = "unknown"
    for attr in ("revision", "version", "_revision"):
        if hasattr(output, attr):
            try:
                revision = str(getattr(output, attr))
                break
            except Exception:  # noqa: BLE001
                pass

    return build_envelope(
        audio_path=str(audio_path),
        duration_seconds=duration_seconds,
        model_name=args.model,
        model_revision=revision,
        segments=primary,
        overlapping_segments=overlapping,
        elapsed_seconds=elapsed,
        warnings=[],
    )


# Argument parsing + entrypoint ------------------------------------------

def parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="diarize",
        description="Speaker-diarization sidecar for Transcript Shadow.",
    )
    parser.add_argument(
        "--audio",
        type=Path,
        default=None,
        help="Path to input audio (WAV expected). If omitted, "
        "TRANSCRIPT_SHADOW_AUDIO_BOOKMARK env may be checked (currently "
        "deferred — see resolve_audio_path).",
    )
    parser.add_argument(
        "--output",
        required=True,
        type=Path,
        help="Path to write the schema-1.0 JSON envelope.",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Pyannote model identifier (default: {DEFAULT_MODEL}).",
    )
    parser.add_argument(
        "--num-speakers",
        type=int,
        default=None,
        help="Optional: pin the speaker count (skips estimation).",
    )
    parser.add_argument(
        "--hf-token",
        default=None,
        help="HuggingFace token. Falls back to HF_TOKEN env. Required only "
        "on first download of a gated model (community-1 is gated).",
    )
    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    args = parse_args(argv)
    audio_path = resolve_audio_path(args)

    emit_progress(0.0)
    envelope = run_pipeline(args, audio_path)
    emit_progress(1.0)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(envelope, indent=2))
    return EXIT_OK


if __name__ == "__main__":
    # PyInstaller re-execs to spawn child processes; freeze_support() must
    # be the first thing in __main__ to keep that path clean. (No-op when
    # running unfrozen, harmless to always call.)
    multiprocessing.freeze_support()
    sys.exit(main())
