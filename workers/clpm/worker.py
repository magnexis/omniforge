import json
import subprocess
import sys
from pathlib import Path


CLPM = Path(
    r"C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\CLPM.CLPM_Microsoft.Winget.Source_8wekyb3d8bbwe\clpm-0.4.2-rc.2-windows-amd64\bin\clpm.exe"
)
if not CLPM.exists():
    CLPM = Path("clpm")


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
                "workerId": "clpm-plan-01",
                "language": "clpm",
                "runtimeVersion": "0.4.2-rc.2",
                "workerVersion": "0.1.0",
                "status": "ready",
            }
        )
        send(
            {
                "type": "REGISTER",
                "protocol": "ofp/1",
                "workerId": "clpm-plan-01",
                "language": "clpm",
                "runtimeVersion": "0.4.2-rc.2",
                "workerVersion": "0.1.0",
                "capabilities": [{"name": "dev.common-lisp-tooling"}],
            }
        )
    elif message["type"] == "REGISTER_ACK":
        continue
    elif message["type"] == "JOB_START":
        if message["capability"] != "dev.common-lisp-tooling":
            send({"type": "JOB_ERROR", "jobId": "unknown", "error": "unsupported capability"})
            break
        send({"type": "JOB_ACCEPTED", "jobId": message["jobId"], "status": "running"})
        send({"type": "JOB_LOG", "jobId": message["jobId"], "severity": "info", "message": "starting dev.common-lisp-tooling"})
        completed = subprocess.run([str(CLPM), "version"], capture_output=True, text=True, check=False)
        version = (completed.stdout or completed.stderr or "").strip().splitlines()
        version_text = version[-1] if version else "unknown"
        package = str(message.get("input", {}).get("package", "") or "")
        send(
            {
                "type": "JOB_RESULT",
                "jobId": message["jobId"],
                "output": {
                    "tool": "clpm",
                    "version": version_text,
                    "requestedPackage": package,
                    "suggestedCommand": "clpm sync" if not package else f"clpm install {package}",
                },
            }
        )
        break
    elif message["type"] == "JOB_CANCEL":
        send({"type": "JOB_CANCELLED", "jobId": message.get("jobId", "job-unknown"), "status": "cancelled"})
        break
    elif message["type"] == "SHUTDOWN":
        send({"type": "SHUTDOWN_ACK", "workerId": "clpm-plan-01", "status": "stopped"})
        break
