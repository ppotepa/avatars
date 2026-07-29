#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export DART_SUPPRESS_ANALYTICS=true
export CI=true

dart pub get
dart run bin/avatar_editor_server.dart --host 127.0.0.1 --port 8080
