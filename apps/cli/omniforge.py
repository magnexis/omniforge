import argparse
import json
import os
import shutil
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
from shutil import which


ROOT = Path(__file__).resolve().parents[2]
COORDINATOR_DIR = ROOT / "apps" / "coordinator"
COORDINATOR = ["go", "run", "."]
TOOLCHAIN_MANIFEST_PATH = ROOT / "toolchains" / "manifest.json"
LANGUAGES_DIR = ROOT / "languages"
PIPELINES_DIR = ROOT / "pipelines"
WORKERS_DIR = ROOT / "workers"
CLI_STATE_PATH = ROOT / ".cache" / "omniforge-cli-state.json"

COMMAND_ALIASES = {
    "lua": r"C:\Users\matth\AppData\Local\Programs\Lua\bin\lua.exe",
    "bash": r"C:\Program Files\Git\usr\bin\bash.exe",
    "awk": r"C:\Program Files\Git\usr\bin\awk.exe",
    "perl": r"C:\Program Files\Git\usr\bin\perl.exe",
    "git": r"C:\Program Files\Git\cmd\git.exe",
    "sh": r"C:\Program Files\Git\bin\sh.exe",
    "julia": r"C:\Users\matth\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe",
    "groovy": r"C:\Program Files (x86)\Groovy\bin\groovy.bat",
    "Rscript": r"C:\Program Files\R\R-4.6.1\bin\Rscript.exe",
    "tclsh": r"C:\Program Files\Git\mingw64\bin\tclsh.exe",
    "octave-cli": r"C:\Users\matth\AppData\Local\Programs\GNU Octave\Octave-11.3.0\mingw64\bin\octave-cli.exe",
    "fbc": r"C:\Program Files (x86)\FreeBASIC\fbc.exe",
    "scala": r"C:\Program Files (x86)\scala\bin\scala.bat",
    "dmd": r"C:\D\dmd2\windows\bin64\dmd.exe",
    "crystal": r"C:\Users\matth\AppData\Local\Programs\Crystal\crystal.exe",
    "fpc": r"C:\FPC\3.2.2\bin\i386-win32\fpc.exe",
    "gforth": r"C:\Program Files (x86)\gforth\gforth.exe",
    "bb": str(ROOT / ".cache" / "runtime-shims" / "bb.exe"),
    "gleam": str(ROOT / ".cache" / "runtime-shims" / "gleam.exe"),
    "raku": r"C:\Program Files\Rakudo\bin\raku.exe",
    "sbcl": r"C:\Program Files\Steel Bank Common Lisp\sbcl.exe",
    "nu": r"C:\Users\matth\AppData\Local\Programs\nu\bin\nu.exe",
    "elvish": str(ROOT / ".cache" / "runtime-shims" / "elvish.exe"),
    "dart": str(ROOT / ".cache" / "runtime-shims" / "dart-sdk" / "bin" / "dart.exe"),
    "zig": str(ROOT / ".cache" / "runtime-shims" / "zig" / "zig.exe"),
    "racket": r"C:\Program Files\Racket\Racket.exe",
    "escript": r"C:\Program Files\Erlang OTP\bin\escript.exe",
    "erl": r"C:\Program Files\Erlang OTP\bin\erl.exe",
    "swipl": r"C:\Program Files\swipl\bin\swipl.exe",
    "nim": str(ROOT / ".cache" / "runtime-shims" / "nim.exe"),
    "powershell": r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
    "jq": str(ROOT / ".cache" / "runtime-shims" / "jq.exe"),
    "protoc": str(ROOT / ".cache" / "runtime-shims" / "protoc.exe"),
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def print_json(payload):
    print(json.dumps(payload, indent=2))


def file_size_bytes(path: Path):
    if not path.exists():
        return 0
    if path.is_file():
        return path.stat().st_size
    total = 0
    for child in path.rglob("*"):
        if child.is_file():
            try:
                total += child.stat().st_size
            except OSError:
                pass
    return total


def normalize_key(value: str) -> str:
    return value.strip().lower().replace("-", " ")


def load_cli_state():
    if not CLI_STATE_PATH.exists():
        return {"selectedLanguage": None, "selectedWorkerId": None}
    try:
        payload = load_json(CLI_STATE_PATH)
    except (json.JSONDecodeError, OSError):
        return {"selectedLanguage": None, "selectedWorkerId": None}
    return {
        "selectedLanguage": payload.get("selectedLanguage"),
        "selectedWorkerId": payload.get("selectedWorkerId"),
    }


def save_cli_state(payload):
    CLI_STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CLI_STATE_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def clear_cli_state():
    save_cli_state({"selectedLanguage": None, "selectedWorkerId": None})


def iter_cleanup_targets():
    dist_dir = ROOT / "dist"
    latest_zip = dist_dir / "omniforge-cli-latest.zip"
    explicit_targets = [
        ROOT / ".cache" / "go",
        ROOT / ".cache" / "cobolx-src",
        ROOT / ".cache" / "magnificent-language-src",
        ROOT / ".cache" / "omniforge-cli-state.json",
        ROOT / ".cache" / "runtime-shims" / "zig.exe",
        ROOT / ".cache" / "runtime-shims" / "dart.exe",
    ]
    for target in explicit_targets:
        yield target
    if dist_dir.exists():
        for path in sorted(dist_dir.iterdir()):
            if path == latest_zip or path.name == ".gitkeep":
                continue
            if path.name.startswith("omniforge-cli-dev-"):
                yield path


def stop_repo_helper_processes():
    script = f"""
$repo = {str(ROOT)!r}
$killed = @()
Get-Process coordinator,go -ErrorAction SilentlyContinue | ForEach-Object {{
  $path = $_.Path
  if ($_.ProcessName -eq 'go' -or ($path -and ($path -like "$repo*" -or $path -like "$env:LOCALAPPDATA\\Temp\\go-build*" -or $path -like "$env:LOCALAPPDATA\\go-build*"))) {{
    try {{
      Stop-Process -Id $_.Id -Force -ErrorAction Stop
      $killed += [pscustomobject]@{{ processName = $_.ProcessName; id = $_.Id; path = $path }}
    }} catch {{}}
  }}
}}
$killed | ConvertTo-Json -Depth 3
"""
    completed = subprocess.run(
        ["powershell", "-NoProfile", "-Command", script],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        return {"error": completed.stderr.strip() or completed.stdout.strip()}
    output = completed.stdout.strip()
    if not output:
        return []
    payload = json.loads(output)
    return payload if isinstance(payload, list) else [payload]


def find_worker(worker_id: str):
    payload = json.loads(run_coordinator(["workers"]))
    return next((entry for entry in payload if entry["workerId"].lower() == worker_id.lower()), None)


def find_language(language: str):
    worker_match = next((entry for entry in build_languages_payload() if entry["language"].lower() == language.lower()), None)
    if worker_match:
        return worker_match["language"]
    catalog_match = next((entry for entry in load_language_catalog() if entry["_slug"].lower() == language.lower()), None)
    if catalog_match:
        return catalog_match["_slug"]
    return None


def get_effective_language(explicit_language=None):
    if explicit_language:
        return explicit_language
    state = load_cli_state()
    if state.get("selectedWorkerId"):
        worker = find_worker(state["selectedWorkerId"])
        if worker:
            return worker["language"]
    return state.get("selectedLanguage")


def get_effective_worker_id(explicit_worker_id=None):
    if explicit_worker_id:
        return explicit_worker_id
    return load_cli_state().get("selectedWorkerId")


def safe_path_exists(path_string: str) -> bool:
    try:
        return Path(path_string).exists()
    except (PermissionError, OSError):
        return False


def load_worker_manifests():
    manifests = []
    for path in sorted(WORKERS_DIR.glob("*/worker.json")):
        manifest = load_json(path)
        manifest["_path"] = str(path)
        manifests.append(manifest)
    return manifests


def load_support_levels():
    levels = {}
    for line in (ROOT / "docs" / "support-matrix.md").read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped.startswith("|") or stripped.startswith("| ---"):
            continue
        parts = [part.strip() for part in stripped.strip("|").split("|")]
        if len(parts) != 4 or parts[0] == "Language":
            continue
        levels[normalize_key(parts[0])] = {
            "display": parts[0],
            "role": parts[1],
            "headlineCapability": parts[2],
            "level": parts[3],
        }
    return levels


def load_language_catalog():
    records = []
    for path in sorted(LANGUAGES_DIR.glob("*/metadata.json")):
        payload = load_json(path)
        payload["_path"] = str(path)
        payload["_slug"] = path.parent.name
        readme_path = path.parent / "README.md"
        toolchain_path = path.parent / "toolchain" / "manifest.json"
        payload["_readme"] = str(readme_path) if readme_path.exists() else None
        payload["_toolchain"] = str(toolchain_path) if toolchain_path.exists() else None
        records.append(payload)
    return records


def run_coordinator(args):
    cache_root = ROOT / ".cache" / "go"
    cache_root.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["GOCACHE"] = str(cache_root / "build")
    env["GOMODCACHE"] = str(cache_root / "pkg")
    completed = subprocess.run(
        COORDINATOR + args,
        cwd=COORDINATOR_DIR,
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(completed.stderr.strip() or completed.stdout.strip() or completed.returncode)
    return completed.stdout


def parse_pipeline_yaml(path: Path) -> dict:
    name = ""
    steps = []
    current = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        stripped = raw.strip()
        if not stripped:
            continue
        if stripped.startswith("name:"):
            name = stripped.split(":", 1)[1].strip()
        elif stripped == "steps:":
            continue
        elif stripped.startswith("- capability:"):
            if current:
                steps.append(current)
            current = {"capability": stripped.split(":", 1)[1].strip()}
        elif stripped.startswith("language:") and current is not None:
            current["language"] = stripped.split(":", 1)[1].strip()
    if current:
        steps.append(current)
    return {"name": name, "steps": steps}


def ensure_pipeline_json(path: Path) -> Path:
    if not path.is_absolute():
        path = (ROOT / path).resolve()
    if path.suffix == ".json":
        return path
    pipeline = parse_pipeline_yaml(path)
    generated = ROOT / ".cache" / "pipeline.json"
    generated.parent.mkdir(exist_ok=True)
    generated.write_text(json.dumps(pipeline, indent=2), encoding="utf-8")
    return generated


def resolve_toolchain_command(command):
    resolved = list(command)
    executable = resolved[0]
    if executable in COMMAND_ALIASES and safe_path_exists(COMMAND_ALIASES[executable]):
        resolved[0] = COMMAND_ALIASES[executable]
    elif which(executable):
        resolved[0] = which(executable)
    return resolved


def run_detect_command(command):
    executable = command[0]
    if executable.lower().endswith((".bat", ".cmd")):
        launch = [os.environ.get("COMSPEC", r"C:\Windows\System32\cmd.exe"), "/c", *command]
    else:
        launch = command
    return subprocess.run(launch, cwd=ROOT, capture_output=True, text=True, shell=False, check=False)


def load_toolchain_statuses():
    toolchains = load_json(TOOLCHAIN_MANIFEST_PATH)
    statuses = []
    for entry in toolchains["toolchains"]:
        command = resolve_toolchain_command(entry["detect"])
        if not safe_path_exists(command[0]) and which(command[0]) is None:
            statuses.append(
                {
                    "language": entry["language"],
                    "available": False,
                    "detect": command,
                    "reason": "command-not-found",
                }
            )
            continue
        try:
            completed = run_detect_command(command)
        except PermissionError as exc:
            statuses.append(
                {
                    "language": entry["language"],
                    "available": False,
                    "detect": command,
                    "reason": "permission-denied",
                    "error": str(exc),
                }
            )
            continue
        except OSError as exc:
            statuses.append(
                {
                    "language": entry["language"],
                    "available": False,
                    "detect": command,
                    "reason": "launch-failed",
                    "error": str(exc),
                }
            )
            continue
        statuses.append(
            {
                "language": entry["language"],
                "available": completed.returncode == 0,
                "detect": command,
                "stdout": (completed.stdout or "").strip(),
                "stderr": (completed.stderr or "").strip(),
            }
        )
    return statuses


def resolve_input_path(input_value: str) -> Path:
    path = Path(input_value)
    return (ROOT / path).resolve() if not path.is_absolute() else path


def filter_workers(payload, args):
    filtered = payload
    if getattr(args, "language", None):
        filtered = [entry for entry in filtered if entry["language"].lower() == args.language.lower()]
    if getattr(args, "tier", None):
        filtered = [entry for entry in filtered if entry.get("tier", "").lower() == args.tier.lower()]
    if getattr(args, "query", None):
        query = args.query.lower()
        filtered = [
            entry
            for entry in filtered
            if query in entry["workerId"].lower()
            or query in entry["language"].lower()
            or any(query in cap["name"].lower() for cap in entry.get("capabilities", []))
        ]
    return filtered


def summarize_workers(payload):
    tier_counts = Counter(entry.get("tier", "unknown") for entry in payload)
    language_counts = Counter(entry["language"] for entry in payload)
    return {
        "workerCount": len(payload),
        "languageCount": len(language_counts),
        "tiers": dict(sorted(tier_counts.items())),
        "languages": dict(sorted(language_counts.items())),
    }


def cmd_overview(_args):
    workers = json.loads(run_coordinator(["workers"]))
    capabilities = json.loads(run_coordinator(["capabilities"]))
    support = load_support_levels()
    catalog = load_language_catalog()
    state = load_cli_state()
    pipelines = [path.name for path in sorted(PIPELINES_DIR.glob("*.json"))] + [path.name for path in sorted(PIPELINES_DIR.glob("*.yaml"))]
    payload = {
        "project": "Omniforge",
        "repositoryMode": "rainbow-repository",
        "activeContext": state,
        "workers": summarize_workers(workers),
        "capabilityCount": len(capabilities),
        "cataloguedLanguages": len(catalog),
        "supportMatrixEntries": len(support),
        "pipelineFiles": pipelines,
        "recommendedNextCommands": [
            "python omniforge.py workers summary",
            "python omniforge.py capabilities search data",
            "python omniforge.py toolchains doctor",
            "python omniforge.py pipeline list",
        ],
    }
    print_json(payload)


def cmd_workers(args):
    payload = json.loads(run_coordinator(["workers"]))
    print_json(filter_workers(payload, args))


def cmd_workers_summary(_args):
    payload = json.loads(run_coordinator(["workers"]))
    print_json(summarize_workers(payload))


def cmd_workers_inspect(args):
    target_worker_id = get_effective_worker_id(args.worker_id)
    if not target_worker_id:
        raise SystemExit("worker id required or select a worker with 'python omniforge.py select worker <worker-id>'")
    payload = json.loads(run_coordinator(["workers"]))
    worker = next((entry for entry in payload if entry["workerId"].lower() == target_worker_id.lower()), None)
    if worker is None:
        raise SystemExit(f"worker not found: {target_worker_id}")
    manifest = next((entry for entry in load_worker_manifests() if entry["id"] == target_worker_id), None)
    if manifest:
        worker["manifestPath"] = manifest["_path"]
        worker["command"] = manifest.get("command", [])
        worker["workingDirectory"] = manifest.get("workingDirectory")
        worker["runtime"] = manifest.get("runtime")
        worker["tier"] = manifest.get("tier")
    worker["examples"] = sorted(str(path) for path in (ROOT / "workers" / worker["language"]).glob("examples/**/*") if path.is_file())
    print_json(worker)


def cmd_capabilities(_args):
    payload = json.loads(run_coordinator(["capabilities"]))
    print_json(payload)


def cmd_capabilities_search(args):
    payload = json.loads(run_coordinator(["capabilities"]))
    query = args.query.lower()
    matches = [entry for entry in payload if query in entry["capability"].lower() or query in entry["language"].lower()]
    print_json(matches)


def cmd_capabilities_summary(_args):
    payload = json.loads(run_coordinator(["capabilities"]))
    language_counts = Counter(entry["language"] for entry in payload)
    prefix_counts = Counter(entry["capability"].split(".", 1)[0] for entry in payload)
    print_json(
        {
            "capabilityCount": len(payload),
            "languagesWithCapabilities": len(language_counts),
            "byLanguage": dict(sorted(language_counts.items())),
            "byDomainPrefix": dict(sorted(prefix_counts.items())),
        }
    )


def build_languages_payload():
    manifests = load_worker_manifests()
    support = load_support_levels()
    records = []
    for manifest in manifests:
        info = support.get(normalize_key(manifest["language"]), {})
        records.append(
            {
                "language": manifest["language"],
                "workerId": manifest["id"],
                "runtime": manifest["runtime"],
                "tier": manifest["tier"],
                "level": info.get("level", "unknown"),
                "capabilities": [cap["name"] for cap in manifest.get("capabilities", [])],
            }
        )
    return sorted(records, key=lambda item: item["language"].lower())


def summarize_language_catalog_entry(slug: str, manifests, support_entry):
    highest_tier = None
    if manifests:
        highest_tier = sorted((manifest.get("tier", "tier-0") for manifest in manifests))[-1]
    support_level = (support_entry or {}).get("level", "").strip().lower().replace(" ", "-")
    worker_count = len(manifests)
    expected = {
        "supportTier": None,
        "status": None,
        "workerStatus": None,
    }
    if worker_count == 0:
        expected["supportTier"] = "tier-0"
        expected["status"] = "catalogued"
        expected["workerStatus"] = "not-counted"
    elif highest_tier == "tier-1":
        expected["supportTier"] = "tier-1"
        expected["status"] = "example-available"
        expected["workerStatus"] = "tracked-only"
    elif highest_tier == "tier-2":
        expected["supportTier"] = "tier-2"
        expected["status"] = "container-backed"
        expected["workerStatus"] = "container-backed"
    else:
        expected["supportTier"] = highest_tier or support_level or "tier-0"
        expected["status"] = "operational"
        expected["workerStatus"] = "operational"
    return expected


def cmd_languages_doctor(_args):
    manifests = load_worker_manifests()
    support = load_support_levels()
    catalog = load_language_catalog()
    manifests_by_language = defaultdict(list)
    for manifest in manifests:
        manifests_by_language[manifest["language"].lower()].append(manifest)

    issues = []
    for entry in catalog:
        slug = entry["_slug"]
        manifest_list = manifests_by_language.get(slug.lower(), [])
        support_entry = support.get(normalize_key(slug))
        expected = summarize_language_catalog_entry(slug, manifest_list, support_entry)
        actual = {
            "supportTier": entry.get("supportTier"),
            "status": entry.get("status"),
            "workerStatus": entry.get("workerStatus"),
        }
        mismatches = []
        for key, expected_value in expected.items():
            actual_value = actual.get(key)
            if expected_value != actual_value:
                mismatches.append(
                    {
                        "field": key,
                        "expected": expected_value,
                        "actual": actual_value,
                    }
                )
        if mismatches:
            issues.append(
                {
                    "language": slug,
                    "workerCount": len(manifest_list),
                    "workerTiers": sorted({manifest.get("tier", "tier-0") for manifest in manifest_list}),
                    "supportMatrixLevel": support_entry.get("level") if support_entry else None,
                    "metadataPath": entry["_path"],
                    "readmePath": entry["_readme"],
                    "mismatches": mismatches,
                }
            )

    print_json(
        {
            "cataloguedLanguages": len(catalog),
            "workerBackedLanguages": len(manifests_by_language),
            "issueCount": len(issues),
            "issues": sorted(issues, key=lambda item: item["language"].lower()),
        }
    )


def cmd_languages(_args):
    payload = build_languages_payload()
    print_json(payload)


def cmd_languages_catalog(_args):
    catalog = load_language_catalog()
    payload = []
    for entry in catalog:
        payload.append(
            {
                "language": entry["_slug"],
                "name": entry.get("name", entry["_slug"]),
                "status": entry.get("status", "unknown"),
                "supportTier": entry.get("supportTier", "unknown"),
                "workerStatus": entry.get("workerStatus", "unknown"),
                "metadataPath": entry["_path"],
                "readmePath": entry["_readme"],
                "toolchainPath": entry["_toolchain"],
            }
        )
    print_json(payload)


def cmd_languages_inspect(args):
    target_language = get_effective_language(args.language)
    if not target_language:
        raise SystemExit("language required or select a language with 'python omniforge.py select language <language>'")
    manifests = [entry for entry in load_worker_manifests() if entry["language"].lower() == target_language.lower()]
    support = load_support_levels().get(normalize_key(target_language), {})
    catalog = next((entry for entry in load_language_catalog() if entry["_slug"].lower() == target_language.lower()), None)
    if not manifests and not catalog:
        raise SystemExit(f"language not found: {target_language}")
    payload = {
        "language": manifests[0]["language"] if manifests else catalog["name"],
        "support": support,
        "catalog": None,
        "workers": [],
    }
    if catalog:
        payload["catalog"] = {
            "slug": catalog["_slug"],
            "status": catalog.get("status"),
            "supportTier": catalog.get("supportTier"),
            "workerStatus": catalog.get("workerStatus"),
            "metadataPath": catalog["_path"],
            "readmePath": catalog["_readme"],
            "toolchainPath": catalog["_toolchain"],
        }
    if manifests:
        payload["workers"] = [
            {
                "id": manifest["id"],
                "runtime": manifest["runtime"],
                "tier": manifest["tier"],
                "workingDirectory": manifest.get("workingDirectory"),
                "command": manifest.get("command", []),
                "capabilities": manifest.get("capabilities", []),
                "manifestPath": manifest["_path"],
            }
            for manifest in manifests
        ]
    print_json(payload)


def cmd_run(args):
    payload_path = resolve_input_path(args.input)
    effective_language = get_effective_language(args.language)
    command = [
        "run-job",
        "--capability",
        args.capability,
        "--language",
        effective_language or "",
        "--input",
        str(payload_path),
    ]
    if args.cancel_after_ms:
        command.extend(["--cancel-after-ms", str(args.cancel_after_ms)])
    output = run_coordinator(command)
    print(output)


def cmd_run_explain(args):
    manifests = load_worker_manifests()
    effective_language = get_effective_language(args.language)
    matches = []
    for manifest in manifests:
        if effective_language and manifest["language"].lower() != effective_language.lower():
            continue
        for capability in manifest.get("capabilities", []):
            if capability["name"] == args.capability:
                matches.append(
                    {
                        "workerId": manifest["id"],
                        "language": manifest["language"],
                        "runtime": manifest["runtime"],
                        "tier": manifest["tier"],
                        "workingDirectory": manifest.get("workingDirectory"),
                        "command": manifest.get("command", []),
                        "capability": capability["name"],
                        "inputSchema": capability.get("inputSchema"),
                        "outputSchema": capability.get("outputSchema"),
                    }
                )
    if not matches:
        raise SystemExit(f"no worker found for capability={args.capability} language={effective_language or '*'}")
    payload = {
        "capability": args.capability,
        "requestedLanguage": effective_language,
        "inputPath": str(resolve_input_path(args.input)) if args.input else None,
        "matches": matches,
        "schedulerNote": "The coordinator currently selects the first compatible worker in manifest order after capability and optional language filtering.",
    }
    print_json(payload)


def cmd_pipeline(args):
    pipeline_json = ensure_pipeline_json(Path(args.pipeline))
    input_path = resolve_input_path(args.input)
    output = run_coordinator(
        [
            "run-pipeline",
            "--pipeline",
            str(pipeline_json),
            "--input",
            str(input_path),
        ]
    )
    print(output)


def cmd_pipeline_list(_args):
    pipelines = []
    for path in sorted(PIPELINES_DIR.glob("*.json")):
        payload = load_json(path)
        pipelines.append(
            {
                "name": payload.get("name", path.stem),
                "path": str(path),
                "format": "json",
                "stepCount": len(payload.get("steps", [])),
                "languages": sorted({step.get("language", "auto") for step in payload.get("steps", [])}),
            }
        )
    for path in sorted(PIPELINES_DIR.glob("*.yaml")):
        payload = parse_pipeline_yaml(path)
        pipelines.append(
            {
                "name": payload.get("name", path.stem),
                "path": str(path),
                "format": "yaml",
                "stepCount": len(payload.get("steps", [])),
                "languages": sorted({step.get("language", "auto") for step in payload.get("steps", [])}),
            }
        )
    print_json(sorted(pipelines, key=lambda item: item["name"].lower()))


def cmd_pipeline_inspect(args):
    path = Path(args.pipeline)
    if not path.is_absolute():
        path = ROOT / path
    payload = load_json(path) if path.suffix == ".json" else parse_pipeline_yaml(path)
    payload["path"] = str(path.resolve())
    payload["stepCount"] = len(payload.get("steps", []))
    payload["languages"] = sorted({step.get("language", "auto") for step in payload.get("steps", [])})
    print_json(payload)


def cmd_toolchains_detect(_args):
    print_json(load_toolchain_statuses())


def cmd_toolchains_list(_args):
    toolchains = load_json(TOOLCHAIN_MANIFEST_PATH)
    payload = [
        {
            "language": entry["language"],
            "detect": resolve_toolchain_command(entry["detect"]),
        }
        for entry in toolchains["toolchains"]
    ]
    print_json(payload)


def cmd_toolchains_doctor(_args):
    statuses = load_toolchain_statuses()
    available = [entry for entry in statuses if entry["available"]]
    unavailable = [entry for entry in statuses if not entry["available"]]
    reasons = Counter(entry.get("reason", "ok") for entry in unavailable)
    payload = {
        "summary": {
            "total": len(statuses),
            "available": len(available),
            "unavailable": len(unavailable),
            "unavailableReasons": dict(sorted(reasons.items())),
        },
        "availableLanguages": sorted(entry["language"] for entry in available),
        "unavailableLanguages": sorted(
            [
                {
                    "language": entry["language"],
                    "reason": entry.get("reason", "unknown"),
                    "detect": entry["detect"],
                }
                for entry in unavailable
            ],
            key=lambda item: item["language"].lower(),
        ),
    }
    print_json(payload)


def cmd_examples(_args):
    examples = defaultdict(list)
    active_language = get_effective_language()
    for path in sorted(WORKERS_DIR.glob("*/examples/**/*")):
        if path.is_file():
            worker_name = path.relative_to(WORKERS_DIR).parts[0]
            if active_language and worker_name.lower() != active_language.lower():
                continue
            examples[worker_name].append(str(path.relative_to(ROOT)))
    print_json(dict(sorted(examples.items())))


def cmd_context_status(_args):
    state = load_cli_state()
    payload = {
        "selectedLanguage": state.get("selectedLanguage"),
        "selectedWorkerId": state.get("selectedWorkerId"),
        "effectiveLanguage": get_effective_language(),
        "suggestedCommands": [],
    }
    if state.get("selectedWorkerId"):
        payload["suggestedCommands"] = [
            f"python omniforge.py workers inspect {state['selectedWorkerId']}",
            "python omniforge.py run-explain <capability>",
            "python omniforge.py context clear",
        ]
    elif state.get("selectedLanguage"):
        payload["suggestedCommands"] = [
            f"python omniforge.py languages inspect {state['selectedLanguage']}",
            "python omniforge.py workers",
            "python omniforge.py capabilities summary",
            "python omniforge.py context clear",
        ]
    else:
        payload["suggestedCommands"] = [
            "python omniforge.py select language python",
            "python omniforge.py select worker python-data-01",
        ]
    print_json(payload)


def cmd_context_clear(_args):
    clear_cli_state()
    print_json(
        {
            "cleared": True,
            "selectedLanguage": None,
            "selectedWorkerId": None,
        }
    )


def cmd_select_language(args):
    language = find_language(args.language)
    if not language:
        raise SystemExit(f"language not found: {args.language}")
    save_cli_state({"selectedLanguage": language, "selectedWorkerId": None})
    print_json(
        {
            "selectedLanguage": language,
            "selectedWorkerId": None,
            "commandsUnlocked": [
                f"python omniforge.py languages inspect {language}",
                "python omniforge.py workers",
                "python omniforge.py run-explain <capability>",
                "python omniforge.py examples",
            ],
        }
    )


def cmd_select_worker(args):
    worker = find_worker(args.worker_id)
    if not worker:
        raise SystemExit(f"worker not found: {args.worker_id}")
    save_cli_state({"selectedLanguage": worker["language"], "selectedWorkerId": worker["workerId"]})
    print_json(
        {
            "selectedLanguage": worker["language"],
            "selectedWorkerId": worker["workerId"],
            "commandsUnlocked": [
                f"python omniforge.py workers inspect {worker['workerId']}",
                f"python omniforge.py languages inspect {worker['language']}",
                "python omniforge.py run-explain <capability>",
                "python omniforge.py context clear",
            ],
        }
    )


def cmd_help_topics(_args):
    payload = {
        "commands": {
            "overview": "High-level repository summary and next commands.",
            "workers": "List, filter, summarize, and inspect OFP workers.",
            "capabilities": "List, summarize, and search capability declarations.",
            "languages": "Inspect worker-backed languages and the wider catalog.",
            "languages doctor": "Audit catalog metadata against real worker and support-matrix status.",
            "run": "Execute a capability through the coordinator.",
            "pipeline": "List, inspect, and execute pipelines.",
            "toolchains": "Inspect host runtime detection and run doctor checks.",
            "examples": "List example inputs and example source trees.",
            "select": "Persist an active language or worker selection for later commands.",
            "context": "Inspect or clear the active CLI selection state.",
            "cleanup": "Clear safe caches, stale release artifacts, and orphaned helper processes.",
        },
        "examples": [
            "python omniforge.py overview",
            "python omniforge.py select language python",
            "python omniforge.py select worker scryer-max-01",
            "python omniforge.py context status",
            "python omniforge.py workers summary",
            "python omniforge.py workers --language python",
            "python omniforge.py capabilities summary",
            "python omniforge.py run-explain text.template --language lua --input examples/data/template-input.json",
            "python omniforge.py toolchains doctor",
            "python omniforge.py languages catalog",
            "python omniforge.py languages doctor",
            "python omniforge.py cleanup",
            "python omniforge.py cleanup --dry-run",
        ],
    }
    print_json(payload)


def cmd_cleanup(args):
    targets = []
    for path in iter_cleanup_targets():
        if path.exists():
            targets.append(
                {
                    "path": str(path),
                    "exists": True,
                    "sizeBytes": file_size_bytes(path),
                    "sizeMB": round(file_size_bytes(path) / (1024 * 1024), 1),
                    "kind": "directory" if path.is_dir() else "file",
                }
            )
    stopped = [] if args.skip_processes else stop_repo_helper_processes()
    if args.dry_run:
        print_json(
            {
                "mode": "dry-run",
                "wouldClearCliState": True,
                "wouldStopProcesses": False if args.skip_processes else True,
                "processes": stopped,
                "targets": targets,
                "totalTargetMB": round(sum(item["sizeMB"] for item in targets), 1),
                "kept": [
                    "dist/omniforge-cli-latest.zip",
                    "current repository files",
                    "runtime-shims directories",
                ],
            }
        )
        return

    clear_cli_state()
    removed = []
    failed = []
    for item in targets:
        path = Path(item["path"])
        try:
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()
            removed.append(item)
        except OSError as exc:
            failed.append({"path": item["path"], "error": str(exc)})
    print_json(
        {
            "mode": "apply",
            "clearedCliState": True,
            "stoppedProcesses": stopped,
            "removed": removed,
            "failed": failed,
            "freedMB": round(sum(item["sizeMB"] for item in removed), 1),
            "kept": [
                "dist/omniforge-cli-latest.zip",
                "current repository files",
                "runtime-shims directories",
            ],
        }
    )


def main():
    parser = argparse.ArgumentParser(
        description="Omniforge CLI",
        epilog="Use 'python omniforge.py help-topics' for guided examples and command discovery.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    overview = subparsers.add_parser("overview", help="Show a high-level repository and runtime summary.")
    overview.set_defaults(func=cmd_overview)

    workers = subparsers.add_parser("workers", help="List, filter, summarize, and inspect workers.")
    workers.add_argument("--language", help="Filter worker list by exact language.")
    workers.add_argument("--tier", help="Filter worker list by exact tier, e.g. tier-3.")
    workers.add_argument("--query", help="Filter worker list by worker id, language, or capability substring.")
    workers_sub = workers.add_subparsers(dest="workers_command")
    workers.set_defaults(func=cmd_workers)
    workers_list = workers_sub.add_parser("list", help="List all workers.")
    workers_list.add_argument("--language")
    workers_list.add_argument("--tier")
    workers_list.add_argument("--query")
    workers_list.set_defaults(func=cmd_workers)
    workers_summary = workers_sub.add_parser("summary", help="Summarize worker counts by tier and language.")
    workers_summary.set_defaults(func=cmd_workers_summary)
    workers_inspect = workers_sub.add_parser("inspect", help="Inspect a specific worker manifest and runtime metadata.")
    workers_inspect.add_argument("worker_id", nargs="?")
    workers_inspect.set_defaults(func=cmd_workers_inspect)

    capabilities = subparsers.add_parser("capabilities", help="List and search capabilities.")
    capabilities_sub = capabilities.add_subparsers(dest="capabilities_command")
    capabilities.set_defaults(func=cmd_capabilities)
    capabilities_list = capabilities_sub.add_parser("list", help="List all capabilities.")
    capabilities_list.set_defaults(func=cmd_capabilities)
    capabilities_search = capabilities_sub.add_parser("search", help="Search capabilities by capability or language.")
    capabilities_search.add_argument("query")
    capabilities_search.set_defaults(func=cmd_capabilities_search)
    capabilities_summary = capabilities_sub.add_parser("summary", help="Summarize capabilities by language and domain.")
    capabilities_summary.set_defaults(func=cmd_capabilities_summary)

    languages = subparsers.add_parser("languages", help="Inspect worker-backed languages and wider language catalog entries.")
    languages_sub = languages.add_subparsers(dest="languages_command")
    languages.set_defaults(func=cmd_languages)
    languages_list = languages_sub.add_parser("list", help="List worker-backed languages.")
    languages_list.set_defaults(func=cmd_languages)
    languages_catalog = languages_sub.add_parser("catalog", help="List all catalogued languages from languages/.")
    languages_catalog.set_defaults(func=cmd_languages_catalog)
    languages_doctor = languages_sub.add_parser("doctor", help="Audit catalog metadata against worker and support status.")
    languages_doctor.set_defaults(func=cmd_languages_doctor)
    languages_inspect = languages_sub.add_parser("inspect", help="Inspect one language across catalog and worker layers.")
    languages_inspect.add_argument("language", nargs="?")
    languages_inspect.set_defaults(func=cmd_languages_inspect)

    run = subparsers.add_parser("run", help="Execute a capability through the coordinator.")
    run.add_argument("capability")
    run.add_argument("--language", help="Preferred exact language.")
    run.add_argument("--input", required=True, help="JSON input file path.")
    run.add_argument("--cancel-after-ms", type=int, default=0, help="Cancel the job after the given delay in milliseconds.")
    run.set_defaults(func=cmd_run)
    run_explain = subparsers.add_parser("run-explain", help="Explain which workers can satisfy a capability before running it.")
    run_explain.add_argument("capability")
    run_explain.add_argument("--language")
    run_explain.add_argument("--input")
    run_explain.set_defaults(func=cmd_run_explain)

    pipeline = subparsers.add_parser("pipeline", help="List, inspect, and run pipelines.")
    pipeline_sub = pipeline.add_subparsers(dest="pipeline_command", required=True)
    pipeline_list = pipeline_sub.add_parser("list", help="List known pipeline files.")
    pipeline_list.set_defaults(func=cmd_pipeline_list)
    pipeline_inspect = pipeline_sub.add_parser("inspect", help="Inspect one pipeline file.")
    pipeline_inspect.add_argument("pipeline")
    pipeline_inspect.set_defaults(func=cmd_pipeline_inspect)
    pipeline_run = pipeline_sub.add_parser("run", help="Run a pipeline against an input file.")
    pipeline_run.add_argument("pipeline")
    pipeline_run.add_argument("--input", required=True)
    pipeline_run.set_defaults(func=cmd_pipeline)

    toolchains = subparsers.add_parser("toolchains", help="Inspect host runtime/toolchain availability.")
    toolchains_sub = toolchains.add_subparsers(dest="toolchain_command", required=True)
    toolchains_list = toolchains_sub.add_parser("list", help="List toolchain detection commands.")
    toolchains_list.set_defaults(func=cmd_toolchains_list)
    toolchains_detect = toolchains_sub.add_parser("detect", help="Run full toolchain detection across the manifest.")
    toolchains_detect.set_defaults(func=cmd_toolchains_detect)
    toolchains_doctor = toolchains_sub.add_parser("doctor", help="Summarize toolchain availability and failure reasons.")
    toolchains_doctor.set_defaults(func=cmd_toolchains_doctor)

    examples = subparsers.add_parser("examples", help="List worker example files available in the repository.")
    examples.set_defaults(func=cmd_examples)

    select = subparsers.add_parser("select", help="Persist an active language or worker selection.")
    select_sub = select.add_subparsers(dest="select_command", required=True)
    select_language = select_sub.add_parser("language", help="Select an active language for future commands.")
    select_language.add_argument("language")
    select_language.set_defaults(func=cmd_select_language)
    select_worker = select_sub.add_parser("worker", help="Select an active worker for future commands.")
    select_worker.add_argument("worker_id")
    select_worker.set_defaults(func=cmd_select_worker)

    context = subparsers.add_parser("context", help="Inspect or clear the active CLI context.")
    context_sub = context.add_subparsers(dest="context_command", required=True)
    context_status = context_sub.add_parser("status", help="Show the active selected language/worker.")
    context_status.set_defaults(func=cmd_context_status)
    context_clear = context_sub.add_parser("clear", help="Clear any active selected language/worker.")
    context_clear.set_defaults(func=cmd_context_clear)

    cleanup = subparsers.add_parser("cleanup", help="Clear safe caches, stale release artifacts, and orphaned helper processes.")
    cleanup.add_argument("--dry-run", action="store_true", help="Report what would be removed without changing anything.")
    cleanup.add_argument("--skip-processes", action="store_true", help="Do not stop orphaned go/coordinator helper processes.")
    cleanup.set_defaults(func=cmd_cleanup)

    help_topics = subparsers.add_parser("help-topics", help="Show curated command examples and CLI guidance.")
    help_topics.set_defaults(func=cmd_help_topics)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    sys.exit(main())
