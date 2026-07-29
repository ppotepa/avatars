$ErrorActionPreference = "Stop"

Set-Location (Split-Path -Parent $PSScriptRoot)

1..100 | ForEach-Object {
  $n = "{0:D3}" -f $_
  dart run tool/generate.dart --seed "avatar-$n" --out "output/avatar_$n" --scale 8
}
