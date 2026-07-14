$ErrorActionPreference = "Stop"

$workerRoot = $PSScriptRoot
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $workerRoot "..\.."))
$cacheRoot = Join-Path $workerRoot ".cache\crystal-cache"
$tempRoot = Join-Path $workerRoot ".cache\temp"

New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

$safePath = (($env:PATH -split ';' | Where-Object {
    $_ -and ($_ -notmatch 'wingtk\.gvsbuild\.GTK4')
}) -join ';')

$env:PATH = "C:\Users\matth\AppData\Local\Programs\Crystal;$safePath"
$env:CRYSTAL_CACHE_DIR = $cacheRoot
$env:TEMP = $tempRoot
$env:TMP = $tempRoot

Push-Location $workerRoot

if (-not (Test-Path (Join-Path $workerRoot "worker.exe"))) {
    & "C:\Users\matth\AppData\Local\Programs\Crystal\crystal.exe" build "worker.cr" -o "worker.exe"
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        exit $LASTEXITCODE
    }
}

& (Join-Path $workerRoot "worker.exe")
$code = $LASTEXITCODE
Pop-Location
exit $code
