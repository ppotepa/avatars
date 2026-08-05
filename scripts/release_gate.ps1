param(
  [switch]$ApproveGolden,
  [switch]$SkipBenchmark
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $ProjectRoot
try {
  $Dart = if ($env:DART_EXE) {
    $env:DART_EXE
  } elseif (Get-Command dart -ErrorAction SilentlyContinue) {
    (Get-Command dart).Source
  } elseif (Test-Path 'C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe') {
    'C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe'
  } else {
    throw 'Dart executable not found. Set DART_EXE or add Dart to PATH.'
  }

  function Invoke-DartStep {
    param(
      [Parameter(Mandatory = $true)][string]$Name,
      [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    & $Dart @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "$Name failed with exit code $LASTEXITCODE."
    }
  }

  Invoke-DartStep 'Dependencies' @('pub', 'get')
  Invoke-DartStep 'Format check' @(
    'format', '--output=none', '--set-exit-if-changed',
    'lib', 'test', 'bin', 'tool', 'example', 'benchmark'
  )
  Invoke-DartStep 'Static analysis' @('analyze', '--fatal-infos')
  Invoke-DartStep 'Tests' @('test', '--reporter', 'expanded')

  if ($ApproveGolden) {
    Invoke-DartStep 'Approve golden vectors' @(
      'run', 'tool/update_contract_vectors.dart', '--approve'
    )
  } else {
    Invoke-DartStep 'Refresh golden vectors' @(
      'run', 'tool/update_contract_vectors.dart'
    )
    throw 'Golden vectors were refreshed but not approved. Review them visually and rerun with -ApproveGolden.'
  }

  Invoke-DartStep 'Release audit' @('run', 'tool/release_audit.dart')
  if (-not $SkipBenchmark) {
    Invoke-DartStep 'Benchmark' @('run', 'benchmark/avatar_benchmark.dart')
  }

  Write-Host "`n=== Server smoke test ===" -ForegroundColor Cyan
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ProjectRoot\scripts\smoke_server.ps1"
  if ($LASTEXITCODE -ne 0) {
    throw "Server smoke test failed with exit code $LASTEXITCODE."
  }

  Write-Host "`nRELEASE GATE PASSED" -ForegroundColor Green
} finally {
  Pop-Location
}
