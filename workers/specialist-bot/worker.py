import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKERS_DIR = ROOT / "workers"
SPECIALTIES_PATH = ROOT / "data" / "language-specialties.json"


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_manifests():
    manifests = []
    for path in sorted(WORKERS_DIR.glob("*/worker.json")):
        manifest = load_json(path)
        manifest["_path"] = str(path)
        manifests.append(manifest)
    return manifests


def resolve_language(payload, manifests):
    worker_id = payload.get("delegateWorkerId")
    if worker_id:
        manifest = next((entry for entry in manifests if entry["id"] == worker_id), None)
        if manifest is not None:
            return manifest["language"], manifest
    language = payload.get("assignedLanguage") or payload.get("language")
    if language:
        manifest = next((entry for entry in manifests if entry["language"].lower() == str(language).lower()), None)
        return str(language), manifest
    return "", None


def matching_workers(language: str, manifests):
    return [
        {
            "id": manifest["id"],
            "language": manifest["language"],
            "runtime": manifest["runtime"],
            "tier": manifest["tier"],
            "capabilities": [cap["name"] for cap in manifest.get("capabilities", [])],
        }
        for manifest in manifests
        if manifest["language"].lower() == language.lower()
    ]


def build_plan(capability: str, payload, manifests, specialties):
    language, inherited_manifest = resolve_language(payload, manifests)
    if not language:
        return {"error": "assignedLanguage or delegateWorkerId is required"}

    worker_matches = matching_workers(language, manifests)
    strength_entries = specialties.get(language.lower(), {}).get("strengths", [])
    preferred = []
    for entry in strength_entries:
        options = []
        for capability_name in entry.get("recommendedCapabilities", []):
            providers = [
                manifest["id"]
                for manifest in manifests
                if any(cap["name"] == capability_name for cap in manifest.get("capabilities", []))
            ]
            options.append(
                {
                    "capability": capability_name,
                    "providers": providers,
                }
            )
        preferred.append(
            {
                "area": entry.get("area"),
                "why": entry.get("why"),
                "executionOptions": options,
            }
        )

    response = {
        "assignedLanguage": language,
        "inheritedFromWorker": inherited_manifest["id"] if inherited_manifest else None,
        "requestedGoal": payload.get("goal", ""),
        "matchingWorkers": worker_matches,
        "languageStrengths": preferred,
    }

    if capability == "bot.execution-options":
        response["recommendedActions"] = [
            option
            for strength in preferred
            for option in strength["executionOptions"]
        ]
    elif capability == "bot.pipeline-handoff":
        response["handoffPlan"] = [
            {
                "step": index + 1,
                "area": strength["area"],
                "capabilities": [option["capability"] for option in strength["executionOptions"]],
            }
            for index, strength in enumerate(preferred)
        ]
    else:
        response["summary"] = f"{language} specialist bot inherited the language assignment and proposed language-native execution paths."

    return response


REGISTER = {
    "type": "REGISTER",
    "protocol": "ofp/1",
    "workerId": "specialist-bot-01",
    "language": "omniforge-bot",
    "runtimeVersion": "python-3.12",
    "workerVersion": "0.1.0",
    "capabilities": [
        {"name": "bot.language-plan"},
        {"name": "bot.execution-options"},
        {"name": "bot.pipeline-handoff"},
    ],
}


def main():
    manifests = load_manifests()
    specialties = load_json(SPECIALTIES_PATH)
    for raw in sys.stdin:
        raw = raw.strip()
        if not raw:
            continue
        message = json.loads(raw)
        if message["type"] == "HELLO":
            send(REGISTER)
            continue
        if message["type"] == "JOB_START":
            capability = message["capability"]
            if capability not in {"bot.language-plan", "bot.execution-options", "bot.pipeline-handoff"}:
                send({"type": "JOB_ERROR", "jobId": message["jobId"], "error": "unsupported capability"})
                break
            output = build_plan(capability, message.get("input", {}) or {}, manifests, specialties)
            if "error" in output:
                send({"type": "JOB_ERROR", "jobId": message["jobId"], "error": output["error"]})
                break
            send({"type": "JOB_RESULT", "jobId": message["jobId"], "output": output})
            break
        if message["type"] == "SHUTDOWN":
            break


if __name__ == "__main__":
    main()
