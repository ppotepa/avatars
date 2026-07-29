$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Process = Start-Process powershell.exe `
  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\run_server.ps1`"" `
  -WorkingDirectory $ProjectRoot `
  -PassThru `
  -WindowStyle Hidden

try {
  Start-Sleep -Seconds 8
  Invoke-RestMethod "http://127.0.0.1:8080/api/health" | ConvertTo-Json
} finally {
  Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
  $Connection = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue |
    Where-Object { $_.State -eq "Listen" } |
    Select-Object -First 1
  if ($Connection -ne $null) {
    Stop-Process -Id $Connection.OwningProcess -Force -ErrorAction SilentlyContinue
  }
}
