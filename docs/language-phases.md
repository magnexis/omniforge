# Language Phases

Omniforge is expanding language support in phases so the repository can stay honest:

1. install runtimes that are actually obtainable on this machine
2. implement real OFP workers for those runtimes
3. test them through the coordinator
4. only then count them as supported

## Phase 0

Already operational workers include:

- `python`
- `ruby`
- `javascript`
- `typescript`
- `go`
- `rust`
- `c`
- `cpp`
- `csharp`
- `fsharp`
- `vb`
- `powershell`
- `awk`
- `bash`
- `sh`
- `perl`
- `lua`
- `racket`
- `erlang`
- `prolog`
- `nim`
- `julia`
- `groovy`
- `r`
- `tcl`
- `freebasic`
- `forth`
- `elvish`

Installed but not yet operationally counted:

- `scala`
- `crystal`
- `gleam`
- `nushell`
- `dart`
- `zig`
- `octave`

Newly promoted from this phase:

- `d`
- `pascal`
- `raku`
- `sbcl`
- `freebasic`
- `forth`
- `elvish`

## Phase 1

Priority install-and-integrate targets from the large requested backlog:

- `octave`
- `freebasic`
- `cobol` if a workable Windows toolchain is found
- `gnu cobol` if a workable Windows toolchain is found
- `objective-c` only if a practical host or container path is added
- `fortran` only if a practical host or container path is added

## Admission Rule

A language is only promoted from backlog to supported when it has:

- a detected runtime or compiler
- a worker manifest
- a real OFP worker implementation
- a verified coordinator execution path
- automated test coverage

## Notes

- Large historical language lists are tracked as backlog input, not support claims.
- Aliases, standards, versions, and dialect names should be deduplicated before they are counted.
- Proprietary or OS-specific languages may require containers, emulators, or separate host environments.
