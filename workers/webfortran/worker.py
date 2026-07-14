import json
import subprocess
import sys


WEBFORTRAN = "webfortran.exe"


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    message = json.loads(line)
    if message["type"] == "HELLO":
        send(
            {
                "type": "REGISTER",
                "protocol": "ofp/1",
                "workerId": "webfortran-status-01",
                "language": "webfortran",
                "runtimeVersion": "0.8",
                "workerVersion": "0.1.0",
                "capabilities": [{"name": "dev.webfortran-status"}],
            }
        )
    elif message["type"] == "JOB_START":
        if message["capability"] != "dev.webfortran-status":
            send({"type": "JOB_ERROR", "jobId": "unknown", "error": "unsupported capability"})
            break
        completed = subprocess.run([WEBFORTRAN, "--version"], capture_output=True, text=True, check=False)
        output = (completed.stdout or completed.stderr or "").strip().splitlines()
        authorized = not any("Not currently authorized" in line for line in output)
        send(
            {
                "type": "JOB_RESULT",
                "jobId": message["jobId"],
                "output": {
                    "tool": "webfortran",
                    "version": output[0] if output else "unknown",
                    "authorized": authorized,
                    "suggestedCommand": "webfortran.exe --login" if not authorized else "webfortran.exe source.f90",
                },
            }
        )
        break
    elif message["type"] == "SHUTDOWN":
        break
