while (($line = [Console]::In.ReadLine()) -ne $null) {
  $payload = $line + [Environment]::NewLine
  $payload | & "C:\Program Files (x86)\gforth\gforth.exe" (Join-Path $PSScriptRoot "worker.fs")
}
