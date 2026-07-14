# Attachment 276-300 Host Viability

This document narrows the `#276-300` attachment batch to what is most useful for Omniforge on this Windows host.

## Detected On This Host

Installed and verified:

- `jq` at `C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe\jq.exe`
- `protoc` at `C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\Google.Protobuf_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\protoc.exe`
- `nvim` at `C:\Program Files\Neovim\bin\nvim.exe`

Still missing from the candidate set:

- `vim`
- `emacs`
- `thrift`
- `capnp`
- `flatc`
- `flowgorithm`
- `raptor`

## Best Next Real Targets

These are the highest-yield entries from the batch for Omniforge:

1. `jq`
   Reason: lightweight JSON processing CLI, directly useful for OFP fixtures and data workers.
2. `Protocol Buffers / protoc`
   Reason: strong interoperability target and useful for protocol tooling.
3. `Neovim` or `Vim`
   Reason: unlocks Vimscript-family worker exploration.
4. `Emacs`
   Reason: unlocks Emacs Lisp worker exploration.
5. `Flowgorithm`
   Reason: real Windows install path, but lower yield than protocol/data tooling.
6. `RAPTOR`
   Reason: real Windows educational tool, but lower yield than protocol/data tooling.

## Real But Not Good Standalone Installs For Omniforge

- `FiveM Lua`
- `Garry's Mod Lua`
- `World of Warcraft Lua Addon API`
- `Neovim Lua API`

These are ecosystem-bound and should be tracked as dialect/platform surfaces rather than default host installs.

## Data / IDL Formats

These are real and useful, but they are not standalone language runtimes in the same sense as Python or Lua:

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

For Omniforge, these should usually become:

- parser capabilities
- transform capabilities
- validation capabilities
- serialization benchmark targets

## Recommended Install Batch

Completed first batch:

- `jq`
- `protoc`
- `neovim`

The best second batch is:

- `emacs`
- `flowgorithm`
- `raptor`

## Rule

No item from this batch should be counted as supported until it has:

- a verified install path
- a detected executable
- a real Omniforge capability
- a working coordinator execution path
- automated verification
