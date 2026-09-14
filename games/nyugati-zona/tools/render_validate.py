#!/usr/bin/env python3
"""Render the actual game using software OpenGL, capture reviewable previews."""
import os
from pathlib import Path
import re
import subprocess
root = Path(__file__).resolve().parents[1]
engine = os.environ.get("GODOT_BIN", "godot")
run = subprocess.run(
    ["xvfb-run", "-a", engine, "--path", str(root), "--audio-driver", "Dummy",
     "--rendering-method", "gl_compatibility", "--resolution", "1280x720",
     "--", "--render-test"],
    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    timeout=180, env={**os.environ, "LIBGL_ALWAYS_SOFTWARE":"1"})
print(run.stdout)
(root/"render.log").write_text(run.stdout, encoding="utf-8")
if run.returncode or "NYUGATI_ZONA_RENDER_OK" not in run.stdout or re.search(r"SCRIPT ERROR|Parse Error|Shader compilation failed|Assertion failed", run.stdout, re.I):
    raise SystemExit("Rendered scene validation failed")
