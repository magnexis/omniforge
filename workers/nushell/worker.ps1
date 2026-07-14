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
        Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"nushell-reverse-01","language":"nushell","runtimeVersion":"0.114.1","workerVersion":"0.1.0","capabilities":[{"name":"text.reverse-nu"}]}'
        continue
    }

    if ($line.Contains('"type":"JOB_START"')) {
        $jobId = Get-JsonField -Line $line -Name "jobId"
        if (-not $line.Contains('"capability":"text.reverse-nu"')) {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $(if ($jobId) { $jobId } else { "job-unknown" }) + '","error":"unsupported capability"}')
            continue
        }

        $text = Get-JsonField -Line $line -Name "text"
        $env:OMNIFORGE_TEXT = $text
        $reversed = & "C:\Users\matth\AppData\Local\Programs\nu\bin\nu.exe" worker.nu
        if ($LASTEXITCODE -ne 0) {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $jobId + '","error":"nushell transform failed"}')
            continue
        }

        $escaped = ($reversed -replace '\\', '\\' -replace '"', '\"')
        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"reversed":"' + $escaped + '"}}')
        continue
    }

    if ($line.Contains('"type":"SHUTDOWN"')) {
        exit 0
    }
}
