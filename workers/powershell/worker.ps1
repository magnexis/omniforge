function Send-Message {
  param([string]$Payload)
  Write-Output $Payload
}

while ($line = [Console]::In.ReadLine()) {
  if ($line -match '"type":"HELLO"') {
    Send-Message '{"type":"REGISTER","protocol":"ofp/1","workerId":"powershell-env-01","language":"powershell","runtimeVersion":"windows-powershell","workerVersion":"0.1.0","capabilities":[{"name":"system.environment"},{"name":"ops.remediation-plan"}]}'
  } elseif ($line -match '"type":"JOB_START"') {
    $payload = $line | ConvertFrom-Json
    if ($payload.capability -eq "system.environment") {
      $count = (Get-ChildItem Env: | Measure-Object).Count
      Send-Message ('{"type":"JOB_RESULT","jobId":"' + $payload.jobId + '","output":{"variableCount":' + $count + '}}')
      continue
    }
    if ($payload.capability -eq "ops.remediation-plan") {
      $incidents = @($payload.input.previous.incidents)
      $actions = @()
      foreach ($incident in $incidents) {
        $command = switch ($incident.action) {
          "isolate_host" { "Disable-NetAdapter -Name `"$($incident.host)`" -Confirm:`$false" }
          "restart_service" { "Restart-Service -Name `"$($incident.service)`" -Force" }
          default { "Restart-Computer -ComputerName `"$($incident.host)`" -WhatIf" }
        }
        $actions += @{
          incidentId = $incident.id
          service = $incident.service
          host = $incident.host
          severity = $incident.severity
          action = ($incident.action -replace "_", "-")
          command = $command
        }
      }

      $critical = @($actions | Where-Object { $_.severity -eq "critical" }).Count
      $restartCount = @($actions | Where-Object { $_.action -eq "restart-service" }).Count
      $isolateCount = @($actions | Where-Object { $_.action -eq "isolate-host" }).Count
      $output = @{
        incidents = $incidents
        actions = $actions
        report = @{
          totalIncidents = $incidents.Count
          criticalIncidents = $critical
          restartActions = $restartCount
          isolateActions = $isolateCount
        }
      } | ConvertTo-Json -Depth 8 -Compress
      Send-Message ('{"type":"JOB_RESULT","jobId":"' + $payload.jobId + '","output":' + $output + '}')
      continue
    }
    Send-Message '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
  } elseif ($line -match '"type":"SHUTDOWN"') {
    break
  }
}
