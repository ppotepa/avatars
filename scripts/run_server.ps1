$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

$Dart = "dart"
$FlutterDart = "C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe"
if (Test-Path $FlutterDart) {
  $Dart = $FlutterDart
}

Write-Host "Using Dart: $Dart"
Write-Host "Starting Avatar Genome Editor on http://127.0.0.1:8080"
Write-Host "Dart run will incrementally rebuild changed sources. Use scripts/rebuild.ps1 for a clean rebuild."

$env:DART_SUPPRESS_ANALYTICS = "true"
$env:CI = "true"

& $Dart pub get
& $Dart run bin/avatar_editor_server.dart --host 127.0.0.1 --port 8080 --root $ProjectRoot
