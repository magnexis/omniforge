# Safety

Omniforge is evolving toward autonomous reliability workflows, but it must remain constrained.

## Principles

- no unrestricted autonomous production modification
- no silent repair execution
- no success claims without verification
- no hidden state transitions
- no worker-level bypass of approval policy

## Repair Modes

### Observe

- detect and collect evidence only

### Recommend

- produce structured repair proposals without execution

### Guarded Repair

- permit only preapproved low-risk actions

### Supervised Repair

- require explicit human approval before execution

### Emergency Containment

- allow strictly predefined containment actions such as isolation, shutdown, or restart

## Repository Status

Implemented today:

- process boundaries
- explicit capabilities
- structured worker errors
- manifest-based execution

Not yet fully implemented:

- signed repair records
- worker permissions model
- file sandboxing per worker
- CPU and memory enforcement
- artifact checksums everywhere
- rollback checkpoints
