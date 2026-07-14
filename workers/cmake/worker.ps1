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
        Send-Json '{"type":"WELCOME","protocol":"ofp/1","workerId":"cmake-replace-01","language":"cmake","runtimeVersion":"3.x","workerVersion":"0.1.0","status":"ready"}'
        Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"cmake-replace-01","language":"cmake","runtimeVersion":"3.x","workerVersion":"0.1.0","capabilities":[{"name":"text.replace-cmake"}]}'
        continue
    }

    if ($line.Contains('"type":"REGISTER_ACK"')) {
        continue
    }

    if ($line.Contains('"type":"JOB_START"')) {
        $payload = $line | ConvertFrom-Json
        $jobId = [string]$payload.jobId
        if ($payload.capability -ne "text.replace-cmake") {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $(if ($jobId) { $jobId } else { "job-unknown" }) + '","error":"unsupported capability"}')
            continue
        }

        Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $jobId + '","status":"running"}')
        Send-Json ('{"type":"JOB_LOG","jobId":"' + $jobId + '","severity":"info","message":"starting text.replace-cmake"}')
        $text = [string]$payload.input.text
        $from = [string]$payload.input.from
        $to = [string]$payload.input.to
        $script = Join-Path $PSScriptRoot "transform.cmake"
        $jobDir = Join-Path $PSScriptRoot "..\..\ .cache\cmake-worker\$jobId"
        $jobDir = [System.IO.Path]::GetFullPath($jobDir.Replace("\ .cache", "\.cache"))
        New-Item -ItemType Directory -Force -Path $jobDir | Out-Null
        $textFile = Join-Path $jobDir "output.txt"
        $lengthFile = Join-Path $jobDir "length.txt"
        $raw = & "C:\Program Files\CMake\bin\cmake.exe" "-DINPUT_TEXT=$text" "-DFROM_TEXT=$from" "-DTO_TEXT=$to" "-DOUTPUT_TEXT_FILE=$textFile" "-DOUTPUT_LENGTH_FILE=$lengthFile" -P $script 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errorText = ([string]($raw | Out-String)).Trim().Replace('\', '\\').Replace('"', '\"')
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $jobId + '","error":"' + $errorText + '"}')
            continue
        }

        $outputText = if (Test-Path $textFile) { [System.IO.File]::ReadAllText($textFile) } else { "" }
        $outputLength = if (Test-Path $lengthFile) { [int]([System.IO.File]::ReadAllText($lengthFile)) } else { $outputText.Length }
        $escaped = $outputText.Replace('\', '\\').Replace('"', '\"')
        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"text":"' + $escaped + '","length":' + $outputLength + '}}')
        continue
    }

    if ($line.Contains('"type":"JOB_CANCEL"')) {
        $payload = $line | ConvertFrom-Json
        $jobId = if ($payload.jobId) { [string]$payload.jobId } else { "job-unknown" }
        Send-Json ('{"type":"JOB_CANCELLED","jobId":"' + $jobId + '","status":"cancelled"}')
        continue
    }

    if ($line.Contains('"type":"SHUTDOWN"')) {
        Send-Json '{"type":"SHUTDOWN_ACK","workerId":"cmake-replace-01","status":"stopped"}'
        exit 0
    }
}
