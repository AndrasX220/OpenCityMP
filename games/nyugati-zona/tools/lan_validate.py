#!/usr/bin/env python3
"""Run two real Godot processes: host world mutation -> replicated client inventory."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
root = Path(__file__).resolve().parents[1]
engine = os.environ.get("GODOT_BIN", "godot")
with tempfile.TemporaryDirectory(prefix="nyugati-zona-lan-") as folder:
    host_file = Path(folder)/"host.log"
    client_file = Path(folder)/"client.log"
    processes = []
    try:
        with host_file.open("w") as hout, client_file.open("w") as cout:
            for flag, log in [("--lan-host-test",hout),("--lan-client-test",cout)]:
                processes.append(subprocess.Popen(
                    [engine,"--headless","--path",str(root),"--",flag],
                    stdout=log,stderr=subprocess.STDOUT))
                if len(processes)==1:
                    time.sleep(3)
            for proc in processes:
                proc.wait(timeout=40)
        for name, path, marker in [
            ("host",host_file,"NYUGATI_ZONA_LAN_HOST_OK"),
            ("client",client_file,"NYUGATI_ZONA_LAN_CLIENT_OK")]:
            output=path.read_text()
            print(name.upper(),output)
            (root/f"lan-{name}.log").write_text(output)
            if marker not in output or re.search(r"SCRIPT ERROR|Parse Error|Assertion failed",output,re.I):
                raise SystemExit(f"LAN {name} validation failed")
        if any(proc.returncode for proc in processes):
            raise SystemExit("A LAN process returned an error")
    finally:
        for proc in processes:
            if proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
print("LAN VALIDATION PASSED")
