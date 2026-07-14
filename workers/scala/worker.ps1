$ErrorActionPreference = "Stop"

$scalaCli = "C:\Program Files\scala-cli-x86_64-pc-win32\scala-cli.exe"
if (-not (Test-Path $scalaCli)) {
  $scalaCli = "scala-cli"
}

$cacheRoot = Join-Path $PSScriptRoot ".cache"
$coursierCache = Join-Path $cacheRoot "coursier"
New-Item -ItemType Directory -Force -Path $coursierCache | Out-Null

$env:COURSIER_CACHE = $coursierCache

Push-Location $PSScriptRoot
& $scalaCli run "Worker.scala" --server=false --power
$code = $LASTEXITCODE
Pop-Location
exit $code
