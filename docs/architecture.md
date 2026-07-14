# Omniforge Architecture

Omniforge remains the project name.

The repository is being evolved into an autonomous reliability runtime, not renamed into another product.

## Identity

Omniforge is:

- a local-first polyglot execution fabric
- a universal worker runtime
- a distributed incident-response foundation
- a self-healing software operations platform in phased development

Core lifecycle:

`OBSERVE -> CLASSIFY -> INVESTIGATE -> PLAN -> REPAIR -> VERIFY -> LEARN`

## Current Runtime

Current implemented path:

- Python CLI invokes the Go coordinator
- the coordinator loads worker manifests
- the scheduler selects a compatible worker
- workers run as separate OS processes
- OFP messages flow over stdio
- pipeline output from one worker becomes input to the next worker

## Target Reliability Architecture

```text
Clients
  |
  +-- CLI
  +-- Desktop / local agent
  +-- API / automation hooks
  |
  v
Omniforge Daemon
  |
  +-- Registry
  +-- Router
  +-- Incident State Machine
  +-- Scheduler
  +-- Verification Engine
  +-- Repair Policy Engine
  +-- Audit Log
  +-- Learning Archive
  |
  v
Worker Families
  +-- Supervisory
  +-- Systems
  +-- Services
  +-- Analysis
  +-- Web
  +-- Automation
  +-- Policy
  +-- Database
  +-- Legacy / Compatibility
```

## Preservation Plan

Existing code is preserved as the seed of the daemon runtime:

- `omniforge.py` is the single public entry point and release surface
- `apps/cli` contains the implementation of that public CLI surface
- `apps/coordinator` is an internal control-plane component invoked by the CLI
- `workers/*` are the existing OFP worker fleet
- `pipelines/*` are the current workflow definitions
- `protocol/*` is the current protocol source of truth

## Phased Upgrade

### Phase 1

- formalize protocol and incident model
- formalize worker manifest schema
- document language roles
- expand CLI and detection
- add incident-oriented workflow definitions

### Phase 2

- implement first end-to-end healing workflow
- add repair proposal structure
- add verification and rollback records

### Phase 3

- add persistent daemon state
- add worker supervision and heartbeats
- add arena scoring and learning archive

### Phase 4

- add guarded repair modes
- add audit export
- add distributed deployment interfaces
