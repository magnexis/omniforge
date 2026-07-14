$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send-Json {
    param([string]$Payload)
    [Console]::Out.WriteLine($Payload)
    [Console]::Out.Flush()
}

function Get-JsonField {
    param(
        [string]$Line,
        [string]$Name
    )

    $pattern = '"' + [Regex]::Escape($Name) + '":"([^"]*)"'
    $match = [regex]::Match($Line, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value
    }
    return ""
}

while (($line = [Console]::In.ReadLine()) -ne $null) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    if ($line.Contains('"type":"HELLO"')) {
        Send-Json '{"type":"WELCOME","protocol":"ofp/1","workerId":"zig-primes-01","language":"zig","runtimeVersion":"0.16","workerVersion":"0.1.0","status":"ready"}'
        Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"zig-primes-01","language":"zig","runtimeVersion":"0.16","workerVersion":"0.1.0","capabilities":[{"name":"algorithm.prime-search"}]}'
        continue
    }

    if ($line.Contains('"type":"REGISTER_ACK"')) {
        continue
    }

    if ($line.Contains('"type":"JOB_START"')) {
        $jobId = Get-JsonField -Line $line -Name "jobId"
        if (-not $line.Contains('"capability":"algorithm.prime-search"')) {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $(if ($jobId) { $jobId } else { "job-unknown" }) + '","error":"unsupported capability"}')
            continue
        }

        Send-Json ('{"type":"JOB_ACCEPTED","jobId":"' + $jobId + '","status":"running"}')
        Send-Json ('{"type":"JOB_LOG","jobId":"' + $jobId + '","severity":"info","message":"starting algorithm.prime-search"}')
        $limitMatch = [regex]::Match($line, '"limit":\s*(\d+)')
        $limit = if ($limitMatch.Success) { $limitMatch.Groups[1].Value } else { "0" }
        $payload = & ".\worker.exe" $limit
        if ($LASTEXITCODE -ne 0) {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $jobId + '","error":"zig execution failed"}')
            continue
        }

        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":' + ($payload -join "") + '}')
        continue
    }

    if ($line.Contains('"type":"JOB_CANCEL"')) {
        $jobId = Get-JsonField -Line $line -Name "jobId"
        Send-Json ('{"type":"JOB_CANCELLED","jobId":"' + $(if ($jobId) { $jobId } else { "job-unknown" }) + '","status":"cancelled"}')
        continue
    }

    if ($line.Contains('"type":"SHUTDOWN"')) {
        Send-Json '{"type":"SHUTDOWN_ACK","workerId":"zig-primes-01","status":"stopped"}'
        exit 0
    }
}
