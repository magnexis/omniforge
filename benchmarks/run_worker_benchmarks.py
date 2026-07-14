import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "reports" / "benchmarks" / "latest.json"

CASES = [
    ("text.word-count", "java", ".cache/job-java.json"),
    ("system.file-hash", "c", ".cache/job-c.json"),
    ("algorithm.sort", "cpp", ".cache/job-cpp.json"),
    ("text.slugify", "typescript", ".cache/job-ts.json"),
    ("text.template", "lua", ".cache/job-lua.json"),
    ("text.lower-janet", "janet", ".cache/job-janet.json"),
    ("math.vector-sum", "julia", ".cache/job-julia.json"),
    ("algorithm.prime-search", "zig", ".cache/job-zig.json"),
]


def run_case(capability: str, language: str, input_path: str) -> dict:
    completed = subprocess.run(
        ["python", "apps/cli/omniforge.py", "run", capability, "--language", language, "--input", input_path],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(f"{language} {capability} failed: {completed.stderr.strip()}")
    payload = json.loads(completed.stdout)
    return {
        "capability": capability,
        "language": language,
        "workerId": payload["workerId"],
        "elapsedMs": payload["elapsedMs"],
    }


def main() -> None:
    results = [run_case(capability, language, input_path) for capability, language, input_path in CASES]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps({"results": results}, indent=2), encoding="utf-8")
    print(json.dumps({"results": results}, indent=2))


if __name__ == "__main__":
    main()
