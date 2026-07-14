# Mega Expansion Review

This document captures the large attachment titled `MEGA-OMNIFORGE EXPANSION PROMPT` and translates it into an Omniforge-appropriate plan.

## What The Attachment Is

The attachment is not a direct implementation patch.

It is a generated meta-prompt that asks an agent to:

- create `650+` OFP workers
- scaffold full worker directories for every language
- implement a stricter OFP variant
- add tests, manifests, Dockerfiles, examples, and capabilities for each worker

That makes it useful as backlog and design input, but unsafe to apply literally.

## Why It Cannot Be Applied Literally

Applying the prompt as written would create several problems:

1. It would encourage mass scaffolding of unverified workers.
2. It defines an OFP message shape that does not exactly match the current coordinator.
3. It assumes runtimes and package managers that do not exist on this Windows host.
4. It treats grouped categories, editor DSLs, data formats, and full languages as if they were the same kind of worker target.
5. It would inflate support claims far beyond what the repo can honestly execute and test.

## Current Omniforge Constraint

Omniforge only counts a language as supported when it has:

- a detected runtime or compiler
- a real worker manifest
- a working execution path through the coordinator
- automated verification

That rule stays in force.

## Protocol Mismatch Notes

The attachment proposes a stricter OFP shape with fields such as:

- `version` instead of `protocol`
- `worker_id` instead of `workerId`
- `request_id`
- `options.timeout_ms`
- richer `metrics`
- richer `error` objects

Current Omniforge workers and coordinator use the repo’s existing message format, so the prompt cannot be copied over verbatim without first versioning the coordinator and protocol.

## Safe Interpretation

The attachment is best treated as:

1. a capability backlog
2. a future worker-generator specification
3. a protocol-v2 design candidate
4. a language-family prioritization source

## Recommended Execution Plan

### Phase A: Stabilize Current Installed Runtimes

Finish operationalizing already-installed but not yet fully counted runtimes:

- `nushell`
- `octave`
- `gleam`
- `crystal`
- `dart`
- `zig`

### Phase B: Add High-Yield Real Workers

Expand only across runtimes that are already available or realistically installable here:

- `php`
- `clojure` or `babashka`
- `scala` if compiler health is fixed
- `cobol`
- `fortran`
- `objective-c` only through a realistic container or separate host path

### Phase C: Generator Tooling

Instead of hand-writing hundreds of workers, build:

- worker templates by runtime family
- a manifest generator
- OFP wrapper templates
- common test harness generation
- capability fixture generation

### Phase D: Protocol Evolution

If Omniforge wants the stricter attachment protocol, add:

- `ofp/2` schemas
- backward-compatibility rules
- coordinator support for both message families
- migration docs

## Worker Family Classification

The attachment mixes multiple target types that should be handled differently:

- real general-purpose languages
- shell environments
- editor scripting languages
- game-platform scripting dialects
- markup/config/data formats
- IDLs and serialization schemas
- visual tools and educational environments

These should not all produce the same worker template.

## Repo Action

This review means:

- the prompt is preserved as scope input
- it is not treated as an implementation command
- Omniforge will continue promoting only tested workers
- future large-batch generation should be template-driven, not fake-folder-driven
