$ErrorActionPreference = "Stop"

$cabal = "C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\haskell.cabal_Microsoft.Winget.Source_8wekyb3d8bbwe\cabal.exe"
if (-not (Test-Path $cabal)) {
  $cabal = "cabal"
}

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
    Send-Json '{"type":"WELCOME","protocol":"ofp/1","workerId":"cabal-plan-01","language":"cabal","runtimeVersion":"3.10.2.0","workerVersion":"0.1.0","status":"ready"}'
    Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"cabal-plan-01","language":"cabal","runtimeVersion":"3.10.2.0","workerVersion":"0.1.0","capabilities":[{"name":"dev.haskell-tooling"}]}'
    continue
  }

  if ($line.Contains('"type":"REGISTER_ACK"')) {
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    if ($payload.capability -eq "dev.haskell-tooling") {
      Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $payload.jobId + '","status":"running"}')
      Send-Json ('{"type":"JOB_LOG","jobId":"' + $payload.jobId + '","severity":"info","message":"starting dev.haskell-tooling"}')
      $version = (& $cabal --numeric-version 2>$null).Trim()
      if ([string]::IsNullOrWhiteSpace($version)) {
        $version = "unknown"
      }
      $input = $payload.input
      $output = @{
        tool = "cabal"
        version = $version
        requestedPackage = [string]$input.package
        suggestedCommand = if ([string]::IsNullOrWhiteSpace([string]$input.package)) {
          "cabal update"
        } else {
          "cabal install " + [string]$input.package
        }
      } | ConvertTo-Json -Compress
      Send-Json ('{"type":"JOB_RESULT","jobId":"' + $payload.jobId + '","output":' + $output + '}')
      continue
    }

    Send-Json '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
    continue
  }

  if ($line.Contains('"type":"JOB_CANCEL"')) {
    $payload = $line | ConvertFrom-Json
    $jobId = if ($payload.jobId) { [string]$payload.jobId } else { "job-unknown" }
    Send-Json ('{"type":"JOB_CANCELLED","jobId":"' + $jobId + '","status":"cancelled"}')
    continue
  }

  if ($line.Contains('"type":"SHUTDOWN"')) {
    Send-Json '{"type":"SHUTDOWN_ACK","workerId":"cabal-plan-01","status":"stopped"}'
    exit 0
  }
}
