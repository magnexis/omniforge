import csv
import json
import queue
import sys
import threading
import time


REGISTER = {
    "type": "REGISTER",
    "protocol": "ofp/1",
    "workerId": "python-data-01",
    "language": "python",
    "runtimeVersion": sys.version.split()[0],
    "workerVersion": "0.1.0",
    "capabilities": [{"name": "data.csv-transform"}, {"name": "ops.incident-normalize"}],
}

WELCOME = {
    "type": "WELCOME",
    "protocol": "ofp/1",
    "workerId": "python-data-01",
    "language": "python",
    "runtimeVersion": sys.version.split()[0],
    "workerVersion": "0.1.0",
    "status": "ready"
}

incoming = queue.Queue()
canceled_jobs = set()


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


def load_csv(path):
    rows = []
    with open(path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            rows.append(
                {
                    "customer_id": row["customer_id"].strip(),
                    "name": row["name"].strip(),
                    "department": row["department"].strip().lower(),
                    "amount": float(row["amount"]),
                    "active": row["active"].strip().lower() == "true",
                }
            )
    return rows


def load_incidents(path):
    with open(path, "r", encoding="utf-8") as handle:
        payload = json.load(handle)
    incidents = []
    for item in payload.get("incidents", []):
        incidents.append(
            {
                "id": str(item["id"]).strip(),
                "service": str(item["service"]).strip().lower(),
                "host": str(item["host"]).strip().lower(),
                "cpu": int(item["cpu"]),
                "memory": int(item["memory"]),
                "restarts": int(item["restarts"]),
                "error_rate": float(item["error_rate"]),
                "region": str(item.get("region", "unknown")).strip().lower(),
            }
        )
    return incidents


def reader_loop():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        incoming.put(json.loads(line))


def drain_control_messages():
    while True:
        try:
            message = incoming.get_nowait()
        except queue.Empty:
            return
        if message["type"] == "JOB_CANCEL":
            canceled_jobs.add(message["jobId"])
        elif message["type"] == "SHUTDOWN":
            incoming.put(message)
            return
        else:
            incoming.put(message)
            return


def cancellable_wait(job_id, total_ms):
    elapsed = 0
    step = 25
    while elapsed < total_ms:
        drain_control_messages()
        if job_id in canceled_jobs:
            send({"type": "JOB_CANCELLED", "jobId": job_id, "status": "cancelled"})
            canceled_jobs.discard(job_id)
            return False
        time.sleep(step / 1000)
        elapsed += step
    return True


threading.Thread(target=reader_loop, daemon=True).start()

while True:
    message = incoming.get()
    if message["type"] == "HELLO":
        send(WELCOME)
        send(REGISTER)
    elif message["type"] == "REGISTER_ACK":
        continue
    elif message["type"] == "JOB_CANCEL":
        canceled_jobs.add(message["jobId"])
    elif message["type"] == "JOB_START":
        job_id = message["jobId"]
        capability = message["capability"]
        send({"type": "JOB_ACCEPTED", "jobId": job_id, "status": "running"})
        send({"type": "JOB_LOG", "jobId": job_id, "severity": "info", "message": f"starting {capability}"})
        if capability == "data.csv-transform":
            send({"type": "JOB_PROGRESS", "jobId": job_id, "progress": 0.15, "metadata": {"stage": "loading"}})
            if not cancellable_wait(job_id, int(message.get("input", {}).get("simulateDelayMs", 0) or 0)):
                continue
            input_path = message["input"]["inputPath"]
            rows = load_csv(input_path)
            send(
                {
                    "type": "JOB_RESULT",
                    "jobId": job_id,
                    "output": {
                        "rows": rows,
                        "rowCount": len(rows),
                    },
                }
            )
        elif capability == "ops.incident-normalize":
            send({"type": "JOB_PROGRESS", "jobId": job_id, "progress": 0.2, "metadata": {"stage": "normalizing"}})
            if not cancellable_wait(job_id, int(message.get("input", {}).get("simulateDelayMs", 0) or 0)):
                continue
            input_path = message["input"]["inputPath"]
            incidents = load_incidents(input_path)
            send(
                {
                    "type": "JOB_RESULT",
                    "jobId": job_id,
                    "output": {
                        "incidents": incidents,
                        "incidentCount": len(incidents),
                    },
                }
            )
        else:
            send({"type": "JOB_ERROR", "jobId": job_id, "error": "unsupported capability"})
    elif message["type"] == "SHUTDOWN":
        send({"type": "SHUTDOWN_ACK", "workerId": "python-data-01", "status": "stopped"})
        break
