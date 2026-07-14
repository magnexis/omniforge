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

function Get-JsonNumbers {
    param([string]$Line)

    $match = [regex]::Match($Line, '"numbers":\[(.*?)\]')
    if (-not $match.Success) {
        return @()
    }

    return $match.Groups[1].Value.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" }
}

while (($line = [Console]::In.ReadLine()) -ne $null) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    if ($line.Contains('"type":"HELLO"')) {
        Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"octave-mean-01","language":"octave","runtimeVersion":"11.3.0","workerVersion":"0.1.0","capabilities":[{"name":"math.mean"}]}'
        continue
    }

    if ($line.Contains('"type":"JOB_START"')) {
        $jobId = Get-JsonField -Line $line -Name "jobId"
        if (-not $line.Contains('"capability":"math.mean"')) {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $(if ($jobId) { $jobId } else { "job-unknown" }) + '","error":"unsupported capability"}')
            continue
        }

        $numbers = Get-JsonNumbers -Line $line
        $count = $numbers.Count
        $source = if ($count -gt 0) { [string]::Join(", ", $numbers) } else { "" }
        $octave = "numbers = [$source]; if isempty(numbers), fprintf('0 0'); else fprintf('%d %g', numel(numbers), mean(numbers)); end;"
        $result = & "C:\Users\matth\AppData\Local\Programs\GNU Octave\Octave-11.3.0\mingw64\bin\octave-cli.exe" --quiet --eval $octave
        if ($LASTEXITCODE -ne 0) {
            Send-Json ('{"type":"JOB_ERROR","jobId":"' + $jobId + '","error":"octave execution failed"}')
            continue
        }

        $parts = ($result -join "") -split "\s+"
        $outCount = if ($parts.Length -ge 1 -and $parts[0] -ne "") { $parts[0] } else { "0" }
        $mean = if ($parts.Length -ge 2) { $parts[1] } else { "0" }
        Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":{"count":' + $outCount + ',"mean":' + $mean + '}}')
        continue
    }

    if ($line.Contains('"type":"SHUTDOWN"')) {
        exit 0
    }
}
