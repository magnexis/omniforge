$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..\..")

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
  Write-Error "docker is required to run the container-backed OCaml worker"
  exit 1
}

docker info | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "docker daemon is not running"
  exit 1
}

$image = "omniforge-functional:dev"
docker image inspect $image | Out-Null 2>$null
if ($LASTEXITCODE -ne 0) {
  docker compose --profile functional build omniforge-functional | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Error "failed to build omniforge-functional image"
    exit 1
  }
}

& docker compose --profile functional run --rm -T omniforge-functional ocaml workers/ocaml/worker.ml
exit $LASTEXITCODE
