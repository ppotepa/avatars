@echo off
cd /d "%~dp0\.."
set "DART=dart"
if exist "C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe" set "DART=C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe"
echo Using Dart: %DART%
echo Starting Avatar Genome Editor on http://127.0.0.1:8080
set DART_SUPPRESS_ANALYTICS=true
set CI=true
"%DART%" pub get
"%DART%" run bin/avatar_editor_server.dart --host 127.0.0.1 --port 8080 --root "%CD%"
