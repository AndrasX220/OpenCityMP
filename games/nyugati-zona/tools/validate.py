#!/usr/bin/env python3
"""Godot integration gate; catches script errors even when Godot exits zero."""
import os
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
engine = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("GODOT_BIN", "godot")
commands = [
    [engine, "--headless", "--path", str(root), "--editor", "--import"],
    [engine, "--headless", "--path", str(root), "--", "--smoke-test"],
]
for index, command in enumerate(commands):
    if index == 0:
        command += ["--quit"]
    try:
        run = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, timeout=180)
    except subprocess.TimeoutExpired as exc:
        print(exc.stdout or "")
        raise SystemExit("Godot timed out")
    output = run.stdout
    print(output)
    (root / ("import.log" if index == 0 else "smoke.log")).write_text(output, encoding="utf-8")
    if run.returncode or re.search(r"SCRIPT ERROR|Parse Error|Shader compilation failed|Assertion failed", output, re.I):
        raise SystemExit("Godot validation failed")
    if index == 1 and "NYUGATI_ZONA_SMOKE_OK" not in output:
        raise SystemExit("Smoke-test completion marker missing")
print("VALIDATION PASSED")
