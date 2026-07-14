$jq = "C:\Users\matth\OneDrive\Desktop\we lit\polyglot-forge\.cache\runtime-shims\jq.exe"

function Send-Json {
  param([string]$Payload)
  Write-Output $Payload
}

while (($line = [Console]::In.ReadLine()) -ne $null) {
  if ($line.Contains('"type":"HELLO"')) {
    Send-Json '{"type":"WELCOME","protocol":"ofp/1","workerId":"jq-query-01","language":"jq","runtimeVersion":"jq-1.8.1","workerVersion":"0.1.0","status":"ready"}'
    Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"jq-query-01","language":"jq","runtimeVersion":"jq-1.8.1","workerVersion":"0.1.0","capabilities":[{"name":"data.json-query"},{"name":"ops.remediation-summary"}]}'
    continue
  }

  if ($line.Contains('"type":"REGISTER_ACK"')) {
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    if ($payload.capability -eq "data.json-query") {
      $jobId = [string]$payload.jobId
      Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $jobId + '","status":"running"}')
      Send-Json ('{"type":"JOB_LOG","jobId":"' + $jobId + '","severity":"info","message":"starting data.json-query"}')
      $query = [string]$payload.input.query
      $document = $payload.input.document | ConvertTo-Json -Depth 100 -Compress
      $raw = $document | & $jq -c $query 2>&1
      if ($LASTEXITCODE -ne 0) {
        $errorText = ([string]($raw | Out-String)).Trim().Replace('\', '\\').Replace('"', '\"')
        Send-Json ('{"type":"JOB_ERROR","jobId":"' + $jobId + '","error":"' + $errorText + '"}')
        continue
      }

      $resultText = ([string]($raw | Out-String)).Trim()
      if ([string]::IsNullOrWhiteSpace($resultText)) {
        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"result":null}}')
        continue
      }

      try {
        $parsed = $resultText | ConvertFrom-Json
        $resultJson = $parsed | ConvertTo-Json -Depth 100 -Compress
        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"result":' + $resultJson + '}}')
      } catch {
        $escaped = $resultText.Replace('\', '\\').Replace('"', '\"')
        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"resultText":"' + $escaped + '"}}')
      }
      continue
    }

    if ($payload.capability -eq "ops.remediation-summary") {
      $jobId = [string]$payload.jobId
      Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $jobId + '","status":"running"}')
      Send-Json ('{"type":"JOB_LOG","jobId":"' + $jobId + '","severity":"info","message":"starting ops.remediation-summary"}')
      $document = $payload.input.previous | ConvertTo-Json -Depth 100 -Compress
      $query = '{totalIncidents: (.incidents | length), criticalIncidents: ([.incidents[] | select(.severity == "critical")] | length), restartActions: ([.actions[] | select(.action == "restart-service")] | length), isolateActions: ([.actions[] | select(.action == "isolate-host")] | length)}'
      $raw = $document | & $jq -c $query 2>&1
      if ($LASTEXITCODE -ne 0) {
        $errorText = ([string]($raw | Out-String)).Trim().Replace('\', '\\').Replace('"', '\"')
        Send-Json ('{"type":"JOB_ERROR","jobId":"' + $jobId + '","error":"' + $errorText + '"}')
        continue
      }
      $summary = ([string]($raw | Out-String)).Trim()
      Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":' + $summary + '}')
      continue
    }

    if ($payload.capability -ne "data.json-query") {
      Send-Json '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
      continue
    }
  }

  if ($line.Contains('"type":"JOB_CANCEL"')) {
    $payload = $line | ConvertFrom-Json
    $jobId = if ($payload.jobId) { [string]$payload.jobId } else { "job-unknown" }
    Send-Json ('{"type":"JOB_CANCELLED","jobId":"' + $jobId + '","status":"cancelled"}')
    continue
  }

  if ($line.Contains('"type":"SHUTDOWN"')) {
    Send-Json '{"type":"SHUTDOWN_ACK","workerId":"jq-query-01","status":"stopped"}'
    exit 0
  }
}
