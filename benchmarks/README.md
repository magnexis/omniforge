# Benchmarking

Tier 4 in Omniforge means benchmark-validated, not merely operational.

Current status:

- Tier 3 means the worker has a real OFP execution path and automated validation in `tests/test_omniforge.py`
- Tier 4 should mean the worker participates in a repeatable benchmark run with captured timing output

Initial benchmark entrypoint:

```bash
python benchmarks/run_worker_benchmarks.py
```

This benchmark pass currently focuses on a small core set of stable workers and records:

- capability
- language
- worker id
- elapsed milliseconds

The benchmark runner is intentionally narrow for now. It provides a real upgrade path to Tier 4, but the repository does not yet claim Tier 4 for workers until the benchmark matrix and persistence are broader.
