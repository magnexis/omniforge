$ErrorActionPreference = "Stop"

function Send-Json {
  param([string]$Payload)
  Write-Output $Payload
}

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

while (($line = [Console]::In.ReadLine()) -ne $null) {
  if ($line.Contains('"type":"HELLO"')) {
    Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"dockerfile-packs-01","language":"dockerfile","runtimeVersion":"dockerfile","workerVersion":"0.1.0","capabilities":[{"name":"container.language-packs"}]}'
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    if ($payload.capability -eq "container.language-packs") {
      $dockerfiles = Get-ChildItem (Join-Path $repoRoot "containers") -Recurse -Filter Dockerfile | ForEach-Object {
        $_.FullName.Replace($repoRoot + "\", "").Replace("\", "/")
      }
      $output = @{
        dockerfileCount = @($dockerfiles).Count
        dockerfiles = @($dockerfiles)
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
