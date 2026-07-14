# Gleam

This language is now tracked in Omniforge as a Tier 1 language entry with a runnable example, but it is still not counted as an operational OFP worker.

## Status

- Support tier: `Tier 1`
- Runtime: `gleam`
- Worker status: `tracked only`
- Admission rule: detected runtime and runnable example are present; OFP worker execution is still blocked

## Example

- [hello-world/gleam.toml](examples/hello-world/gleam.toml)
- [hello-world/src/hello_world.gleam](examples/hello-world/src/hello_world.gleam)

## Notes

Run the example with:

```powershell
powershell -ExecutionPolicy Bypass -File languages/gleam/toolchain/run-example.ps1
```

This directory exists so the language backlog is represented in-repo with concrete metadata and runnable example code instead of only being mentioned in planning documents.
