# Runbooks

## Current Runbooks

### Inspect Workers

```powershell
python omniforge.py workers list
python omniforge.py workers inspect jq-query-01
```

### Inspect Capabilities

```powershell
python omniforge.py capabilities list
python omniforge.py capabilities search proto
```

### Inspect Languages

```powershell
python omniforge.py languages list
python omniforge.py languages inspect python
```

### Detect Toolchains

```powershell
python omniforge.py toolchains detect
```

### Run Current Data Pipeline

```powershell
python omniforge.py pipeline run pipelines/data-intelligence.yaml --input examples/data/customers.csv
```

## Next Runbooks To Implement

- create incident
- inspect incident
- approve repair
- reject repair
- rollback repair
- export audit history
