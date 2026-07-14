# Self-Healing Bots Demo

`self-healing-ops` is a cross-language Omniforge pipeline for incident triage and remediation planning.

## Flow

1. `python` normalizes raw incident telemetry from JSON.
2. `prolog` applies policy rules to classify severity and choose remediation classes.
3. `powershell` turns those decisions into concrete remediation commands.
4. `jq` computes a compact operations summary from the remediation plan.
5. `protobuf` compiles a real protocol descriptor for an `IncidentPacket` envelope and packages the summary preview.
6. `rust` compresses the final artifact payload.

## Run

```powershell
python omniforge.py pipeline run pipelines/self-healing-ops.json --input examples/data/incidents.json
```

## Why It Matters

This is a stronger Omniforge demonstration than disconnected toy workers because:

- the languages cooperate on one operational objective
- policy and remediation are separated into distinct worker responsibilities
- protocol tooling participates as part of the workflow
- the final output is packageable for downstream systems
