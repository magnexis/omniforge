$ErrorActionPreference = "Stop"

$arturo = "C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\ArturoLang.Arturo_Microsoft.Winget.Source_8wekyb3d8bbwe\arturo.exe"
if (-not (Test-Path $arturo)) {
  $arturo = "arturo"
}

$cacheRoot = Join-Path $PSScriptRoot ".cache"
New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

function Send-Json {
  param([string]$Payload)
  Write-Output $Payload
}

function Escape-ArturoString {
  param([string]$Text)
  return $Text.Replace('\', '\\').Replace('"', '\"')
}

foreach ($line in $input) {
  if ($null -eq $line) {
    continue
  }
  $line = [string]$line

  if ($line.Contains('"type":"HELLO"')) {
    Send-Json '{"type":"WELCOME","protocol":"ofp/1","workerId":"arturo-lower-01","language":"arturo","runtimeVersion":"0.10.0","workerVersion":"0.1.0","status":"ready"}'
    Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"arturo-lower-01","language":"arturo","runtimeVersion":"0.10.0","workerVersion":"0.1.0","capabilities":[{"name":"text.lower-arturo"}]}'
    continue
  }

  if ($line.Contains('"type":"REGISTER_ACK"')) {
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    if ($payload.capability -ne "text.lower-arturo") {
      Send-Json '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
      continue
    }

    $text = [string]$payload.input.text
    $escaped = Escape-ArturoString $text
    $scriptPath = Join-Path $cacheRoot "job-$($payload.jobId).art"
    Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $payload.jobId + '","status":"running"}')
    Send-Json ('{"type":"JOB_LOG","jobId":"' + $payload.jobId + '","severity":"info","message":"starting text.lower-arturo"}')
    @"
a: "$escaped"
print lower a
"@ | Set-Content -NoNewline $scriptPath

    $lowered = (& $arturo $scriptPath 2>$null | Out-String).Trim()
    $safeLowered = $lowered.Replace('\', '\\').Replace('"', '\"')
    Send-Json ('{"type":"JOB_RESULT","jobId":"' + $payload.jobId + '","output":{"lowered":"' + $safeLowered + '"}}')
    continue
  }

  if ($line.Contains('"type":"JOB_CANCEL"')) {
    $payload = $line | ConvertFrom-Json
    $jobId = if ($payload.jobId) { [string]$payload.jobId } else { "job-unknown" }
    Send-Json ('{"type":"JOB_CANCELLED","jobId":"' + $jobId + '","status":"cancelled"}')
    continue
  }

  if ($line.Contains('"type":"SHUTDOWN"')) {
    Send-Json '{"type":"SHUTDOWN_ACK","workerId":"arturo-lower-01","status":"stopped"}'
    exit 0
  }
}
