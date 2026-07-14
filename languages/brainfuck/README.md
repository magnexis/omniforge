# Brainfuck

This language is catalogued in Omniforge and also has a small operational worker backed by an embedded interpreter.

## Status

- Support tier: `Tier 3`
- Runtime: `embedded-python-interpreter`
- Worker status: `counted operational`
- Capability: `esolang.brainfuck-run`

## Example

- [hello-world/main.bf](examples/hello-world/main.bf)

## Notes

The current OFP worker executes Brainfuck programs through a minimal embedded interpreter inside the Omniforge worker process. That is counted explicitly as an embedded execution path, not as a native external Brainfuck toolchain.
