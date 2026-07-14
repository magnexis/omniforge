# Omniforge

*One system. Every language. One universal execution fabric.*

Omniforge is a local-first distributed execution fabric. Jobs are routed to independently executable language workers that speak a shared protocol called OFP, the Omniforge Protocol. The project is no longer a collection of disconnected examples. It is a cooperating runtime where different languages perform real work inside one larger system.

The repository now also carries a broader catalog layer in `languages/`, where each tracked language directory has concrete metadata, a toolchain manifest, and example code without being falsely counted as an operational worker.

Omniforge is also being upgraded into a polyglot autonomous reliability platform while keeping the Omniforge name. The goal is a self-healing software runtime built out of specialized language workers rather than a rebrand into a different product identity.

Omniforge is also intentionally presented as a rainbow repository: a visibly broad, multi-language codebase where the language surface is part of the identity rather than hidden in the background.

## CLI Release

The CLI is the single public entry point for the repository:

```bash
python omniforge.py help-topics
```

Build a release artifact with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build-cli-release.ps1
```

Artifacts are written to `dist/`:

- `dist/omniforge-cli-latest.zip`
- `dist/omniforge-cli-dev-<timestamp>.zip`

Generated caches, workspace-local shims, temporary job inputs, and release staging output are intentionally local-only and ignored through `.gitignore`.

## Maintenance Commands

Audit language catalog drift against the actual worker/runtime state:

```bash
python omniforge.py languages doctor
```

Clear safe local clutter on demand:

```bash
python omniforge.py cleanup
python omniforge.py cleanup --dry-run
```

`cleanup` clears CLI state, stale release artifacts, safe cache paths, and orphaned repo helper processes. It preserves current source files, runtime shim directories, and `dist/omniforge-cli-latest.zip`.

## Language Badges

<p align="center">
  <img alt="Operational Languages" src="https://img.shields.io/badge/operational_languages-57-E40303">
  <img alt="Catalogued Language Dirs" src="https://img.shields.io/badge/catalogued_language_dirs-71-FF8C00">
  <img alt="OFP Commands" src="https://img.shields.io/badge/ofp_commands-31-FFED00&labelColor=111111">
  <img alt="Container Ready" src="https://img.shields.io/badge/container_ready-3-008026">
  <img alt="Blocked Or Partial" src="https://img.shields.io/badge/blocked_or_partial-0-004DFF">
  <img alt="Protocol" src="https://img.shields.io/badge/OFP-ofp%2F1-750787">
</p>

Badge layout for validated OFP workers:

<p>
  <img alt="Python" src="https://img.shields.io/badge/python-Tier%203-E40303?logo=python&logoColor=white">
  <img alt="Ruby" src="https://img.shields.io/badge/ruby-Tier%203-FF5E00?logo=ruby&logoColor=white">
  <img alt="JavaScript" src="https://img.shields.io/badge/javascript-Tier%203-FFB000?logo=javascript&logoColor=111111">
  <img alt="Java" src="https://img.shields.io/badge/java-Tier%203-FFD400?logo=openjdk&logoColor=111111">
  <img alt="Go" src="https://img.shields.io/badge/go-Tier%203-B8E000?logo=go&logoColor=111111">
  <img alt="Rust" src="https://img.shields.io/badge/rust-Tier%203-5BCB00?logo=rust&logoColor=111111">
  <img alt="C" src="https://img.shields.io/badge/c-Tier%203-00A651?logo=c&logoColor=white">
  <img alt="C++" src="https://img.shields.io/badge/c%2B%2B-Tier%203-00B894?logo=cplusplus&logoColor=white">
  <img alt="C#" src="https://img.shields.io/badge/c%23-Tier%203-00B7C3?logo=csharp&logoColor=white">
  <img alt="F#" src="https://img.shields.io/badge/f%23-Tier%203-00AEEF?logo=fsharp&logoColor=white">
</p>

<p>
  <img alt="VB" src="https://img.shields.io/badge/visual%20basic-Tier%203-0095FF?logo=visualbasic&logoColor=white">
  <img alt="PowerShell" src="https://img.shields.io/badge/powershell-Tier%203-1D6CF2?logo=powershell&logoColor=white">
  <img alt="TypeScript" src="https://img.shields.io/badge/typescript-Tier%203-3D5AFE?logo=typescript&logoColor=white">
  <img alt="Lua" src="https://img.shields.io/badge/lua-Tier%203-5B3FD6?logo=lua&logoColor=white">
  <img alt="Racket" src="https://img.shields.io/badge/racket-Tier%203-7B2CBF?logo=racket&logoColor=white">
  <img alt="Erlang" src="https://img.shields.io/badge/erlang-Tier%203-8E24AA?logo=erlang&logoColor=white">
  <img alt="Prolog" src="https://img.shields.io/badge/prolog-Tier%203-A100C8">
  <img alt="Julia" src="https://img.shields.io/badge/julia-Tier%203-B5179E?logo=julia&logoColor=white">
  <img alt="Groovy" src="https://img.shields.io/badge/groovy-Tier%203-C2185B?logo=apachegroovy&logoColor=white">
  <img alt="R" src="https://img.shields.io/badge/r-Tier%203-D81B60?logo=r&logoColor=white">
</p>

<p>
  <img alt="Tcl" src="https://img.shields.io/badge/tcl-Tier%203-E40303">
  <img alt="D" src="https://img.shields.io/badge/d-Tier%203-F4511E?logo=d&logoColor=white">
  <img alt="Pascal" src="https://img.shields.io/badge/pascal-Tier%203-F57C00">
  <img alt="Raku" src="https://img.shields.io/badge/raku-Tier%203-FFB300?logo=raku&logoColor=111111">
  <img alt="SBCL" src="https://img.shields.io/badge/sbcl-Tier%203-C0CA33">
  <img alt="Scheme" src="https://img.shields.io/badge/scheme-Tier%203-7CB342">
  <img alt="Janet" src="https://img.shields.io/badge/janet-Tier%203-43A047">
  <img alt="Arturo" src="https://img.shields.io/badge/arturo-Tier%203-009688">
  <img alt="FreeBASIC" src="https://img.shields.io/badge/freebasic-Tier%203-00ACC1">
  <img alt="Forth" src="https://img.shields.io/badge/forth-Tier%203-039BE5">
</p>

<p>
  <img alt="Elvish" src="https://img.shields.io/badge/elvish-Tier%203-1E88E5">
  <img alt="Clojure" src="https://img.shields.io/badge/clojure-Tier%203-3949AB?logo=clojure&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/dart-Tier%203-5E35B1?logo=dart&logoColor=white">
  <img alt="Nushell" src="https://img.shields.io/badge/nushell-Tier%203-7E57C2?logo=nushell&logoColor=white">
  <img alt="Octave" src="https://img.shields.io/badge/octave-Tier%203-8E24AA?logo=gnuoctave&logoColor=white">
  <img alt="Zig" src="https://img.shields.io/badge/zig-Tier%203-AD1457?logo=zig&logoColor=white">
  <img alt="Batch" src="https://img.shields.io/badge/batch-Tier%203-C62828">
  <img alt="CMake" src="https://img.shields.io/badge/cmake-Tier%203-E64A19?logo=cmake&logoColor=white">
  <img alt="findstr" src="https://img.shields.io/badge/findstr-Tier%203-F9A825">
  <img alt="Brainfuck" src="https://img.shields.io/badge/brainfuck-Tier%203-FDD835">
</p>

<p>
  <img alt="Git" src="https://img.shields.io/badge/git-Tier%203-9CCC65?logo=git&logoColor=111111">
  <img alt="jq" src="https://img.shields.io/badge/jq-Tier%203-4CAF50?logo=jq&logoColor=white">
  <img alt="Protobuf" src="https://img.shields.io/badge/protobuf-Tier%203-26A69A?logo=protobuf&logoColor=white">
  <img alt="Dockerfile" src="https://img.shields.io/badge/dockerfile-Tier%203-00ACC1?logo=docker&logoColor=white">
  <img alt="Scala CLI" src="https://img.shields.io/badge/scala%20cli-Tier%203-1E88E5?logo=scala&logoColor=white">
  <img alt="Scala" src="https://img.shields.io/badge/scala-Tier%203-3949AB?logo=scala&logoColor=white">
  <img alt="Scryer Prolog" src="https://img.shields.io/badge/scryer%20prolog-Tier%203-5E35B1">
  <img alt="Crystal" src="https://img.shields.io/badge/crystal-Tier%203-7E57C2?logo=crystal&logoColor=white">
  <img alt="Cabal" src="https://img.shields.io/badge/cabal-Tier%203-8E24AA?logo=cabal&logoColor=white">
  <img alt="Make" src="https://img.shields.io/badge/make-Tier%203-AD1457">
</p>

<p>
  <img alt="Stack" src="https://img.shields.io/badge/stack-Tier%203-C62828">
  <img alt="opam" src="https://img.shields.io/badge/opam-Tier%203-E64A19?logo=ocaml&logoColor=white">
  <img alt="CLPM" src="https://img.shields.io/badge/clpm-Tier%203-F57C00">
  <img alt="fpm" src="https://img.shields.io/badge/fpm-Tier%203-FBC02D">
  <img alt="WebFortran" src="https://img.shields.io/badge/webfortran-Tier%203-8BC34A">
  <img alt="Omniforge Bot" src="https://img.shields.io/badge/omniforge%20bot-Tier%203-26A69A">
  <img alt="Awk" src="https://img.shields.io/badge/awk-Tier%203-00ACC1">
  <img alt="Bash" src="https://img.shields.io/badge/bash-Tier%203-039BE5?logo=gnubash&logoColor=white">
  <img alt="Perl" src="https://img.shields.io/badge/perl-Tier%203-3949AB?logo=perl&logoColor=white">
  <img alt="sh" src="https://img.shields.io/badge/sh-Tier%203-6A1B9A">
</p>

Container-ready workers:

<p>
  <img alt="Haskell" src="https://img.shields.io/badge/haskell-Tier%202-5D4F85?logo=haskell&logoColor=white">
  <img alt="OCaml" src="https://img.shields.io/badge/ocaml-Tier%202-EC6813?logo=ocaml&logoColor=white">
  <img alt="Elixir" src="https://img.shields.io/badge/elixir-Tier%202-4B275F?logo=elixir&logoColor=white">
</p>

Still blocked:

<p>
  <img alt="Gleam" src="https://img.shields.io/badge/gleam-Tier%201-FFAFF3?logo=gleam&logoColor=111111">
</p>


## What Omniforge Is

Omniforge accepts jobs such as parsing data, applying rules, validating records, computing statistics, or producing artifacts. A coordinator resolves the requested capability, selects a worker based on language and capability metadata, dispatches the job, and collects structured results.

The next product direction is incident-driven:

- observe applications, repositories, services, and infrastructure
- classify incidents
- route investigations to specialized workers
- produce structured repair plans
- verify repairs
- store incident learnings for future routing and evaluation

Current implemented vertical slice:

- `apps/coordinator/`: Go coordinator, registry, scheduler, and pipeline runner
- `apps/cli/`: Python CLI that wraps the coordinator and provides local UX
- `protocol/`: OFP schemas, fixtures, and specification
- `workers/`: independently executable workers in multiple languages
- `pipelines/`: cross-language pipeline definitions
- `tests/`: end-to-end verification

## Current Working Demonstration

The first real Omniforge pipeline is `data-intelligence`.

It runs:

1. Python worker parses and cleans CSV rows
2. Ruby worker applies rule-based classifications
3. JavaScript worker validates transformed records
4. Go worker computes summary statistics
5. Rust worker compresses the final artifact

This is a real pipeline with real data flow. It does not use mocked worker responses.

## Architecture

```text
Client
  |
  v
