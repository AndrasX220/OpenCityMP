#!/usr/bin/env python3
"""Import + gameplay gate; fail immediately on Godot script errors."""
import os
from pathlib import Path
import re
import subprocess
import sys
import threading

root = Path(__file__).resolve().parents[1]
engine = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("GODOT_BIN", "godot")
commands = [
    [engine, "--headless", "--path", str(root), "--editor", "--import", "--quit"],
    [engine, "--headless", "--path", str(root), "--", "--smoke-test"],
]
for index, command in enumerate(commands):
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, bufsize=1)
    timer = threading.Timer(150, process.kill)
    timer.daemon = True
    timer.start()
    lines = []
    failed = False
    try:
        for line in process.stdout:
            print(line, end="", flush=True)
            lines.append(line)
            if re.search(r"SCRIPT ERROR|Parse Error|Shader compilation failed|Assertion failed", line, re.I):
                failed = True
                process.terminate()
                break
        try:
            remaining, _ = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            remaining, _ = process.communicate()
        lines.append(remaining or "")
    finally:
        timer.cancel()
        if process.poll() is None:
            process.kill()
            process.wait()
    output = "".join(lines)
    (root / ("import.log" if index == 0 else "smoke.log")).write_text(output, encoding="utf-8")
    if process.returncode or failed:
        raise SystemExit("Godot validation failed")
    if index == 1 and "NYUGATI_ZONA_SMOKE_OK" not in output:
        raise SystemExit("Smoke-test completion marker missing")
print("VALIDATION PASSED")
