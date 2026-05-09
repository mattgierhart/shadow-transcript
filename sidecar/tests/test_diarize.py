# @implements TEST-201, TEST-202, TEST-203, TEST-204
"""Tests for the diarization sidecar.

Tests exercise the pure-Python pieces of `diarize.py` (envelope build,
progress format, error format, exit-code matrix, audio-path resolution)
without invoking pyannote.audio. The pyannote pipeline itself is
exercised by the manual integration spike (Phase A Spike C) and the
PyInstaller smoke test (Phase C).

The golden JSON fixture under `sidecar/test_fixtures/golden-3spk.json`
is the cross-language contract test — EPIC-04b's Swift Codable types
must decode the same file.
"""

from __future__ import annotations

import io
import json
import re
from pathlib import Path

import pytest

import diarize


FIXTURES_DIR = Path(__file__).resolve().parent.parent / "test_fixtures"
GOLDEN_3SPK = FIXTURES_DIR / "golden-3spk.json"
GOLDEN_1SPK = FIXTURES_DIR / "golden-1spk.json"

REQUIRED_KEYS = {
    "version",
    "audio",
    "model",
    "speakers",
    "segments",
    "overlapping_segments",
    "elapsed_seconds",
    "warnings",
}


# ---------------------------------------------------------------------------
# TEST-201 — Sidecar produces valid JSON
# ---------------------------------------------------------------------------


class TestGoldenFixturesConformToSchema:
    """The golden fixtures define the cross-language contract for EPIC-04b."""

    def test_3spk_fixture_loads(self):
        data = json.loads(GOLDEN_3SPK.read_text())
        assert data["version"] == diarize.SCHEMA_VERSION

    def test_3spk_fixture_has_required_keys(self):
        data = json.loads(GOLDEN_3SPK.read_text())
        missing = REQUIRED_KEYS - set(data.keys())
        assert not missing, f"missing required keys: {missing}"

    def test_3spk_fixture_audio_block(self):
        data = json.loads(GOLDEN_3SPK.read_text())
        assert "path" in data["audio"]
        assert "duration_seconds" in data["audio"]
        assert isinstance(data["audio"]["duration_seconds"], (int, float))

    def test_3spk_fixture_segments_well_ordered(self):
        data = json.loads(GOLDEN_3SPK.read_text())
        for seg in data["segments"]:
            assert seg["end"] > seg["start"], f"bad segment: {seg}"
            assert "speaker" in seg

    def test_3spk_fixture_speakers_match_segments(self):
        data = json.loads(GOLDEN_3SPK.read_text())
        speaker_ids = {s["id"] for s in data["speakers"]}
        segment_ids = {s["speaker"] for s in data["segments"]}
        assert segment_ids.issubset(speaker_ids), (
            f"segments reference unknown speakers: {segment_ids - speaker_ids}"
        )

    def test_3spk_fixture_speaker_totals_consistent(self):
        """Each speaker's `total_seconds` must equal the sum of their segments."""
        data = json.loads(GOLDEN_3SPK.read_text())
        sums: dict[str, float] = {}
        for seg in data["segments"]:
            sums[seg["speaker"]] = sums.get(seg["speaker"], 0.0) + (seg["end"] - seg["start"])
        for speaker in data["speakers"]:
            expected = sums.get(speaker["id"], 0.0)
            assert abs(speaker["total_seconds"] - expected) < 0.001, (
                f"speaker {speaker['id']} total {speaker['total_seconds']} != sum {expected}"
            )


