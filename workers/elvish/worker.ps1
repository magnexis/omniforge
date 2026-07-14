$elvish = "C:\Users\matth\OneDrive\Desktop\we lit\polyglot-forge\.cache\runtime-shims\elvish.exe"

while (($line = [Console]::In.ReadLine()) -ne $null) {
  if ($line.Contains('"type":"HELLO"')) {
    Write-Output '{"type":"REGISTER","protocol":"ofp/1","workerId":"elvish-length-01","language":"elvish","runtimeVersion":"0.21.0","workerVersion":"0.1.0","capabilities":[{"name":"text.length-elvish"}]}'
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    if ($payload.capability -ne 'text.length-elvish') {
      Write-Output '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
      continue
    }

    $text = [string]$payload.input.text
    $raw = & $elvish -c 'put (count $args[0])' $text
    $length = [int](([string]$raw) -replace '[^\d-]', '')
    Write-Output "{""type"":""JOB_RESULT"",""jobId"":""$($payload.jobId)"",""output"":{""length"":$length}}"
    continue
  }

  if ($line.Contains('"type":"SHUTDOWN"')) {
    exit 0
  }
}
