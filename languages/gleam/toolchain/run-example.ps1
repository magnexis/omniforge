$ErrorActionPreference = "Stop"

$exampleDir = Join-Path $PSScriptRoot "..\examples\hello-world"
$exampleDir = [System.IO.Path]::GetFullPath($exampleDir)
$erlangBin = "C:\Program Files\Erlang OTP\bin"
$gleam = Join-Path $PSScriptRoot "..\..\..\.cache\runtime-shims\gleam.exe"
$gleam = [System.IO.Path]::GetFullPath($gleam)

if (-not (Test-Path (Join-Path $erlangBin "escript.exe"))) {
  Write-Error "Erlang escript.exe was not found at $erlangBin"
  exit 1
}

if (-not (Test-Path $gleam)) {
  Write-Error "Gleam executable was not found at $gleam"
  exit 1
}

$env:PATH = "$erlangBin;$env:PATH"
Set-Location $exampleDir
& $gleam run
exit $LASTEXITCODE
