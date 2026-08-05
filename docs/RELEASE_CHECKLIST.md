# Release checklist

This checklist is the manual release gate for `2.0.0-rc.1`.

## Contract

- [ ] `pubspec.yaml`, `CHANGELOG.md`, `PROJECT_MANIFEST.md` and `AvatarGenomeVersion` agree.
- [ ] Catalog reports exactly 30 categories and 275 fields.
- [ ] Stable contract vectors pass without updates.
- [ ] Request/result schemas remain 1/2.
- [ ] Core entry point has no `dart:io`, Flutter, DOM or `dart:ui` dependency.

## Correctness

- [ ] Same request produces the same genome and image hash in repeated runs.
- [ ] Phases 16 and above match the corresponding animation frame.
- [ ] Unknown overrides, locks, categories and nonces fail immediately.
- [ ] Result images, masks, palettes and metadata cannot be mutated through public references.
- [ ] Custom renderer parts are honored and pipeline/dependency conflicts are rejected.

## Performance

- [ ] Static unique-seed, same-seed, animation and batch benchmarks are recorded.
- [ ] Reduced-motion phase zero uses the single-sample camera plan.
- [ ] Genome, layout and result caches remain bounded.
- [ ] Batch requests exceeding avatar, memory or worker budgets are rejected.

## Server

- [ ] Loopback is the default bind address.
- [ ] Remote bind requires `--allow-remote`.
- [ ] Cross-origin POST requests are rejected unless explicitly allowed.
- [ ] `/api/save` is disabled by default and requires the configured token.
- [ ] Internal server errors do not expose stack traces to clients.

## Local verification

```bash
dart format --output=none --set-exit-if-changed lib test bin tool benchmark
dart analyze --fatal-infos
dart test --reporter expanded
dart run tool/release_audit.dart
dart run benchmark/avatar_benchmark.dart
```

CI is not required for this release process; these commands are intended for the maintainer's local machine.
