#!/usr/bin/env sh
set -eu

python tool/static_audit.py
if command -v node >/dev/null 2>&1; then
  node --check web/app.js
fi
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart run benchmark/avatar_benchmark.dart
