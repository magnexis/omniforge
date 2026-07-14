$protoc = "C:\Users\matth\OneDrive\Desktop\we lit\polyglot-forge\.cache\runtime-shims\protoc.exe"
$tempRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.cache\protobuf-worker"))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

function Send-Json {
  param([string]$Payload)
  Write-Output $Payload
}

function Invoke-Protoc {
  param(
    [string]$JobId,
    [string]$ProtoText,
    [string]$FileName
  )

  $jobDir = Join-Path $tempRoot $JobId
  New-Item -ItemType Directory -Force -Path $jobDir | Out-Null
  $protoPath = Join-Path $jobDir $FileName
  $descriptorPath = Join-Path $jobDir "descriptor.pb"
  [System.IO.File]::WriteAllText($protoPath, $ProtoText, [System.Text.UTF8Encoding]::new($false))

  $raw = & $protoc "--proto_path=$jobDir" "--descriptor_set_out=$descriptorPath" "--include_imports" $protoPath 2>&1
  if ($LASTEXITCODE -ne 0) {
    $errorText = ([string]($raw | Out-String)).Trim().Replace('\', '\\').Replace('"', '\"')
    Send-Json ('{"type":"JOB_ERROR","jobId":"' + $JobId + '","error":"' + $errorText + '"}')
    return $null
  }

  $bytes = [System.IO.File]::ReadAllBytes($descriptorPath)
  return @{
    fileName = $FileName
    descriptorBytes = $bytes.Length
    descriptorBase64 = [Convert]::ToBase64String($bytes)
  }
}

while (($line = [Console]::In.ReadLine()) -ne $null) {
  if ($line.Contains('"type":"HELLO"')) {
    Send-Json '{"type":"REGISTER","protocol":"ofp/1","workerId":"protobuf-descriptor-01","language":"protobuf","runtimeVersion":"protoc-33.0","workerVersion":"0.1.0","capabilities":[{"name":"dev.proto-descriptor"},{"name":"ops.incident-packet"}]}'
    continue
  }

  if ($line.Contains('"type":"JOB_START"')) {
    $payload = $line | ConvertFrom-Json
    $jobId = [string]$payload.jobId
    if ($payload.capability -eq "dev.proto-descriptor") {
      $proto = [string]$payload.input.proto
      $fileName = [string]$payload.input.fileName
      if ([string]::IsNullOrWhiteSpace($fileName)) {
        $fileName = "schema.proto"
      }
      $result = Invoke-Protoc -JobId $jobId -ProtoText $proto -FileName $fileName
      if ($null -eq $result) {
        continue
      }
      $outputJson = $result | ConvertTo-Json -Compress
      Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":' + $outputJson + '}')
      continue
    }

    if ($payload.capability -eq "ops.incident-packet") {
      $summary = $payload.input.previous
      $proto = @"
syntax = "proto3";
package omniforge.ops;

message IncidentPacket {
  uint32 total_incidents = 1;
  uint32 critical_incidents = 2;
  uint32 restart_actions = 3;
  uint32 isolate_actions = 4;
}
"@
      $result = Invoke-Protoc -JobId $jobId -ProtoText $proto -FileName "incident_packet.proto"
      if ($null -eq $result) {
        continue
      }
      $summaryJson = $summary | ConvertTo-Json -Compress
      $summaryEscaped = $summaryJson.Replace('\', '\\').Replace('"', '\"')
      $outputJson = ($result + @{
        packetSchema = "IncidentPacket"
        packetPreview = $summary
      }) | ConvertTo-Json -Depth 8 -Compress
      Send-Json ('{"type":"JOB_RESULT","jobId":"' + $jobId + '","output":' + $outputJson + '}')
      continue
    }

    Send-Json '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
    continue
  }

  if ($line.Contains('"type":"SHUTDOWN"')) {
    exit 0
  }
}
