# Support Matrix

Current honest status:

| Language | Role | Capability | Level |
| --- | --- | --- | --- |
| Python | worker | `data.csv-transform` | Tier 3 |
| Ruby | worker | `rules.evaluate` | Tier 3 |
| JavaScript | worker | `data.validate` | Tier 3 |
| Go | coordinator and worker | `statistics.summary` | Tier 3 |
| Rust | worker | `system.compress` | Tier 3 |
| Java | worker | `text.word-count` | Tier 3 |
| C | worker | `system.file-hash` | Tier 3 |
| C++ | worker | `algorithm.sort` | Tier 3 |
| C# | worker | `system.process-info` | Tier 3 |
| F# | worker | `math.statistics` | Tier 3 |
| VB | worker | `text.reverse` | Tier 3 |
| PowerShell | worker | `system.environment` | Tier 3 |
| Awk | worker | `text.tokenize` | Tier 3 |
| Bash | worker | `text.uppercase` | Tier 3 |
| Perl | worker | `text.regex` | Tier 3 |
| TypeScript | worker | `text.slugify` | Tier 3 |
| sh | worker | `text.lowercase` | Tier 3 |
| Lua | worker | `text.template` | Tier 3 |
| Racket | worker | `data.aggregate` | Tier 3 |
| Erlang | worker | `system.ping` | Tier 3 |
| Prolog | worker | `rules.classify` | Tier 3 |
| Nim | worker | `text.palindrome` | Tier 3 |
| Julia | worker | `math.vector-sum` | Tier 3 |
| Groovy | worker | `text.camel-case` | Tier 3 |
| R | worker | `math.median` | Tier 3 |
| Tcl | worker | `text.trim` | Tier 3 |
| D | worker | `math.range` | Tier 3 |
| Pascal | worker | `math.product` | Tier 3 |
| Raku | worker | `text.title-case` | Tier 3 |
| SBCL | worker | `text.word-count-lisp` | Tier 3 |
| Scheme | worker | `math.product-scheme` | Tier 3 |
| Janet | worker | `text.lower-janet` | Tier 3 |
| Arturo | worker | `text.lower-arturo` | Tier 3 |
| FreeBASIC | worker | `math.sum` | Tier 3 |
| Forth | worker | `math.max` | Tier 3 |
| Elvish | worker | `text.length-elvish` | Tier 3 |
| Clojure (Babashka) | worker | `data.frequencies` | Tier 3 |
| Dart | worker | `data.json-parse` | Tier 3 |
| Nushell | worker | `text.reverse-nu` | Tier 3 |
| Octave | worker | `math.mean` | Tier 3 |
| Zig | worker | `algorithm.prime-search` | Tier 3 |
| Batch | worker | `text.length` | Tier 3 |
| CMake | worker | `text.replace-cmake` | Tier 3 |
| findstr | worker | `text.search-findstr` | Tier 3 |
| Brainfuck | worker via embedded interpreter | `esolang.brainfuck-run` | Tier 3 |
| Git | tool-backed worker | `repo.file-list` | Tier 3 |
| jq | tool-backed worker | `data.json-query` | Tier 3 |
| Protobuf | tool-backed worker | `dev.proto-descriptor` | Tier 3 |
| Dockerfile | worker | `container.language-packs` | Tier 3 |
| Scala CLI | worker | `text.lines-scala` | Tier 3 |
| Scala | worker | `text.lengths-scala` | Tier 3 |
| Scryer Prolog | worker | `math.max-scryer` | Tier 3 |
| Cabal | tool-backed worker | `dev.haskell-tooling` | Tier 3 |
| Make | tool-backed worker | `dev.make-targets` | Tier 3 |
| Stack | tool-backed worker | `dev.haskell-stack` | Tier 3 |
| opam | tool-backed worker | `dev.ocaml-tooling` | Tier 3 |
| CLPM | tool-backed worker | `dev.common-lisp-tooling` | Tier 3 |
| fpm | tool-backed worker | `dev.fortran-tooling` | Tier 3 |
| WebFortran | tool-backed worker | `dev.webfortran-status` | Tier 3 |
| Omniforge Bot | worker | `bot.language-plan` | Tier 3 |
| Haskell | container-backed worker | `text.length-hs` | Tier 2 |
| OCaml | container-backed worker | `math.sum-ocaml` | Tier 2 |
| Elixir | container-backed worker | `text.uppercase-ex` | Tier 2 |
| Crystal | worker | `text.length-cr` | Tier 3 |
| Gleam | runtime detected with runnable example project, but the OFP worker is still blocked | not counted operational | Tier 1 |
| Elvish shim | workspace-local shim is used to bypass WinGet execution restrictions | counted operational via wrapper | Tier 3 |

Languages are not counted as supported unless they have a working Omniforge execution path.
