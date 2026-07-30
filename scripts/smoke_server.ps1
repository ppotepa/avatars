$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SmokeId = "smoke-$([guid]::NewGuid().ToString('N'))"
$SmokeDirectory = Join-Path $ProjectRoot "output\avatars\$SmokeId"
$SmokeLog = Join-Path $env:TEMP "$SmokeId.log"
$SmokeErrorLog = Join-Path $env:TEMP "$SmokeId.error.log"
$Process = Start-Process powershell.exe `
  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\run_server.ps1`"" `
  -WorkingDirectory $ProjectRoot `
  -PassThru `
  -WindowStyle Hidden `
  -RedirectStandardOutput $SmokeLog `
  -RedirectStandardError $SmokeErrorLog

try {
  $started = $false
  $startDeadline = (Get-Date).AddSeconds(30)
  while ((Get-Date) -lt $startDeadline -and -not $started) {
    if ($Process.HasExited) {
      throw "Avatar server process exited before startup completed."
    }
    if (Test-Path $SmokeLog) {
      $started = (Get-Content $SmokeLog -Raw) -match "Open http://127\.0\.0\.1:8080"
    }
    if (-not $started) {
      Start-Sleep -Milliseconds 500
    }
  }
  if (-not $started) {
    throw "Avatar server did not report startup within 30 seconds."
  }

  $health = $null
  $deadline = (Get-Date).AddSeconds(30)
  while ((Get-Date) -lt $deadline -and $null -eq $health) {
    try {
      $health = Invoke-RestMethod "http://127.0.0.1:8080/api/health" -TimeoutSec 2
    } catch {
      Start-Sleep -Milliseconds 500
    }
  }
  if ($null -eq $health) {
    throw "Avatar server did not become healthy within 30 seconds."
  }
  $health | ConvertTo-Json

  $savePayload = @{
    id = $SmokeId
    scale = 8
    animationId = "laughing"
    request = @{
      schemaVersion = 1
      seed = "smoke-feed"
      overrides = @{
        "v4.animation" = "idle"
        "mouth.shape" = "full"
        "mouth.width" = 8
      }
    }
  } | ConvertTo-Json -Depth 6
  $saved = Invoke-RestMethod "http://127.0.0.1:8080/api/save" `
    -Method Post `
    -ContentType "application/json" `
    -Body $savePayload
  if (
    $saved.files -notcontains "avatar.gif" -or
    $saved.files -notcontains "animation.json" -or
    $saved.files -notcontains "animation_bundle.json"
  ) {
    throw "Saved avatar package is missing animation files."
  }
  $manifestPath = Join-Path $SmokeDirectory "animation.json"
  $bundlePath = Join-Path $SmokeDirectory "animation_bundle.json"
  if (-not (Test-Path $manifestPath)) {
    throw "Animation manifest was not written."
  }
  if (-not (Test-Path $bundlePath)) {
    throw "Animation bundle was not written."
  }
  $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
  if (-not $manifest.feedSafe -or $manifest.fps -ne 8 -or $manifest.animation -ne "laughing") {
    throw "Animation manifest does not meet the feed contract."
  }
  $bundle = Get-Content $bundlePath -Raw | ConvertFrom-Json
  if ($bundle.defaultAnimationId -ne "idle" -or $bundle.clips.Count -lt 5) {
    throw "Animation bundle is incomplete."
  }
  $savedRequestPath = Join-Path $SmokeDirectory "request.json"
  $savedRequest = Get-Content $savedRequestPath -Raw | ConvertFrom-Json
  if ($savedRequest.overrides."v4.animation" -ne "laughing") {
    throw "Saved request did not persist the selected animation."
  }
} catch {
  if (Test-Path $SmokeLog) { Get-Content $SmokeLog }
  if (Test-Path $SmokeErrorLog) { Get-Content $SmokeErrorLog }
  throw
} finally {
  Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
  $Connection = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue |
    Where-Object { $_.State -eq "Listen" } |
    Select-Object -First 1
  if ($Connection -ne $null) {
    Stop-Process -Id $Connection.OwningProcess -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path $SmokeDirectory) {
    Remove-Item -LiteralPath $SmokeDirectory -Recurse -Force
  }
  Remove-Item -LiteralPath $SmokeLog -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $SmokeErrorLog -Force -ErrorAction SilentlyContinue
}
