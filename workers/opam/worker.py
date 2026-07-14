import json
import subprocess
import sys
from pathlib import Path


OPAM = Path(r"C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\OCaml.opam_Microsoft.Winget.Source_8wekyb3d8bbwe\opam.exe")
if not OPAM.exists():
    OPAM = Path("opam")


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


for line in sys.stdin:
    message = json.loads(line)
    if message["type"] == "HELLO":
        send(
            {
                "type": "WELCOME",
                "protocol": "ofp/1",
                "workerId": "opam-plan-01",
                "language": "opam",
                "runtimeVersion": "2.5.2",
                "workerVersion": "0.1.0",
                "status": "ready",
            }
        )
        send(
            {
                "type": "REGISTER",
                "protocol": "ofp/1",
                "workerId": "opam-plan-01",
                "language": "opam",
                "runtimeVersion": "2.5.2",
                "workerVersion": "0.1.0",
                "capabilities": [{"name": "dev.ocaml-tooling"}],
            }
        )
    elif message["type"] == "REGISTER_ACK":
        continue
    elif message["type"] == "JOB_START":
        if message["capability"] != "dev.ocaml-tooling":
            send({"type": "JOB_ERROR", "jobId": "unknown", "error": "unsupported capability"})
            break
        send({"type": "JOB_ACCEPTED", "jobId": message["jobId"], "status": "running"})
        send({"type": "JOB_LOG", "jobId": message["jobId"], "severity": "info", "message": "starting dev.ocaml-tooling"})
        completed = subprocess.run([str(OPAM), "--version"], capture_output=True, text=True, check=False)
        version = (completed.stdout or completed.stderr or "").strip() or "unknown"
        package = str(message.get("input", {}).get("package", "") or "")
        send(
            {
                "type": "JOB_RESULT",
                "jobId": message["jobId"],
                "output": {
                    "tool": "opam",
                    "version": version,
                    "requestedPackage": package,
                    "suggestedCommand": "opam init" if not package else f"opam install {package}",
                },
            }
        )
        break
    elif message["type"] == "JOB_CANCEL":
        send({"type": "JOB_CANCELLED", "jobId": message.get("jobId", "job-unknown"), "status": "cancelled"})
        break
    elif message["type"] == "SHUTDOWN":
        send({"type": "SHUTDOWN_ACK", "workerId": "opam-plan-01", "status": "stopped"})
        break
