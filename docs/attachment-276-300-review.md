# Attachment Review 276-300

This review covers the second attachment batch, entries `#276` through `#300`.

## Likely Active And Installable

- `Flowgorithm`
- `RAPTOR`
- `Luau / Roblox Lua`
- `Vimscript`
- `Emacs Lisp`
- `INI`
- `Java Properties`
- `HOCON`
- `TOML`
- `YAML`
- `JSON`
- `JSON-LD`
- `CBOR`
- `MessagePack`
- `Protocol Buffers`
- `Apache Thrift`
- `Cap'n Proto`
- `FlatBuffers`
- `Avro`

These are not all equal in scope. Some are full language runtimes, some are data languages or IDLs, and some are editor or game-platform scripting environments.

## Active But Platform-Bound Or Ecosystem-Specific

- `FiveM Lua`
- `Garry's Mod Lua`
- `World of Warcraft Lua Addon API`
- `Neovim Lua API`

These are real and still used, but they are tied to a host product, editor, or game ecosystem rather than being generic standalone language installs for Omniforge.

## Not Really A Standalone Language

- `LMS (Learning Management System code)`
- `Configuration Languages (general category)`

These are categories or scripting surfaces, not a single installable language runtime.

## Practical Omniforge Recommendation

Highest-yield additions from this attachment are:

1. `Luau / Roblox Lua` as a Lua-family dialect candidate
2. `Vimscript` and `Emacs Lisp` as editor-embedded scripting targets
3. `Protocol Buffers`, `MessagePack`, `CBOR`, `FlatBuffers`, and `Avro` as interoperability/IDL targets rather than standalone worker languages
4. `Flowgorithm` and `RAPTOR` only if Omniforge wants educational or visual-language catalog coverage

## Magnificent Language

- Repository verified: `https://github.com/magnexis/magnificent-language`
- Repo name: `magnificent-language`
- CLI entrypoint verified locally: `node bin/mgl help`
- Workspace-local shim added: `.cache/runtime-shims/mgl.cmd`

## COBOL-X

No `COBOL-X` implementation, package, directory, binary, or documentation was found in the `magnificent-language` repository snapshot that was cloned for inspection, so it should not be counted as installable from that repository.

A separate repository was then verified at `https://github.com/magnexis/cobolx`.

- Repo name: `cobolx`
- Install model: `npm` workspace source build
- Local status: source install completed on this Windows host
- Build notes: required small local TypeScript return-path fixes plus workspace `dist` flattening to match package `main` entries
- CLI smoke test: `node cli/cobolx-cli/dist/index.js` prints usage successfully
- Workspace-local shim added: `.cache/runtime-shims/cobolx.cmd`
