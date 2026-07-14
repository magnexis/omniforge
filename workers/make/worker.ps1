$ErrorActionPreference = "Stop"

function Send-Json {
  param([string]$Payload)
  Write-Output $Payload
}

foreach ($line in $input) {
  if ($null -eq $line) {
    continue
  }
  $line = [string]$line
  if ($line.Contains('"type":"HELLO"')) {
    Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"make-targets-01","language":"make","runtimeVersion":"gnu-make","workerVersion":"0.1.0","capabilities":[{"name":"dev.make-targets"}]}'
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    if ($payload.capability -eq "dev.make-targets") {
      $repoMakefile = Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "Makefile"
      if (-not (Test-Path $repoMakefile)) {
        Send-Json ('{"type":"JOB_ERROR","jobId":"' + $payload.jobId + '","error":"Makefile not found"}')
        continue
      }
      $targets = @()
      foreach ($entry in (Get-Content $repoMakefile)) {
        if ($entry -match '^([A-Za-z0-9_.-]+):\s*$' -and $entry -notmatch '^(#|\.|Makefile)') {
          $name = $matches[1]
          if ($targets -notcontains $name) {
            $targets += $name
          }
        }
      }
      $output = @{
        targetCount = $targets.Count
        targets = $targets
      } | ConvertTo-Json -Compress
      Send-Json ('{"type":"JOB_RESULT","jobId":"' + $payload.jobId + '","output":' + $output + '}')
      continue
    }

    Send-Json '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
    continue
  }

  if ($line.Contains('"type":"SHUTDOWN"')) {
    exit 0
  }
}
