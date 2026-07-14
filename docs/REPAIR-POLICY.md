# Repair Policy

Repairs in Omniforge should be represented as structured operations, not just free-form text.

## Required Fields

- diagnosis
- supporting evidence
- affected targets
- exact change or action
- expected outcome
- confidence
- risk level
- blast radius
- prerequisites
- approval requirement
- verification plan
- rollback plan
- timeout
- alternatives

## Allowed Repair Classes

- edit file
- apply patch
- update configuration
- restart process
- rebuild target
- rotate unhealthy worker
- restore file
- validate migration
- open escalation

## Denials

- no unrestricted arbitrary shell execution as an autonomous repair
- no destructive data operations without explicit approval
- no marking repairs successful without verification evidence
