$inputPath = Join-Path $PSScriptRoot "input.jsonl"

try {
  while (($line = [Console]::In.ReadLine()) -ne $null) {
    [System.IO.File]::WriteAllText($inputPath, $line + [Environment]::NewLine)
    & (Join-Path $PSScriptRoot "worker.exe") $inputPath
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  }
}
finally {
  Remove-Item -LiteralPath $inputPath -ErrorAction SilentlyContinue
}
