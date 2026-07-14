import json
import os
import subprocess
import unittest
from pathlib import Path
import tempfile


ROOT = Path(__file__).resolve().parents[1]


class OmniforgeTests(unittest.TestCase):
    SCRIPTED_PROTOCOL_CASES = [
        ([r"C:\Users\matth\AppData\Local\Programs\Lua\bin\lua.exe", "workers/lua/worker.lua"], "lua-template-01"),
        ([r"C:\Program Files\Git\usr\bin\perl.exe", "workers/perl/worker.pl"], "perl-regex-01"),
        ([r"C:\Program Files\Git\mingw64\bin\tclsh.exe", "workers/tcl/worker.tcl"], "tcl-trim-01"),
        ([r"C:\Program Files\Rakudo\bin\raku.exe", "workers/raku/worker.raku"], "raku-title-01"),
        (["powershell", "-ExecutionPolicy", "Bypass", "-File", "workers/janet/worker.ps1"], "janet-lower-01"),
        (["powershell", "-ExecutionPolicy", "Bypass", "-File", "workers/arturo/worker.ps1"], "arturo-lower-01"),
    ]

    VERIFIED_CASES = [
        ("text.word-count", "java", ".cache/job-java.json", "java"),
        ("system.file-hash", "c", ".cache/job-c.json", "c"),
        ("algorithm.sort", "cpp", ".cache/job-cpp.json", "cpp"),
        ("system.process-info", "csharp", ".cache/job-csharp.json", "csharp"),
        ("math.statistics", "fsharp", ".cache/job-fsharp.json", "fsharp"),
        ("text.reverse", "vb", ".cache/job-vb.json", "vb"),
        ("system.environment", "powershell", ".cache/job-powershell.json", "powershell"),
        ("text.tokenize", "awk", ".cache/job-awk.json", "awk"),
        ("text.uppercase", "bash", ".cache/job-bash.json", "bash"),
        ("text.regex", "perl", ".cache/job-perl.json", "perl"),
        ("text.slugify", "typescript", ".cache/job-ts.json", "typescript"),
        ("text.lowercase", "sh", ".cache/job-sh.json", "sh"),
        ("text.template", "lua", ".cache/job-lua.json", "lua"),
        ("data.aggregate", "racket", ".cache/job-racket.json", "racket"),
        ("system.ping", "erlang", ".cache/job-erlang.json", "erlang"),
        ("rules.classify", "prolog", ".cache/job-prolog.json", "prolog"),
        ("text.palindrome", "nim", ".cache/job-nim.json", "nim"),
        ("math.vector-sum", "julia", ".cache/job-julia.json", "julia"),
        ("text.camel-case", "groovy", ".cache/job-groovy.json", "groovy"),
        ("math.median", "r", ".cache/job-r.json", "r"),
        ("text.trim", "tcl", ".cache/job-tcl.json", "tcl"),
        ("math.range", "d", ".cache/job-d.json", "d"),
        ("math.product", "pascal", ".cache/job-pascal.json", "pascal"),
        ("text.title-case", "raku", ".cache/job-raku.json", "raku"),
        ("text.word-count-lisp", "sbcl", ".cache/job-sbcl.json", "sbcl"),
        ("math.product-scheme", "scheme", ".cache/job-scheme.json", "scheme"),
        ("text.lower-janet", "janet", ".cache/job-janet.json", "janet"),
        ("text.lower-arturo", "arturo", ".cache/job-arturo.json", "arturo"),
        ("math.sum", "freebasic", ".cache/job-freebasic.json", "freebasic"),
        ("math.max", "forth", ".cache/job-forth.json", "forth"),
        ("text.length-elvish", "elvish", ".cache/job-elvish.json", "elvish"),
        ("data.frequencies", "clojure", ".cache/job-clojure.json", "clojure"),
        ("data.json-parse", "dart", ".cache/job-dart.json", "dart"),
        ("text.reverse-nu", "nushell", ".cache/job-nushell.json", "nushell"),
        ("math.mean", "octave", ".cache/job-octave.json", "octave"),
        ("algorithm.prime-search", "zig", ".cache/job-zig.json", "zig"),
        ("repo.file-list", "git", ".cache/job-git-files.json", "git"),
        ("repo.status", "git", ".cache/job-git-status.json", "git"),
        ("text.length", "batch", ".cache/job-batch.json", "batch"),
        ("text.replace-cmake", "cmake", ".cache/job-cmake.json", "cmake"),
        ("text.search-findstr", "findstr", ".cache/job-findstr.json", "findstr"),
        ("esolang.brainfuck-run", "brainfuck", ".cache/job-brainfuck.json", "brainfuck"),
        ("data.json-query", "jq", ".cache/job-jq.json", "jq"),
        ("dev.proto-descriptor", "protobuf", ".cache/job-protobuf.json", "protobuf"),
        ("container.language-packs", "dockerfile", ".cache/job-dockerfile.json", "dockerfile"),
        ("text.lines-scala", "scalacli", ".cache/job-scalacli.json", "scalacli"),
        ("text.lengths-scala", "scala", ".cache/job-scala.json", "scala"),
        ("math.max-scryer", "scryer-prolog", ".cache/job-scryer.json", "scryer-prolog"),
        ("text.length-cr", "crystal", ".cache/job-crystal.json", "crystal"),
        ("dev.haskell-tooling", "cabal", ".cache/job-cabal.json", "cabal"),
        ("dev.make-targets", "make", ".cache/job-make.json", "make"),
        ("dev.haskell-stack", "stack", ".cache/job-stack.json", "stack"),
        ("dev.ocaml-tooling", "opam", ".cache/job-opam.json", "opam"),
        ("dev.common-lisp-tooling", "clpm", ".cache/job-clpm.json", "clpm"),
        ("dev.fortran-tooling", "fpm", ".cache/job-fpm.json", "fpm"),
        ("dev.webfortran-status", "webfortran", ".cache/job-webfortran.json", "webfortran"),
        ("bot.language-plan", "omniforge-bot", "workers/specialist-bot/examples/language-plan.json", "omniforge-bot"),
    ]

    def run_cli(self, *args):
        completed = subprocess.run(
            ["python", "omniforge.py", *args],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, msg=completed.stderr)
        return json.loads(completed.stdout)

    def test_workers_list(self):
        payload = self.run_cli("workers")
        languages = {entry["language"] for entry in payload}
        self.assertIn("python", languages)
        self.assertIn("rust", languages)
        self.assertIn("java", languages)
        self.assertIn("csharp", languages)
        self.assertIn("typescript", languages)
        self.assertIn("perl", languages)
        self.assertIn("git", languages)
        self.assertIn("batch", languages)
        self.assertIn("cmake", languages)
        self.assertIn("findstr", languages)
        self.assertIn("jq", languages)
        self.assertIn("protobuf", languages)

    def test_cleanup_dry_run(self):
        payload = self.run_cli("cleanup", "--dry-run", "--skip-processes")
        self.assertEqual(payload["mode"], "dry-run")
        self.assertTrue(payload["wouldClearCliState"])
        self.assertIn("dist/omniforge-cli-latest.zip", payload["kept"])
        self.assertTrue(any(item["path"].endswith(".cache\\runtime-shims\\zig.exe") or item["path"].endswith(".cache/runtime-shims/zig.exe") for item in payload["targets"]) or isinstance(payload["targets"], list))

    def test_workers_inspect(self):
        payload = self.run_cli("workers", "inspect", "jq-query-01")
        self.assertEqual(payload["language"], "jq")
        self.assertEqual(payload["workerId"], "jq-query-01")
        self.assertIn("manifestPath", payload)

    def test_capabilities_search(self):
        payload = self.run_cli("capabilities", "search", "proto")
        self.assertTrue(any(entry["language"] == "protobuf" for entry in payload))

    def test_languages_inspect(self):
        payload = self.run_cli("languages", "inspect", "python")
        self.assertEqual(payload["language"], "python")
        self.assertTrue(any(worker["id"] == "python-data-01" for worker in payload["workers"]))

    def test_languages_doctor_reports_catalog_drift(self):
        payload = self.run_cli("languages", "doctor")
        self.assertGreater(payload["issueCount"], 0)
        self.assertTrue(any(issue["language"] == "haskell" for issue in payload["issues"]))

    def test_promoted_language_states(self):
        haskell = self.run_cli("workers", "inspect", "haskell-length-01")
        ocaml = self.run_cli("workers", "inspect", "ocaml-sum-01")
        elixir = self.run_cli("workers", "inspect", "elixir-upper-01")
        gleam = self.run_cli("languages", "inspect", "gleam")

        self.assertEqual(haskell["tier"], "tier-2")
        self.assertEqual(ocaml["tier"], "tier-2")
        self.assertEqual(elixir["tier"], "tier-2")
        self.assertEqual(gleam["catalog"]["supportTier"], "tier-1")

    def test_gleam_example_runner(self):
        env = dict(os.environ)
        env["PATH"] = r"C:\Program Files\Erlang OTP\bin;" + env.get("PATH", "")
        completed = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "languages/gleam/toolchain/run-example.ps1",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, msg=completed.stderr)
        self.assertIn("Hello from Gleam", completed.stdout)

    def test_pipeline_inspect(self):
        payload = self.run_cli("pipeline", "inspect", "pipelines/data-intelligence.json")
        self.assertEqual(payload["name"], "data-intelligence")
        self.assertEqual(payload["stepCount"], 5)

    def test_pipeline(self):
        payload = self.run_cli(
            "pipeline",
            "run",
            "pipelines/data-intelligence.yaml",
            "--input",
            "examples/data/customers.csv",
        )
        self.assertEqual(payload["name"], "data-intelligence")
        self.assertEqual(len(payload["steps"]), 5)
        self.assertEqual(payload["steps"][0]["language"], "python")
        self.assertEqual(payload["steps"][-1]["language"], "rust")

    def test_additional_workers(self):
        for capability, language, input_path, expected_language in self.VERIFIED_CASES:
            payload = self.run_cli("run", capability, "--language", language, "--input", input_path)
            self.assertEqual(payload["language"], expected_language)

    def test_specialist_bot_execution_options(self):
        payload = self.run_cli(
            "run",
            "bot.execution-options",
            "--language",
            "omniforge-bot",
            "--input",
            "workers/specialist-bot/examples/execution-options.json",
        )
        self.assertEqual(payload["language"], "omniforge-bot")
        self.assertEqual(payload["output"]["assignedLanguage"], "python")
        self.assertTrue(any(item["capability"] == "data.csv-transform" for item in payload["output"]["recommendedActions"]))

    def test_python_worker_protocol_messages(self):
        worker = subprocess.Popen(
            ["python", "workers/python/worker.py"],
            cwd=ROOT,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
        )
        try:
            worker.stdin.write('{"type":"HELLO","protocol":"ofp/1","messageId":"hello-1"}\n')
            worker.stdin.flush()
            welcome = json.loads(worker.stdout.readline())
            register = json.loads(worker.stdout.readline())
            self.assertEqual(welcome["type"], "WELCOME")
            self.assertEqual(register["type"], "REGISTER")

            worker.stdin.write('{"type":"REGISTER_ACK","protocol":"ofp/1","status":"accepted"}\n')
            worker.stdin.write('{"type":"SHUTDOWN","protocol":"ofp/1"}\n')
            worker.stdin.flush()
            shutdown_ack = json.loads(worker.stdout.readline())
            self.assertEqual(shutdown_ack["type"], "SHUTDOWN_ACK")
        finally:
            if worker.stdin:
                worker.stdin.close()
            if worker.stdout:
                worker.stdout.close()
            worker.wait(timeout=5)

    def test_scripted_workers_protocol_messages(self):
        for command, worker_id in self.SCRIPTED_PROTOCOL_CASES:
            with self.subTest(worker_id=worker_id):
                worker = subprocess.Popen(
                    command,
                    cwd=ROOT,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    text=True,
                )
                try:
                    worker.stdin.write('{"type":"HELLO","protocol":"ofp/1","messageId":"hello-1"}\n')
                    worker.stdin.flush()
                    welcome = json.loads(worker.stdout.readline())
                    register = json.loads(worker.stdout.readline())
                    self.assertEqual(welcome["type"], "WELCOME")
                    self.assertEqual(register["type"], "REGISTER")
                    self.assertEqual(register["workerId"], worker_id)

                    worker.stdin.write('{"type":"REGISTER_ACK","protocol":"ofp/1","status":"accepted"}\n')
                    worker.stdin.write('{"type":"JOB_CANCEL","protocol":"ofp/1","jobId":"job-cancel-1"}\n')
                    worker.stdin.flush()
                    cancelled = json.loads(worker.stdout.readline())
                    self.assertEqual(cancelled["type"], "JOB_CANCELLED")

                    worker.stdin.write('{"type":"SHUTDOWN","protocol":"ofp/1"}\n')
                    worker.stdin.flush()
                    shutdown_ack = json.loads(worker.stdout.readline())
                    self.assertEqual(shutdown_ack["type"], "SHUTDOWN_ACK")
                finally:
                    if worker.stdin:
                        worker.stdin.close()
                    if worker.stdout:
                        worker.stdout.close()
                    worker.wait(timeout=5)

    def test_python_worker_job_cancel(self):
        with tempfile.NamedTemporaryFile("w", delete=False, suffix=".json", dir=ROOT / ".cache") as handle:
            json.dump({"inputPath": "examples/data/customers.csv", "simulateDelayMs": 300}, handle)
            temp_path = Path(handle.name)
        try:
            completed = subprocess.run(
                [
                    "python",
                    "omniforge.py",
                    "run",
                    "data.csv-transform",
                    "--language",
                    "python",
                    "--input",
                    str(temp_path),
                    "--cancel-after-ms",
                    "25",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("job cancelled", completed.stderr.lower())
        finally:
            temp_path.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