class TestBuildEnvelopeShape:
    """`build_envelope` produces a schema-1.0-conforming dict."""

    def test_minimal_envelope(self):
        env = diarize.build_envelope(
            audio_path="/tmp/test.wav",
            duration_seconds=120.5,
            model_name="pyannote/speaker-diarization-community-1",
            model_revision="abc123",
            segments=[
                {"speaker": "SPEAKER_00", "start": 0.0, "end": 60.0},
                {"speaker": "SPEAKER_01", "start": 60.0, "end": 120.0},
            ],
            overlapping_segments=[],
            elapsed_seconds=15.5,
        )
        assert env["version"] == "1.0"
        assert env["audio"]["duration_seconds"] == 120.5
        assert len(env["speakers"]) == 2
        assert env["warnings"] == []

    def test_required_keys_present(self):
        env = diarize.build_envelope(
            audio_path="/x",
            duration_seconds=0,
            model_name="x",
            model_revision="x",
            segments=[],
            overlapping_segments=[],
            elapsed_seconds=0,
        )
        assert REQUIRED_KEYS == set(env.keys())

    def test_speakers_sorted_by_id(self):
        env = diarize.build_envelope(
            audio_path="/x",
            duration_seconds=10,
            model_name="x",
            model_revision="x",
            segments=[
                {"speaker": "SPEAKER_02", "start": 0.0, "end": 1.0},
                {"speaker": "SPEAKER_00", "start": 1.0, "end": 2.0},
                {"speaker": "SPEAKER_01", "start": 2.0, "end": 3.0},
            ],
            overlapping_segments=[],
            elapsed_seconds=0,
        )
        assert [s["id"] for s in env["speakers"]] == ["SPEAKER_00", "SPEAKER_01", "SPEAKER_02"]

    def test_speaker_totals_computed_from_segments(self):
        env = diarize.build_envelope(
            audio_path="/x",
            duration_seconds=100,
            model_name="x",
            model_revision="x",
            segments=[
                {"speaker": "SPEAKER_00", "start": 0.0, "end": 10.0},
                {"speaker": "SPEAKER_00", "start": 20.0, "end": 25.0},
                {"speaker": "SPEAKER_01", "start": 10.0, "end": 20.0},
            ],
            overlapping_segments=[],
            elapsed_seconds=0,
        )
        totals = {s["id"]: s["total_seconds"] for s in env["speakers"]}
        assert totals["SPEAKER_00"] == 15.0
        assert totals["SPEAKER_01"] == 10.0

    def test_floats_rounded_to_3dp(self):
        env = diarize.build_envelope(
            audio_path="/x",
            duration_seconds=120.123456789,
            model_name="x",
            model_revision="x",
            segments=[{"speaker": "SPEAKER_00", "start": 0.123456, "end": 0.987654}],
            overlapping_segments=[],
            elapsed_seconds=15.987654,
        )
        assert env["audio"]["duration_seconds"] == 120.123
        assert env["segments"][0]["start"] == 0.123
        assert env["segments"][0]["end"] == 0.988
        assert env["elapsed_seconds"] == 15.988

    def test_warnings_default_empty(self):
        env = diarize.build_envelope(
            audio_path="/x",
            duration_seconds=0,
            model_name="x",
            model_revision="x",
            segments=[],
            overlapping_segments=[],
            elapsed_seconds=0,
        )
        assert env["warnings"] == []

    def test_warnings_passed_through(self):
        env = diarize.build_envelope(
            audio_path="/x",
            duration_seconds=0,
            model_name="x",
            model_revision="x",
            segments=[],
            overlapping_segments=[],
            elapsed_seconds=0,
            warnings=["fewer than min_speakers detected"],
        )
        assert env["warnings"] == ["fewer than min_speakers detected"]


# ---------------------------------------------------------------------------
# TEST-202 — Single speaker detection
# ---------------------------------------------------------------------------


class TestSingleSpeaker:
    def test_single_speaker_envelope(self):
        env = diarize.build_envelope(
            audio_path="/single.wav",
            duration_seconds=30,
            model_name="x",
            model_revision="x",
            segments=[
                {"speaker": "SPEAKER_00", "start": 0.0, "end": 10.0},
                {"speaker": "SPEAKER_00", "start": 12.0, "end": 20.0},
                {"speaker": "SPEAKER_00", "start": 22.0, "end": 30.0},
            ],
            overlapping_segments=[],
            elapsed_seconds=2,
        )
        assert len(env["speakers"]) == 1
        assert env["speakers"][0]["id"] == "SPEAKER_00"
        assert env["speakers"][0]["total_seconds"] == 26.0
        assert all(seg["speaker"] == "SPEAKER_00" for seg in env["segments"])

    def test_golden_1spk_fixture_has_one_speaker(self):
        data = json.loads(GOLDEN_1SPK.read_text())
        assert len(data["speakers"]) == 1
        assert data["speakers"][0]["id"] == "SPEAKER_00"
        assert all(seg["speaker"] == "SPEAKER_00" for seg in data["segments"])


