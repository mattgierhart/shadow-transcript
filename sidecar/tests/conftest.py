# pytest conftest for the sidecar tests.
# Adds sidecar/ to sys.path so `import diarize` resolves without an
# installed package or a setup.py — the sidecar is a script, not a package.

import sys
from pathlib import Path

_SIDECAR_DIR = Path(__file__).resolve().parent.parent
if str(_SIDECAR_DIR) not in sys.path:
    sys.path.insert(0, str(_SIDECAR_DIR))
