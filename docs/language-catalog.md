# Language Catalog

Omniforge now tracks the large attachment-sourced language backlog as a catalog input, not as an automatic support claim.

## Source

- Attachment source: `pasted-text.txt`
- Captured into repo: `toolchains/backlog.json`
- Capture date: `2026-07-13`
- Total catalogued entries: `275`
- Additional reviewed scope prompt: `docs/mega-expansion-review.md`
- Repository language directories: `67`
- Newly added repository catalog batch in this pass: `55`

## What This Means

- Catalogued means the language, dialect, platform, tool, or ecosystem entry is tracked.
- Installed means a runtime or compiler was detected on this machine.
- Operational means Omniforge has a real OFP worker, a verified coordinator execution path, and test coverage.

The catalog intentionally includes:

- mainstream languages
- legacy systems
- shell environments
- domain-specific languages
- educational environments
- visual programming systems
- esoteric languages

That makes it valuable as backlog input, but it also means many entries are:

- aliases or grouped families
- proprietary or licensed products
- platform-specific to macOS, Linux, or mainframes
- not realistic to install directly on this Windows host
- better modeled through containers, emulators, or separate hosts

## Immediate Use

The imported catalog should drive:

1. deduplication of aliases and grouped entries
2. installability classification for this host
3. worker-priority selection for realistic runtimes
4. honest separation between backlog size and supported-worker count
5. template-driven worker generation rather than mass unverified scaffolding

## Repository Language Directories

The repository now contains a larger concrete `languages/` catalog in addition to the worker set.

- Each catalogued language directory includes `README.md`, `metadata.json`, `toolchain/manifest.json`, and a hello-world example.
- These entries exist for backlog realism, documentation, and future worker development.
- They are not counted as supported workers unless they satisfy the operational rule below.

## First Catalogued Entries

- `PYTHON`
- `JAVASCRIPT / NODE.JS`
- `TYPESCRIPT`
- `JAVA`
- `C`
- `C++`
- `C# (.NET)`
- `GO (GOLANG)`
- `RUST`
- `PHP`

## Rule

No entry from the catalog is counted as supported until it has:

- detected runtime or compiler
- worker manifest
- real OFP worker implementation
- verified coordinator execution path
- automated test coverage