Omniforge CLI
  |
  v
Go Coordinator
  |
  +-- Registry
  +-- Scheduler
  +-- Pipeline Runner
  +-- Worker Process Manager
  |
  v
Language Workers (stdio + OFP JSON messages)
```

## OFP

Workers communicate over newline-delimited JSON messages. OFP v1 now defines 31 message types across:

- handshake and session control
- discovery and capability negotiation
- job execution and cancellation
- artifact transfer
- health, metrics, and tracing

The protocol is versioned as `ofp/1`.

Core minimum messages still implemented broadly today:

- `HELLO`
- `REGISTER`
- `JOB_START`
- `JOB_PROGRESS`
- `JOB_RESULT`
- `JOB_ERROR`
- `SHUTDOWN`

Implemented now in the coordinator and the stable Python, Ruby, JavaScript, and Go worker slice:

- `WELCOME`
- `REGISTER_ACK`
- `JOB_ACCEPTED`
- `JOB_LOG`
- `JOB_CANCEL`
- `SHUTDOWN_ACK`

The CLI now exposes timed cancellation for real testing:

```bash
python omniforge.py run data.csv-transform --language python --input .cache/job-python.json --cancel-after-ms 25
```

Expanded OFP v1 messages now documented for adoption:

- `WELCOME`
- `REGISTER_ACK`
- `CAPABILITIES`
- `CAPABILITY_QUERY`
- `CAPABILITY_RESPONSE`
- `PING`
- `PONG`
- `HEARTBEAT`
- `HEALTH_REPORT`
- `WORKER_STATUS`
- `METRICS_SNAPSHOT`
- `JOB_ACCEPTED`
- `JOB_LOG`
- `JOB_STREAM`
- `JOB_CANCEL`
- `JOB_CANCELLED`
- `ARTIFACT_PUT`
- `ARTIFACT_GET`
- `ARTIFACT_REF`
- `ARTIFACT_CHUNK`
- `ARTIFACT_COMPLETE`
- `TRACE_START`
- `TRACE_STOP`
- `SHUTDOWN_ACK`

## Specialist Bots

Omniforge now includes worker-connected specialist bots. These are ordinary OFP workers that inherit a language assignment from either:

- an explicit `assignedLanguage`
- or a `delegateWorkerId` from another registered worker

They then return options for what that language does best using the local capability registry plus a language-specialty map.

Current bot capabilities:

- `bot.language-plan`
- `bot.execution-options`
- `bot.pipeline-handoff`

Example:

```bash
python omniforge.py run bot.language-plan --language omniforge-bot --input workers/specialist-bot/examples/language-plan.json
```

## Supported Workers

Current operational workers:

- Python: `data.csv-transform`
- Ruby: `rules.evaluate`
- JavaScript: `data.validate`
- Go: `statistics.summary`
- Rust: `system.compress`
- Java: `text.word-count`
- C: `system.file-hash`
- C++: `algorithm.sort`
- C#: `system.process-info`
- F#: `math.statistics`
- VB: `text.reverse`
- PowerShell: `system.environment`
- Awk: `text.tokenize`
- Bash: `text.uppercase`
- Perl: `text.regex`
- TypeScript: `text.slugify`
- sh: `text.lowercase`
- Lua: `text.template`
- Batch: `text.length`
- CMake: `text.replace-cmake`
- findstr: `text.search-findstr`

Current support levels are tracked honestly in `docs/support-matrix.md`.

Catalogued language directories and their admission boundary are tracked in `docs/language-catalog.md`.

Container packs are documented in `docs/CONTAINERS.md`. The repo now includes `docker-compose.yml` plus systems, functional, scientific, and full development images so extra OFP languages can run inside containers instead of requiring direct host installs.

Reliability-platform foundation documents now live in:

- `docs/ARCHITECTURE.md`
- `docs/WORKERS.md`
- `docs/LANGUAGE-ROLES.md`
- `docs/PROTOCOL.md`
- `docs/SAFETY.md`
- `docs/INCIDENT-LIFECYCLE.md`
- `docs/REPAIR-POLICY.md`
- `docs/THREAT-MODEL.md`
- `docs/RUNBOOKS.md`
- `docs/ROADMAP.md`

## Quick Start

```bash
python omniforge.py workers list
python omniforge.py capabilities
python omniforge.py pipeline run pipelines/data-intelligence.yaml --input examples/data/customers.csv
python omniforge.py run text.template --language lua --input examples/data/template-input.json
python omniforge.py toolchains detect
```

## First Cross-Language Pipeline

```bash
python omniforge.py pipeline run pipelines/data-intelligence.yaml --input examples/data/customers.csv
```

The final result includes:

- cleaned records
- rule classifications
- validation summary
- aggregate statistics
- compressed artifact

## Repository Layout

```text
omniforge/
├── apps/
│   ├── cli/
│   └── coordinator/
├── protocol/
│   ├── conformance/
│   ├── fixtures/
│   ├── schemas/
│   └── specifications/
├── workers/
│   ├── go/
│   ├── javascript/
│   ├── lua/
│   ├── python/
│   ├── ruby/
│   └── rust/
├── pipelines/
├── toolchains/
├── docs/
├── examples/
├── tests/
└── .github/
```

## Security Model

The current implementation is local-first and process-isolated. Workers are spawned as separate OS processes and communicate only through OFP messages over stdio. The repository documents the intended stronger isolation model in `docs/security.md`.

Current implemented safeguards:

- protocol validation at the message layer
- process boundaries between coordinator and workers
- explicit capability routing
- structured worker errors
- graceful worker shutdown

Not yet implemented in code:

- CPU and memory enforcement
- filesystem sandboxing per worker
- container isolation
- worker authentication
- network policy enforcement

Those gaps are listed clearly in the roadmap and support matrix.

## How To Add A Language

The long-term goal is broad language participation, but a language is only counted when it has a real execution path.

A worker is considered operational only when it has:

- metadata
- launch command
- OFP handshake
- at least one capability
- automated test coverage

## Roadmap

- add official SDKs for core languages
- add registry persistence and benchmark history
- add more workers from installed runtimes
- add containerized language packs
- add dashboard and job inspection UI
- add stronger sandboxing and resource limits

## Current Limits

This phase implements a functioning Omniforge core and a real cross-language pipeline. It does not yet satisfy the full 30-language target from the long-range vision. Unsupported and partially supported languages are listed honestly in `docs/support-matrix.md`.
