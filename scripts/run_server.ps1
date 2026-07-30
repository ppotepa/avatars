$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

$Dart = "dart"
$FlutterDart = "C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe"
if (Test-Path $FlutterDart) {
  $Dart = $FlutterDart
}

Write-Host "Using Dart: $Dart"
$HostAddress = "127.0.0.1"
$Port = 8080
$ServerScript = (Join-Path $ProjectRoot "bin\avatar_editor_server.dart")
$CurrentPid = $PID

function Stop-AvatarServerProcesses {
  $serverProcesses = Get-CimInstance Win32_Process |
    Where-Object {
      $_.ProcessId -ne $CurrentPid -and
      $_.CommandLine -and
      $_.CommandLine.Contains("avatar_editor_server.dart")
    }

  foreach ($process in $serverProcesses) {
    Write-Host "Stopping old avatar server PID $($process.ProcessId)"
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
  }

  $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object {
      $_.LocalPort -eq $Port -and $_.OwningProcess -ne $CurrentPid
    } |
    Select-Object -ExpandProperty OwningProcess -Unique

  foreach ($listenerPid in $listeners) {
    Write-Host "Freeing port $Port from PID $listenerPid"
    Stop-Process -Id $listenerPid -Force -ErrorAction SilentlyContinue
  }
}

Write-Host "Preparing Avatar Genome Editor on http://$HostAddress`:$Port"

$env:DART_SUPPRESS_ANALYTICS = "true"
$env:CI = "true"

Stop-AvatarServerProcesses
& $Dart pub get
Write-Host "Starting Avatar Genome Editor on http://$HostAddress`:$Port"
& $Dart run $ServerScript --host $HostAddress --port $Port --root $ProjectRoot
