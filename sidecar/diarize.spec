# PyInstaller spec — Transcript Shadow diarization sidecar
# @implements ARC-002, TECH-006
#
# Build with:  pyinstaller diarize.spec
# Output:      dist/diarize/   (a directory tree, NOT a single file)
#
# Why --onedir, not --onefile:
#   PyInstaller maintainers explicitly recommend onedir for macOS .app
#   bundles. --onefile re-extracts ~1.5 GB on every cold launch, which
#   triggers a 5–15 s Gatekeeper rescan on Apple Silicon. With --onedir
#   the entire Resources/diarize/ tree is signed once at build time and
#   persists across runs (EPIC-04a Phase A Decision 4).
#
# Why so many hidden imports:
#   pyannote.audio 4.x dropped speechbrain in favor of an onnxruntime +
#   WeSpeaker pipeline for speaker embedding. PyInstaller's static
#   analysis misses several transitive deps in the lightning + pyannote
#   trees (lightning_fabric is the canonical EPIC-04a Observation 5
#   trap). collect_submodules() is a sledgehammer that catches all of
#   them; the size cost is amortized by the excludes list below.

# -*- mode: python ; coding: utf-8 -*-

from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# --- Hidden imports ----------------------------------------------------

hidden_imports = [
    "pyannote",
    "pyannote.audio",
    "pyannote.audio.pipelines",
    "pyannote.audio.pipelines.utils.hook",
    "pytorch_lightning",
    "lightning_fabric",
    "torchaudio",
    "sklearn",
    "sklearn.utils._typedefs",
    "librosa",
    "numba",
    "onnxruntime",
    "soundfile",
]

# Catch transitive submodules pyannote / lightning ship that PyInstaller
# may not statically discover. Each call is a one-time analysis cost.
hidden_imports += collect_submodules("pyannote")
hidden_imports += collect_submodules("pytorch_lightning")
hidden_imports += collect_submodules("lightning_fabric")

# --- Data files --------------------------------------------------------

datas = []
datas += collect_data_files("pyannote")
datas += collect_data_files("pytorch_lightning")
datas += collect_data_files("lightning_fabric")
datas += collect_data_files("librosa")
datas += collect_data_files("sklearn")

# --- Excludes (size budget) -------------------------------------------
#
# Reclaim 100–200 MB by dropping clearly-unused transitive deps. If a
# build fails with `ModuleNotFoundError` from one of these, remove from
# the excludes list and rebuild — they're optimistic, not load-bearing.

excludes = [
    "tensorboard",
    "torchvision",
    "IPython",
    "pytest",
    "tqdm.notebook",
    "matplotlib",
]

# --- Analysis / PYZ / EXE / COLLECT (the --onedir form) ---------------

a = Analysis(
    ["diarize.py"],
    pathex=[],
    binaries=[],
    datas=datas,
    hiddenimports=hidden_imports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=excludes,
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# In the --onedir form EXE() does NOT bundle binaries/zipfiles/datas;
# it just produces the bootstrap entry point. The COLLECT() step below
# walks the analysis output and assembles the dist/diarize/ tree.
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="diarize",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch="arm64",
    codesign_identity=None,
    entitlements_file=None,
)

# COLLECT bundles the Python interpreter, our script, all collected
# data files, and every dynamically-linked .dylib / .so under
# dist/diarize/. EPIC-04b's Run Script Build Phase signs this tree
# bottom-up before bundle-signing the .app.
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="diarize",
)
