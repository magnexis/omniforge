$ErrorActionPreference = "Stop"

$exampleDir = Join-Path $PSScriptRoot "..\examples\hello-world"
$exampleDir = [System.IO.Path]::GetFullPath($exampleDir)
$workspaceGleam = Join-Path $PSScriptRoot "..\..\..\.cache\runtime-shims\gleam.exe"
$workspaceGleam = [System.IO.Path]::GetFullPath($workspaceGleam)

$gleamCommand = Get-Command gleam -ErrorAction SilentlyContinue
if ($gleamCommand) {
  $gleam = $gleamCommand.Source
} elseif (Test-Path $workspaceGleam) {
  $gleam = $workspaceGleam
} else {
  Write-Error "Gleam executable was not found in PATH or at $workspaceGleam"
  exit 1
}

$escriptCommand = Get-Command escript -ErrorAction SilentlyContinue
if (-not $escriptCommand) {
  $erlangBin = "C:\Program Files\Erlang OTP\bin"
  if (Test-Path (Join-Path $erlangBin "escript.exe")) {
    $env:PATH = "$erlangBin;$env:PATH"
    $escriptCommand = Get-Command escript -ErrorAction SilentlyContinue
  }
}

if (-not $escriptCommand) {
  Write-Error "Erlang escript was not found in PATH"
  exit 1
}

Set-Location $exampleDir
& $gleam run
exit $LASTEXITCODE
