# Threat Model

Omniforge executes many runtimes, so it must assume worker failure and potential worker compromise.

## Main Risks

- malformed or malicious worker output
- command escalation through repair actions
- filesystem overreach
- dependency-based compromise
- log and evidence leakage
- false-positive repairs
- verification bypass
- silent worker crashes

## Mitigations Direction

- protocol validation
- capability allowlists
- per-worker execution boundaries
- approval gates
- audit logging
- artifact validation
- rollback checkpoints
- supervisor quarantine

## Current Honest Status

The repository has only partial mitigation implementation today. The threat model is documented now so future daemon and repair work can be built against an explicit safety contract.
