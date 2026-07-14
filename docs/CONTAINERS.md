# Container Packs

Omniforge now includes a `docker compose` layout for language packs that are awkward or noisy to install on the host.

## Packs

- `omniforge-systems`: C/C++, Go, Rust, Node.js, Ruby, Lua, Java, protobuf, jq, CMake
- `omniforge-functional`: Haskell, OCaml, Elixir, Erlang, SBCL, Racket, SWI-Prolog
- `omniforge-scientific`: Octave, R, Fortran-oriented tooling
- `omniforge-full`: combined native-friendly development image

## Typical commands

```bash
docker compose --profile functional build omniforge-functional
docker compose --profile functional run --rm omniforge-functional bash
docker compose --profile full run --rm omniforge-full python3 omniforge.py workers list
docker compose --profile functional run --rm omniforge-functional bash containers/smoke-functional.sh
python omniforge.py languages doctor
python omniforge.py cleanup --dry-run
```

## Why this helps

The current coordinator is still local-first and process-based. Running the CLI inside a pack container lets the coordinator spawn workers from the toolchains already installed in that image, which unlocks extra OFP languages without polluting the host machine.

## Container-ready workers added in this phase

- `workers/haskell`: `text.length-hs`
- `workers/ocaml`: `math.sum-ocaml`
- `workers/elixir`: `text.uppercase-ex`

These now count as container-backed Tier 2 workers because they have a concrete execution path through `omniforge-functional`, even when the host machine does not have those runtimes on PATH. They still depend on a running Docker daemon.

## Local hygiene

The repo generates local caches in `.cache/` for Go builds, worker inputs, pipeline scratch files, and workspace-local shims. Those are ignored by git and can be pruned with:

```bash
python omniforge.py cleanup
```

Use the audit command below before large metadata cleanup passes:

```bash
python omniforge.py languages doctor
```
