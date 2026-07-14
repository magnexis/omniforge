$git = "C:\Program Files\Git\cmd\git.exe"
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))

function Send-Json {
  param([string]$Payload)
  Write-Output $Payload
}

function Escape-Json {
  param([string]$Text)
  return $Text.Replace('\', '\\').Replace('"', '\"').Replace("`r", "").Replace("`n", '\n')
}

while (($line = [Console]::In.ReadLine()) -ne $null) {
  if ($line.Contains('"type":"HELLO"')) {
    Send-Json '{"type":"WELCOME","protocol":"ofp/1","workerId":"git-inspect-01","language":"git","runtimeVersion":"2.55.0","workerVersion":"0.1.0","status":"ready"}'
    Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"git-inspect-01","language":"git","runtimeVersion":"2.55.0","workerVersion":"0.1.0","capabilities":[{"name":"repo.file-list"},{"name":"repo.status"}]}'
    continue
  }

  if ($line.Contains('"type":"REGISTER_ACK"')) {
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    $jobId = [string]$payload.jobId

    if ($payload.capability -eq "repo.file-list") {
      Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $jobId + '","status":"running"}')
      Send-Json ('{"type":"JOB_LOG","jobId":"' + $jobId + '","severity":"info","message":"starting repo.file-list"}')
      $tracked = & $git -C $repoRoot ls-files 2>$null
      $gitExit = $LASTEXITCODE
      $untracked = @()
      if ($gitExit -eq 0) {
        $untracked = & $git -C $repoRoot ls-files --others --exclude-standard 2>$null
      }
      if ($gitExit -eq 0) {
        $files = @($tracked + $untracked) |
          Where-Object { $_ -and $_.Trim().Length -gt 0 } |
          Sort-Object -Unique
      } else {
        $rg = Get-Command rg -ErrorAction SilentlyContinue
        if ($null -ne $rg) {
          $files = & $rg.Path --files $repoRoot 2>$null
        } else {
          $files = Get-ChildItem -Path $repoRoot -Recurse -File -Force |
            Where-Object { $_.FullName -notlike "*\\node_modules\\*" -and $_.FullName -notlike "*\\.cache\\*" } |
            ForEach-Object {
              [System.IO.Path]::GetRelativePath($repoRoot, $_.FullName).Replace('\', '/')
            }
        }
      }
      $preview = @($files | Select-Object -First 200)
      $json = ($preview | ConvertTo-Json -Depth 4 -Compress)
      Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"root":"' + ($repoRoot.Replace('\', '\\')) + '","fileCount":' + $files.Count + ',"previewCount":' + $preview.Count + ',"files":' + $json + '}}')
      continue
    }

    if ($payload.capability -eq "repo.status") {
      Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $jobId + '","status":"running"}')
      Send-Json ('{"type":"JOB_LOG","jobId":"' + $jobId + '","severity":"info","message":"starting repo.status"}')
      $raw = & $git -C $repoRoot status --short 2>&1
      $exitCode = $LASTEXITCODE
      $statusText = ([string]($raw | Out-String)).Trim()
      $output = @{
        root = $repoRoot
        gitAvailable = $true
        repositoryPresent = ($exitCode -eq 0)
        statusText = $statusText
      }
      if ($exitCode -ne 0) {
        $output["error"] = $statusText
      }
      $json = $output | ConvertTo-Json -Depth 6 -Compress
      Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":' + $json + '}')
      continue
    }

    Send-Json ('{"type":"JOB_ERROR","jobId":"' + $jobId + '","error":"unsupported capability"}')
    continue
  }

  if ($line.Contains('"type":"JOB_CANCEL"')) {
    $payload = $line | ConvertFrom-Json
    $jobId = if ($payload.jobId) { [string]$payload.jobId } else { "job-unknown" }
    Send-Json ('{"type":"JOB_CANCELLED","jobId":"' + $jobId + '","status":"cancelled"}')
    continue
  }

  if ($line.Contains('"type":"SHUTDOWN"')) {
    Send-Json '{"type":"SHUTDOWN_ACK","workerId":"git-inspect-01","status":"stopped"}'
    exit 0
  }
}
