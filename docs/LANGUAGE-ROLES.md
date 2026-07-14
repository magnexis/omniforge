# Language Roles

This file adapts the “Stackmend Cortex” style role model into Omniforge without renaming the project.

| Language | Worker / Role | Responsibility | Why This Language | Toolchain | Status | Tests / Verification | Operational Risk |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Go | coordinator | routing, scheduling, process control | simple concurrency and strong binaries | `go` | implemented | CLI and pipeline runs | medium |
| Python | analysis / normalize worker | CSV cleanup, incident normalization, automation | strong glue language and data handling | `python` | implemented | worker and pipeline verification | medium |
| Ruby | rules worker | record classification | concise business-rule style transforms | `ruby` | implemented | pipeline verification | medium |
| JavaScript | validation worker | output validation | common runtime and JSON handling | `node` | implemented | pipeline verification | medium |
| Rust | systems / artifact worker | compression, packaging, future sandboxing | systems safety and deterministic binaries | `cargo` | implemented | pipeline verification | medium |
| PowerShell | automation worker | environment checks, remediation planning | native Windows operational control | `powershell` | implemented | worker verification | high |
| Prolog | policy worker | policy reasoning and incident classification | explicit rule logic | `swipl` | implemented | worker verification | medium |
| jq | JSON tool-backed worker | remediation summaries and JSON queries | deterministic JSON transforms | `jq` | implemented | direct CLI verification | low |
| Protobuf | protocol tool-backed worker | portable artifact descriptors | interoperability and schema packaging | `protoc` | implemented | direct CLI verification | low |
| Java | service / build support worker | JVM-side analysis and text tasks | enterprise ecosystem coverage | `javac` | implemented | worker verification | medium |
| C | systems worker | low-level file and hash tasks | direct systems primitives | `clang` | implemented | worker verification | medium |
| C++ | systems worker | algorithm and compute tasks | native performance and tooling parity | `clang++` | implemented | worker verification | medium |
| C# | service / windows worker | process info and .NET integration | strong Windows and service tooling | `dotnet` | implemented | worker verification | medium |
| F# | policy / analysis support | typed stats and validation logic | functional constraints on .NET | `dotnet` | implemented | worker verification | low |
| Bash / sh / Awk / Perl | automation workers | shell repair and text diagnostics | deterministic system automation | Git shell tools | implemented | worker verification | medium |
| Lua | embedded scripting worker | templating and lightweight task logic | embeddable scripting | `lua` | implemented | worker verification | low |
| Julia / R | analysis workers | numerical and statistical investigation | strong technical computing | `julia`, `Rscript` | partially operational | targeted worker runs | medium |
| Erlang / Elixir / Nushell / Elvish | supervision / automation candidates | supervision, shell orchestration | concurrency or shell UX strengths | runtime-specific | mixed | host-specific verification | medium |
| Nim / D / Pascal / Forth / FreeBASIC / Raku / SBCL | compatibility and experimental operational workers | small specialized tasks | broader real runtime coverage | host-specific | implemented or near-operational | targeted worker verification | medium |
| Crystal / Scala / Gleam / Zig / Octave | experimental or unstable here | useful future worker families | real strengths, but current host/runtime issues remain | host-specific | not honestly promoted | limited | high |

## Rule

No language is counted as supported merely because a source file exists.
