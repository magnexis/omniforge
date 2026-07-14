import json
import os
import subprocess
import sys
from pathlib import Path


SCRYER = Path(
    r"C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\mthom.ScryerProlog_Microsoft.Winget.Source_8wekyb3d8bbwe\scryer-prolog_windows-latest_x86_64-pc-windows-msvc\scryer-prolog.exe"
)
if not SCRYER.exists():
    SCRYER = Path("scryer-prolog")

CACHE = Path(__file__).resolve().parent / ".cache"
CACHE.mkdir(exist_ok=True)
WORKDIR = Path(__file__).resolve().parent


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    if line.startswith("\ufeff"):
        line = line[1:]
    try:
        message = json.loads(line)
    except json.JSONDecodeError:
        continue

    if message.get("type") == "HELLO":
        send(
            {
                "type": "WELCOME",
                "protocol": "ofp/1",
                "workerId": "scryer-max-01",
            }
        )
        send(
            {
                "type": "REGISTER",
                "protocol": "ofp/1",
                "workerId": "scryer-max-01",
                "language": "scryer-prolog",
                "runtimeVersion": "0.9.3",
                "workerVersion": "0.1.0",
                "capabilities": [{"name": "math.max-scryer"}],
            }
        )
        continue

    if message.get("type") == "REGISTER_ACK":
        continue

    if message.get("type") == "JOB_START":
        if message["capability"] != "math.max-scryer":
            send({"type": "JOB_ERROR", "jobId": "unknown", "error": "unsupported capability"})
            continue
        send({"type": "JOB_ACCEPTED", "jobId": message["jobId"]})
        send({"type": "JOB_LOG", "jobId": message["jobId"], "level": "info", "message": "executing scryer max query"})
        numbers = message.get("input", {}).get("numbers", [])
        number_list = ",".join(str(n) for n in numbers)
        script = CACHE / f"job-{message['jobId']}.pl"
        script.write_text(
            "\n".join(
                [
                    ":- initialization(main).",
                    "",
                    "max_list([X], X).",
                    "max_list([H|T], Max) :-",
                    "    max_list(T, TailMax),",
                    "    ( H > TailMax -> Max = H ; Max = TailMax ).",
                    "",
                    "main :-",
                    f"    Numbers = [{number_list}],",
                    "    max_list(Numbers, Max),",
                    "    write(Max), nl.",
                ]
            ),
            encoding="utf-8",
        )
        child_env = {
            key: value
            for key, value in os.environ.items()
            if key.upper() in {"PATH", "SYSTEMROOT", "COMSPEC", "PATHEXT", "TEMP", "TMP"}
        }
        try:
            completed = subprocess.run(
                [str(SCRYER), str(script)],
                cwd=WORKDIR,
                env=child_env,
                stdin=subprocess.DEVNULL,
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
            )
        except subprocess.TimeoutExpired:
            send({"type": "JOB_ERROR", "jobId": message["jobId"], "error": "scryer runtime timed out"})
            continue
        value = (completed.stdout or "").strip()
        if not value:
            send(
                {
                    "type": "JOB_ERROR",
                    "jobId": message["jobId"],
                    "error": (completed.stderr or "scryer produced no result").strip(),
                }
            )
            continue
        send({"type": "JOB_RESULT", "jobId": message["jobId"], "output": {"max": int(value)}})
        continue

    if message.get("type") == "JOB_CANCEL":
        send({"type": "JOB_CANCELLED", "jobId": message.get("jobId", "job-unknown")})
        continue

    if message.get("type") == "SHUTDOWN":
        send({"type": "SHUTDOWN_ACK", "workerId": "scryer-max-01"})
        break
