# Validation status

The project includes three validation layers.

## Repository-level static audit

Run:

```bash
python tool/static_audit.py
```

The audit checks:

- the embedded catalog matches `tool/catalog_v41.json`;
- all 26 categories and 223 parameter identifiers are referenced by the Dart implementation;
- the web client does not hardcode catalog property identifiers;
- all required API routes, web assets, scripts and binding modules exist;
- relative Dart imports resolve;
- Dart source delimiters are balanced;
- the editor does not use `<canvas>`.

## Browser contract audit

The assembled project was loaded in headless Chromium against an intercepted
mock of the documented API contract. The test verified:

- 223 dynamically generated catalog controls;
- fourteen request/settings/rendering controls;
- grouped category tabs;
- a rendered SVG preview;
- no JavaScript page errors;
- a slider change produces a generic `{op: "set", id, value}` binding action;
- text filtering reduces the visible field set.

`node --check web/app.js` also completed successfully.

## Dart SDK validation

Run in an environment with Dart 3.3 or newer:

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart run benchmark/avatar_benchmark.dart
```

Or run `tool/verify.sh` on macOS/Linux.

The supplied execution environment did not contain a Dart or Flutter SDK, so
compiler-level analysis and Dart tests were not executed while assembling this
archive. The repository-level static audit and browser contract audit were
executed successfully. The included tests cover determinism, catalog
completeness, animation, codecs, locks, presets, request validation, property
bindings and editor actions.
