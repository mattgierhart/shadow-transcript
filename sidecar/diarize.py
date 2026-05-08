#!/usr/bin/env python3
# @implements TECH-006, ARC-002
"""Speaker-diarization sidecar CLI for Transcript Shadow.

EPIC-01 scaffolding stub. Real pyannote pipeline lands in EPIC-04
(Speaker Diarization). This script only verifies argparse + JSON I/O.
"""

import argparse
import json
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="diarize",
        description="Speaker diarization sidecar for Transcript Shadow.",
    )
    parser.add_argument(
        "--audio",
        required=True,
        type=Path,
        help="Path to input audio file (WAV expected post-EPIC-02).",
    )
    parser.add_argument(
        "--output",
        required=True,
        type=Path,
        help="Path to write speaker-segment JSON output.",
    )
    parser.add_argument(
        "--model",
        default="speaker-diarization-community-1",
        help="Pyannote model identifier (default: community-1).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    stub_payload = {
        "version": "0.1.0-scaffold",
        "model": args.model,
        "audio_input": str(args.audio),
        "speakers": [],
        "stub": True,
        "note": "EPIC-01 scaffold; real diarization implemented in EPIC-04.",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(stub_payload, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
