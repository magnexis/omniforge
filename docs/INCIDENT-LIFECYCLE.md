# Incident Lifecycle

Omniforge will use a strict incident state model for autonomous reliability workflows.

## Target States

- `DETECTED`
- `TRIAGED`
- `INVESTIGATING`
- `DIAGNOSED`
- `PLANNED`
- `AWAITING_APPROVAL`
- `REPAIRING`
- `VERIFYING`
- `RESOLVED`
- `ROLLED_BACK`
- `ESCALATED`
- `FAILED`
- `ARCHIVED`

## Rules

- every transition must be validated
- every transition must be auditable
- `RESOLVED` requires successful verification
- `ROLLED_BACK` requires a recorded failed repair or verification failure
- high-risk repairs must pass through `AWAITING_APPROVAL`

## Current Status

The current coordinator implements job and pipeline flow, but not persistent incident state yet. This document is the contract that future daemon work should implement.
