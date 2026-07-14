$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$version = "dev-$timestamp"
$releaseRoot = Join-Path $root "dist"
$stagingDir = Join-Path $releaseRoot "omniforge-cli-$version"
$zipPath = Join-Path $releaseRoot "omniforge-cli-$version.zip"
$latestZipPath = Join-Path $releaseRoot "omniforge-cli-latest.zip"

New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null
if (Test-Path $stagingDir) {
  Remove-Item -Recurse -Force $stagingDir
}
New-Item -ItemType Directory -Force -Path $stagingDir | Out-Null

$directoriesToCopy = @(
  "apps",
  "workers",
  "languages",
  "pipelines",
  "protocol",
  "toolchains",
  "examples",
  "docs",
  "tests",
  ".github"
)

$filesToCopy = @(
  "omniforge.py",
  "README.md",
  "docker-compose.yml",
  "Makefile"
)

foreach ($relative in $directoriesToCopy) {
  $source = Join-Path $root $relative
  if (Test-Path $source) {
    Copy-Item -Recurse -Force $source (Join-Path $stagingDir $relative)
  }
}

foreach ($relative in $filesToCopy) {
  $source = Join-Path $root $relative
  if (Test-Path $source) {
    Copy-Item -Force $source (Join-Path $stagingDir $relative)
  }
}

$releaseNotes = @(
  "# Omniforge CLI Release",
  "",
  "This package is centered on the single public entry point:",
  "",
  "python omniforge.py help-topics",
  "",
  "## Included",
  "",
  "- root launcher: omniforge.py",
  "- CLI implementation: apps/cli/omniforge.py",
  "- coordinator implementation: apps/coordinator/",
  "- worker manifests and implementations",
  "- language catalog",
  "- pipelines, protocol docs, and toolchain manifests",
  "",
  "## Requirements",
  "",
  "- Python 3.12+",
  "- Go 1.25+",
  "- host toolchains as needed for specific workers",
  "",
  "## First Commands",
  "",
  "python omniforge.py overview",
  "python omniforge.py workers summary",
  "python omniforge.py toolchains doctor"
) -join "`r`n"

$releaseNotes | Set-Content -Path (Join-Path $stagingDir "RELEASE.txt") -Encoding UTF8

$normalizedTime = Get-Date
Get-ChildItem -Recurse -Force $stagingDir | ForEach-Object {
  $_.LastWriteTime = $normalizedTime
}

if (Test-Path $zipPath) {
  Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $zipPath -Force
Copy-Item -Force $zipPath $latestZipPath

[pscustomobject]@{
  version = $version
  stagingDir = $stagingDir
  zipPath = $zipPath
  latestZipPath = $latestZipPath
} | ConvertTo-Json -Depth 3
