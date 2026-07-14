import json
import subprocess
import sys
from pathlib import Path


FPM = Path(r"C:\Users\matth\AppData\Local\fortran-lang\fpm\fpm.exe")
if not FPM.exists():
    FPM = Path("fpm")


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
                "workerId": "fpm-plan-01",
                "language": "fpm",
                "runtimeVersion": "0.13.0",
                "workerVersion": "0.1.0",
                "status": "ready",
            }
        )
        send(
            {
                "type": "REGISTER",
                "protocol": "ofp/1",
                "workerId": "fpm-plan-01",
                "language": "fpm",
                "runtimeVersion": "0.13.0",
                "workerVersion": "0.1.0",
                "capabilities": [{"name": "dev.fortran-tooling"}],
            }
        )
    elif message["type"] == "REGISTER_ACK":
        continue
    elif message["type"] == "JOB_START":
        if message["capability"] != "dev.fortran-tooling":
            send({"type": "JOB_ERROR", "jobId": "unknown", "error": "unsupported capability"})
            break
        send({"type": "JOB_ACCEPTED", "jobId": message["jobId"], "status": "running"})
        send({"type": "JOB_LOG", "jobId": message["jobId"], "severity": "info", "message": "starting dev.fortran-tooling"})
        completed = subprocess.run([str(FPM), "--version"], capture_output=True, text=True, check=False)
        version = (completed.stdout or completed.stderr or "").strip().splitlines()
        version_text = version[0] if version else "unknown"
        package = str(message.get("input", {}).get("package", "") or "")
        send(
            {
                "type": "JOB_RESULT",
                "jobId": message["jobId"],
                "output": {
                    "tool": "fpm",
                    "version": version_text,
                    "requestedPackage": package,
                    "suggestedCommand": "fpm new demo" if not package else f"fpm build --profile {package}",
                },
            }
        )
        break
    elif message["type"] == "JOB_CANCEL":
        send({"type": "JOB_CANCELLED", "jobId": message.get("jobId", "job-unknown"), "status": "cancelled"})
        break
    elif message["type"] == "SHUTDOWN":
        send({"type": "SHUTDOWN_ACK", "workerId": "fpm-plan-01", "status": "stopped"})
        break
