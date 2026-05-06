# PyInstaller spec — Transcript Shadow diarization sidecar
# @implements ARC-002, TECH-006
# Build with: pyinstaller diarize.spec
# Output: dist/diarize (single-file ARM64 binary)

# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ["diarize.py"],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        "pyannote.audio",
        "pyannote.audio.pipelines",
        "torch",
        "torchaudio",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="diarize",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch="arm64",
    codesign_identity=None,
    entitlements_file=None,
)
