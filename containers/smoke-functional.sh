#!/usr/bin/env bash
set -euo pipefail

python3 apps/cli/omniforge.py run text.length-hs --language haskell --input .cache/job-haskell.json
python3 apps/cli/omniforge.py run math.sum-ocaml --language ocaml --input .cache/job-ocaml.json
python3 apps/cli/omniforge.py run text.uppercase-ex --language elixir --input .cache/job-elixir.json