# ---------------------------------------------------------------------------
# TEST-203 — Sidecar progress output
# ---------------------------------------------------------------------------


PROGRESS_PATTERN = re.compile(r"^PROGRESS:(\d+(?:\.\d+)?)$")
ERROR_PATTERN = re.compile(r"^ERROR:(\d+):(.+)$")


class TestProgressFormat:
    def test_progress_line_matches_regex(self):
        buf = io.StringIO()
        diarize.emit_progress(0.42, file=buf)
        line = buf.getvalue().rstrip("\n")
        match = PROGRESS_PATTERN.match(line)
        assert match is not None, f"line {line!r} does not match progress regex"
        assert float(match.group(1)) == 0.42

    def test_progress_clamped_to_unit_interval(self):
        buf = io.StringIO()
        diarize.emit_progress(1.5, file=buf)
        diarize.emit_progress(-0.1, file=buf)
        lines = buf.getvalue().strip().split("\n")
        assert lines[0] == "PROGRESS:1.00"
        assert lines[1] == "PROGRESS:0.00"

    def test_progress_two_decimal_places(self):
        buf = io.StringIO()
        diarize.emit_progress(0.5, file=buf)
        line = buf.getvalue().rstrip("\n")
        assert line == "PROGRESS:0.50"

    def test_progress_terminates_with_newline(self):
        buf = io.StringIO()
        diarize.emit_progress(0.5, file=buf)
        assert buf.getvalue().endswith("\n")

    def test_main_emits_progress_around_pipeline_call(self, monkeypatch, tmp_path, capsys):
        """`main()` must emit PROGRESS:0.00 before `run_pipeline` and PROGRESS:1.00 after.

        Mocks `run_pipeline` so the test runs without pyannote. The
        assertion verifies the actual byte stream EPIC-04b's Swift bridge
        will consume — not just function existence.
        """
        audio = tmp_path / "stub.wav"
        audio.write_bytes(b"RIFF\x00\x00\x00\x00WAVEfmt ")
        output = tmp_path / "out.json"
        monkeypatch.delenv("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK", raising=False)

        fake_envelope = diarize.build_envelope(
            audio_path=str(audio),
            duration_seconds=1.0,
            model_name="x",
            model_revision="x",
            segments=[{"speaker": "SPEAKER_00", "start": 0.0, "end": 1.0}],
            overlapping_segments=[],
            elapsed_seconds=0.1,
        )
        monkeypatch.setattr(diarize, "run_pipeline", lambda args, audio_path: fake_envelope)

        rc = diarize.main(["--audio", str(audio), "--output", str(output)])
        assert rc == diarize.EXIT_OK

        captured = capsys.readouterr()
        progress_lines = [
            ln for ln in captured.out.split("\n") if ln.startswith("PROGRESS:")
        ]
        assert len(progress_lines) >= 2, f"expected ≥2 PROGRESS lines, got: {progress_lines}"
        assert "PROGRESS:0.00" in progress_lines
        assert "PROGRESS:1.00" in progress_lines

        assert output.exists()
        written = json.loads(output.read_text())
        assert written["version"] == "1.0"


# ---------------------------------------------------------------------------
# TEST-204 — Sidecar error handling (exit codes)
# ---------------------------------------------------------------------------


class TestExitCodeMatrix:
    """The exit-code matrix is the contract EPIC-04b's `DiarizationError` decodes."""

    def test_exit_codes_match_phase_a_decision_2(self):
        assert diarize.EXIT_OK == 0
        assert diarize.EXIT_AUDIO_UNREADABLE == 1
        assert diarize.EXIT_MODEL_LOAD_FAILED == 2
        assert diarize.EXIT_HF_AUTH_REQUIRED == 3
        assert diarize.EXIT_OOM == 4


