# Omniforge Protocol

Omniforge uses OFP, the Omniforge Protocol.

Current version:

- `ofp/1`

Current transport:

- newline-delimited JSON over stdio

## OFP v1 Message Surface

- 31 defined message types
- minimum worker subset remains simple
- broader control, artifact, tracing, and health commands are now documented for phased adoption

### Handshake and session

- `HELLO`
- `WELCOME`
- `REGISTER`
- `REGISTER_ACK`
- `PING`
- `PONG`
- `HEARTBEAT`
- `HEALTH_REPORT`
- `SHUTDOWN`
- `SHUTDOWN_ACK`

### Discovery and planning

- `CAPABILITIES`
- `CAPABILITY_QUERY`
- `CAPABILITY_RESPONSE`
- `WORKER_STATUS`
- `METRICS_SNAPSHOT`

### Job execution

- `JOB_START`
- `JOB_ACCEPTED`
- `JOB_PROGRESS`
- `JOB_LOG`
- `JOB_STREAM`
- `JOB_RESULT`
- `JOB_ERROR`
- `JOB_CANCEL`
- `JOB_CANCELLED`

### Artifact transfer

- `ARTIFACT_PUT`
- `ARTIFACT_GET`
- `ARTIFACT_REF`
- `ARTIFACT_CHUNK`
- `ARTIFACT_COMPLETE`

### Diagnostics

- `TRACE_START`
- `TRACE_STOP`

## Current Implemented Baseline

Implemented broadly across the current coordinator and worker set:

- `HELLO`
- `REGISTER`
- `JOB_START`
- `JOB_PROGRESS`
- `JOB_RESULT`
- `JOB_ERROR`
- `SHUTDOWN`

Implemented in the upgraded coordinator path and a stable first worker slice:

- `WELCOME`
- `REGISTER_ACK`
- `JOB_ACCEPTED`
- `JOB_LOG`
- `JOB_CANCEL`
- `SHUTDOWN_ACK`

New work should prefer the expanded OFP message set instead of inventing ad hoc side channels.

## Reliability Upgrade Direction

To support autonomous incident workflows, OFP should use the expanded message surface together with structured envelopes for:

- `IncidentEvent`
- `InvestigationRequest`
- `InvestigationResult`
- `EvidenceArtifact`
- `RepairProposal`
- `RepairAction`
- `VerificationPlan`
- `VerificationResult`
- `RollbackPlan`
- `LearningRecord`
- `AuditEvent`

## Envelope Requirements

Every reliability-oriented message should include:

- protocol version
- message id
- timestamp
- correlation id
- incident id
- worker id
- source
- confidence
- risk level
- payload checksum
- optional parent event id

The current repository implementation is still lighter than that full target, but the protocol definition now makes the intended direction explicit.
