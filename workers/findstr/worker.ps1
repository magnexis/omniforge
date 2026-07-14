$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send-Json {
    param([string]$Payload)
    [Console]::Out.WriteLine($Payload)
    [Console]::Out.Flush()
}

while (($line = [Console]::In.ReadLine()) -ne $null) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    if ($line.Contains('"type":"HELLO"')) {
        Send-Json '{"type":"WELCOME","protocol":"ofp/1","workerId":"findstr-search-01","language":"findstr","runtimeVersion":"windows","workerVersion":"0.1.0","status":"ready"}'
        Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"findstr-search-01","language":"findstr","runtimeVersion":"windows","workerVersion":"0.1.0","capabilities":[{"name":"text.search-findstr"}]}'
        continue
    }

    if ($line.Contains('"type":"REGISTER_ACK"')) {
        continue
    }

    if ($line.Contains('"type":"JOB_START"')) {
        $payload = $line | ConvertFrom-Json
        $jobId = [string]$payload.jobId
        if ($payload.capability -ne "text.search-findstr") {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $(if ($jobId) { $jobId } else { "job-unknown" }) + '","error":"unsupported capability"}')
            continue
        }

        Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $jobId + '","status":"running"}')
        Send-Json ('{"type":"JOB_LOG","jobId":"' + $jobId + '","severity":"info","message":"starting text.search-findstr"}')
        $text = [string]$payload.input.text
        $pattern = [string]$payload.input.pattern
        $jobDir = Join-Path $PSScriptRoot "..\..\ .cache\findstr-worker\$jobId"
        $jobDir = [System.IO.Path]::GetFullPath($jobDir.Replace("\ .cache", "\.cache"))
        New-Item -ItemType Directory -Force -Path $jobDir | Out-Null
        $inputPath = Join-Path $jobDir "input.txt"
        [System.IO.File]::WriteAllText($inputPath, $text, [System.Text.UTF8Encoding]::new($false))
        $raw = & findstr /R /C:$pattern $inputPath 2>$null
        $matches = @()
        if ($LASTEXITCODE -eq 0 -and $raw) {
            $matches = @($raw | ForEach-Object { [string]$_ })
        }

        $matchesJson = (@($matches) | ConvertTo-Json -Compress)
        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"count":' + $matches.Count + ',"matches":' + $matchesJson + '}}')
        continue
    }

    if ($line.Contains('"type":"JOB_CANCEL"')) {
        $payload = $line | ConvertFrom-Json
        $jobId = if ($payload.jobId) { [string]$payload.jobId } else { "job-unknown" }
        Send-Json ('{"type":"JOB_CANCELLED","jobId":"' + $jobId + '","status":"cancelled"}')
        continue
    }

    if ($line.Contains('"type":"SHUTDOWN"')) {
        Send-Json '{"type":"SHUTDOWN_ACK","workerId":"findstr-search-01","status":"stopped"}'
        exit 0
    }
}