class TestErrorFormat:
    def test_error_line_matches_regex(self):
        buf = io.StringIO()
        diarize.emit_error(2, "model load failed", file=buf)
        line = buf.getvalue().rstrip("\n")
        match = ERROR_PATTERN.match(line)
        assert match is not None
        assert int(match.group(1)) == 2
        assert match.group(2) == "model load failed"

    def test_error_strips_newlines(self):
        buf = io.StringIO()
        diarize.emit_error(1, "broken\nmessage\rwith\nbreaks", file=buf)
        # Output must be exactly one non-empty line.
        non_empty = [ln for ln in buf.getvalue().split("\n") if ln]
        assert len(non_empty) == 1

    def test_error_terminates_with_newline(self):
        buf = io.StringIO()
        diarize.emit_error(1, "test", file=buf)
        assert buf.getvalue().endswith("\n")


class TestResolveAudioPath:
    """`resolve_audio_path` drives EXIT_AUDIO_UNREADABLE on every failure path."""

    def test_missing_audio_and_no_bookmark(self, monkeypatch, capsys):
        monkeypatch.delenv("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK", raising=False)
        args = type("A", (), {"audio": None})()
        with pytest.raises(SystemExit) as exc_info:
            diarize.resolve_audio_path(args)
        assert exc_info.value.code == diarize.EXIT_AUDIO_UNREADABLE
        captured = capsys.readouterr()
        assert ERROR_PATTERN.match(captured.err.rstrip("\n").split("\n")[-1])

    def test_audio_points_at_nonexistent_file(self, tmp_path, capsys, monkeypatch):
        monkeypatch.delenv("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK", raising=False)
        args = type("A", (), {"audio": tmp_path / "nope.wav"})()
        with pytest.raises(SystemExit) as exc_info:
            diarize.resolve_audio_path(args)
        assert exc_info.value.code == diarize.EXIT_AUDIO_UNREADABLE
        captured = capsys.readouterr()
        assert "audio file not found" in captured.err

    def test_existing_audio_resolves_to_absolute_path(self, tmp_path, monkeypatch):
        monkeypatch.delenv("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK", raising=False)
        audio = tmp_path / "clip.wav"
        audio.write_bytes(b"RIFF\x00\x00\x00\x00WAVEfmt ")  # not a real WAV; resolve doesn't care
        args = type("A", (), {"audio": audio})()
        resolved = diarize.resolve_audio_path(args)
        assert resolved == audio.resolve()
        assert resolved.is_absolute()

    def test_bookmark_env_without_audio_is_deferred(self, monkeypatch, capsys):
        monkeypatch.setenv("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK", "deadbeefbase64")
        args = type("A", (), {"audio": None})()
        with pytest.raises(SystemExit) as exc_info:
            diarize.resolve_audio_path(args)
        assert exc_info.value.code == diarize.EXIT_AUDIO_UNREADABLE
        captured = capsys.readouterr()
        assert "bookmark resolution" in captured.err.lower()


class TestMainPathExitCodes:
    """End-to-end exit-code paths through `main()`. Pipeline itself is mocked-out
    (we never reach `run_pipeline` in these scenarios since the audio-resolution
    step exits early)."""

    def test_main_with_missing_audio_exits_1(self, tmp_path, monkeypatch, capsys):
        monkeypatch.delenv("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK", raising=False)
        output = tmp_path / "out.json"
        with pytest.raises(SystemExit) as exc_info:
            diarize.main(["--output", str(output)])
        assert exc_info.value.code == diarize.EXIT_AUDIO_UNREADABLE
        assert not output.exists(), "no JSON should be written when audio resolution fails"

    def test_main_with_nonexistent_audio_exits_1(self, tmp_path, monkeypatch, capsys):
        monkeypatch.delenv("TRANSCRIPT_SHADOW_AUDIO_BOOKMARK", raising=False)
        output = tmp_path / "out.json"
        with pytest.raises(SystemExit) as exc_info:
            diarize.main(["--audio", str(tmp_path / "nope.wav"), "--output", str(output)])
        assert exc_info.value.code == diarize.EXIT_AUDIO_UNREADABLE
